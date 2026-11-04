import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';

class _ForbiddenRepository extends MockTeledermaRepository {
  _ForbiddenRepository() : super(latency: Duration.zero);

  @override
  Future<List<TeledermaCase>> listCases() async => throw const ApiChatException(403, 'Not an IMQ patient.');
}

class _SessionFailingRepository extends MockTeledermaRepository {
  _SessionFailingRepository() : super(latency: Duration.zero);

  int sessions = 0;

  @override
  Future<Uri> createIframeSession(String caseId) async {
    sessions++;
    throw const ApiChatException(502, 'Legit Health down');
  }
}

const _caseDetail = {
  'data': {
    'id': 'case-1',
    'status': 'submitted',
    'consultation_reason': 'Mancha en la cara',
    'created_at': '2026-11-04T10:02:00+00:00',
    'submitted_at': '2026-11-04T10:15:00+00:00',
    'reports': [
      {
        'id': 'report-1',
        'body_site': {'code': 'headFront', 'name': 'Face and neck'},
        'media_status': 'stored',
        'photos': [
          {'type': 'observation', 'url': 'https://s3/photo.jpg', 'quality_score': 86},
          {'type': 'macroscopic', 'url': 'https://s3/context.jpg', 'quality_score': null},
        ],
        'pdf_url': 'https://s3/report.pdf',
        'analysis': {
          'hypotheses': [
            {'name': 'Acne', 'code': 'acne', 'icd11': 'ED80', 'probability': 72.5},
          ],
          'risk': {
            'has_condition': 88.0,
            'malignancy': 12.0,
            'pigmented_lesion': 40.0,
            'urgent_referral': 5.0,
            'high_priority_referral': 9.0,
          },
          'severity': [
            {'name': 'ALEGI', 'code': 'alegi', 'score': 34.0, 'severity': 'Moderate'},
          ],
        },
      },
      {
        'id': 'report-2',
        'body_site': {'code': 'trunkBack', 'name': 'Back'},
        'media_status': 'pending',
        'photos': [],
        'pdf_url': null,
        'analysis': null,
      },
    ],
  },
};

void main() {
  group('LegitMessage.parse', () {
    test('decodes the JSON string posted on mobile', () {
      final m = LegitMessage.parse('{"message":"analysis_completed","id":"abc123"}');
      expect(m?.message, LegitMessage.analysisCompleted);
      expect(m?.id, 'abc123');
    });

    test('accepts the object posted through window.postMessage', () {
      final m = LegitMessage.parse({
        'message': 'image_rejected',
        'id': 'img',
        'payload': ['blurry'],
      });
      expect(m?.message, LegitMessage.imageRejected);
      expect(m?.payload, ['blurry']);
    });

    test('ignores anything that is not a Legit.Health callback', () {
      expect(LegitMessage.parse('not json'), isNull);
      expect(LegitMessage.parse('{"foo":1}'), isNull);
      expect(LegitMessage.parse(42), isNull);
    });
  });

  test('only Legit.Health pages and the bundled simulator are trusted', () {
    bool trusted(String url) => LegitIframe.isTrustedOrigin(Uri.parse(url));
    expect(trusted('https://iframe-pre.legit.health/?embeddedKey=x'), isTrue);
    expect(trusted('https://legit.health/'), isTrue);
    expect(trusted('file:///app/flutter_assets/packages/mediquo_flutter_sdk/assets/telederma/legit_iframe_mock.html'),
        isTrue);
    expect(trusted('https://evil-legit.health/'), isFalse);
    expect(trusted('https://legit.health.evil.com/'), isFalse);
    expect(LegitIframe.isTrustedOrigin(null), isFalse);
  });

  group('ApiChatClient', () {
    test('logs in once, sends the session and renews it on 401', () async {
      final requests = <http.Request>[];
      var logins = 0;
      final client = ApiChatClient(
        apiKey: 'org-key',
        token: 'host-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/login/v1/token') {
            logins++;
            return http.Response(jsonEncode({'access_token': 'session-$logins'}), 200);
          }
          final expired = request.headers['Authorization'] == 'Bearer session-1' && requests.length > 3;
          return expired ? http.Response('', 401) : http.Response(jsonEncode({'data': []}), 200);
        }),
      );

      await client.send('GET', '/a');
      await client.send('GET', '/b');
      expect(logins, 1);
      expect(jsonDecode(requests.first.body), {'token': 'host-token'});
      expect(requests[1].headers, containsPair('x-api-key', 'org-key'));
      expect(requests[1].headers, containsPair('Authorization', 'Bearer session-1'));

      await client.send('GET', '/c');
      expect(logins, 2);
      expect(requests.last.headers, containsPair('Authorization', 'Bearer session-2'));
    });

    test('turns error bodies into ApiChatException and retries a failed login', () async {
      var loginFails = true;
      final client = ApiChatClient(
        apiKey: 'k',
        token: 't',
        httpClient: MockClient((request) async {
          if (request.url.path == '/login/v1/token') {
            return loginFails
                ? http.Response('<html>Bad gateway</html>', 502, reasonPhrase: 'Bad Gateway')
                : http.Response(jsonEncode({'access_token': 's'}), 200);
          }
          return http.Response(jsonEncode({'message': 'The case was already submitted.'}), 422);
        }),
      );

      await expectLater(
        client.send('POST', '/x'),
        throwsA(isA<ApiChatException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
      loginFails = false;
      await expectLater(
        client.send('POST', '/x'),
        throwsA(isA<ApiChatException>().having((e) => e.message, 'message', 'The case was already submitted.')),
      );
    });
  });

  group('ApiChatTeledermaClient', () {
    ApiChatTeledermaClient clientFor(Object Function(http.Request) respond) => ApiChatTeledermaClient(
          ApiChatClient(
            apiKey: 'k',
            token: 't',
            httpClient: MockClient((request) async {
              if (request.url.path == '/login/v1/token') return http.Response(jsonEncode({'access_token': 's'}), 200);
              return http.Response(jsonEncode(respond(request)), 200);
            }),
          ),
        );

    test('parses the case detail with and without analysis', () async {
      final c = await clientFor((_) => _caseDetail).getCase('case-1');
      expect(c.status, CaseStatus.submitted);
      expect(c.title, 'Face and neck');
      expect(c.consultationReason, 'Mancha en la cara');
      expect(c.reports, hasLength(2));

      final face = c.reports.first;
      expect(face.bodySite, 'Face and neck');
      expect(face.photos.map((p) => p.qualityScore), [86, null]);
      expect(face.analysis!.hypotheses.single.probability, 72.5);
      expect(face.analysis!.risk!.malignancy, 12);
      expect(face.analysis!.severity.single.severity, 'Moderate');

      expect(c.reports.last.photos, isEmpty);
      expect(c.reports.last.analysis, isNull);
    });

    test('sends the report id and reads the iframe url', () async {
      final bodies = <String, Object?>{};
      final client = clientFor((request) {
        bodies[request.url.path] = request.body.isEmpty ? null : jsonDecode(request.body);
        if (request.url.path.endsWith('/iframe-sessions')) return {'url': 'https://iframe.legit.health/?embeddedKey=k'};
        return {
          'data': {
            'id': 'r1',
            'body_site': {'code': 'headFront', 'name': 'Face and neck'},
            'media_status': 'pending'
          },
        };
      });

      expect((await client.createIframeSession('c 1')).queryParameters, {'embeddedKey': 'k'});
      expect((await client.attachReport('c 1', 'r1')).bodySite, 'Face and neck');
      expect(bodies['/imq/telederma/v1/cases/c%201/reports'], {'report_id': 'r1'});
    });

    test('reads the list thumbnail and discards with DELETE', () async {
      final methods = <String>[];
      final client = clientFor((request) {
        methods.add('${request.method} ${request.url.path}');
        return {
          'data': [
            {'id': 'c1', 'status': 'draft', 'reports': [], 'thumbnail_url': null},
            {'id': 'c2', 'status': 'submitted', 'reports': [], 'thumbnail_url': 'https://s3/thumb.jpg'},
          ],
        };
      });

      final cases = await client.listCases();
      expect(cases.map((c) => c.thumbnailUrl), [null, 'https://s3/thumb.jpg']);
      await client.discardCase('c1');
      expect(methods.last, 'DELETE /imq/telederma/v1/cases/c1');
    });

    test('reads the organization primary colour', () async {
      Future<Color?> colorOf(Object? hex) => clientFor((_) => {
            'data': {'primary_color': hex, 'logo': null}
          }).primaryColor();
      expect(await colorOf('#046bb3'), const Color(0xFF046BB3));
      expect(await colorOf(null), isNull);
      expect(await colorOf('blue'), isNull);
    });

    test('unknown statuses fall back to submitted', () {
      expect(CaseStatus.fromJson('reviewed'), CaseStatus.submitted);
    });
  });

  test('the brand palette follows @mediquo/ui for the default purple', () {
    final t = MqTheme.fromBrand(MqColors.purple700);
    bool near(Color a, Color b) => (a.r - b.r).abs() < 0.03 && (a.g - b.g).abs() < 0.03 && (a.b - b.b).abs() < 0.03;
    expect(near(t.brandStrong, MqColors.purple800), isTrue);
    expect(near(t.brandSubtle, MqColors.purple50), isTrue);
    expect(t.textOnBrand, MqColors.grey50);
    expect(MqTheme.fromBrand(const Color(0xFFFFD60A)).textOnBrand, MqColors.grey950);
  });

  group('MockTeledermaRepository', () {
    test('adds zones idempotently and refuses empty or repeated submits', () async {
      final repo = MockTeledermaRepository(latency: Duration.zero, withAnalysis: true);
      final c = await repo.createCase(consultationReason: '  ');
      expect(c.status, CaseStatus.draft);
      expect(c.consultationReason, isNull);
      await expectLater(repo.submitCase(c.id), throwsA(isA<ApiChatException>()));

      await repo.attachReport(c.id, 'mock_lesion_pigmented_back_changed_1');
      final zone = await repo.attachReport(c.id, 'mock_lesion_pigmented_back_changed_1');
      expect(zone.bodySite, 'Espalda');
      expect(zone.analysis!.risk!.isMalignancyAlert, isTrue);

      final submitted = await repo.submitCase(c.id);
      expect(submitted.status, CaseStatus.submitted);
      expect(submitted.reports, hasLength(1));
      await expectLater(repo.createIframeSession(c.id), throwsA(isA<ApiChatException>()));
      await expectLater(repo.discardCase(c.id), throwsA(isA<ApiChatException>()));
    });
  });

  testWidgets('lists the cases and opens one', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(home: MediquoTeledermaCases(repository: MockTeledermaRepository(latency: Duration.zero))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendiente de revisión'), findsNWidgets(2));
    await tester.tap(find.text('Espalda'));
    await tester.pumpAndSettle();

    expect(find.text('Espalda'), findsOneWidget);
    expect(find.text('Lunar que ha cambiado de color'), findsOneWidget);
    expect(find.text('Un dermatólogo revisará tu caso y te responderá por el chat en menos de 48 h.'), findsOneWidget);
  });

  testWidgets('a new case opens the iframe and retries a failed session', (tester) async {
    final repo = _SessionFailingRepository();
    await tester.pumpWidget(MaterialApp(home: MediquoTeledermaCases(repository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo caso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'Mancha en la cara');
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.byType(LegitIframeScreen), findsOneWidget);
    expect(repo.sessions, 1);
    expect(find.text('No se ha podido iniciar el servicio de dermatología.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repo.sessions, 2);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Mancha en la cara'), findsNothing);
    final cases = await tester.runAsync(repo.listCases);
    expect(cases!.where((c) => c.status == CaseStatus.draft), isEmpty);
  });

  testWidgets('patients without access see no telederma flow', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MediquoTeledermaCases(repository: _ForbiddenRepository())));
    await tester.pumpAndSettle();

    expect(find.text('Servicio no disponible'), findsOneWidget);
    expect(find.text('Nuevo caso'), findsNothing);
  });
}
