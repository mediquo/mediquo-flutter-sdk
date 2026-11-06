import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediquo_flutter_sdk/mediquo_flutter_sdk.dart';
import 'package:mediquo_flutter_sdk/src/design_system/components/mq_icon.dart' show parseSvgPath;

class _SessionFailingRepository extends MockTeledermaRepository {
  _SessionFailingRepository() : super(latency: Duration.zero, scenario: MockScenario.empty);

  int sessions = 0;

  @override
  Future<Uri> createIframeSession(String caseId) async {
    sessions++;
    throw const ApiChatException(502, 'Legit Health down');
  }
}

class _PendingMediaRepository extends MockTeledermaRepository {
  _PendingMediaRepository() : super(latency: Duration.zero);

  int lists = 0;

  @override
  Future<List<TeledermaCase>> listCases() async {
    lists++;
    final stored = lists > 1;
    return [
      TeledermaCase(
        id: 'c1',
        status: CaseStatus.submitted,
        thumbnailUrl: stored ? 'https://s3/thumb.jpg' : null,
        reports: [CaseReport(id: 'r1', bodySite: 'Espalda', mediaPending: !stored)],
      ),
    ];
  }
}

const _caseDetail = {
  'data': {
    'id': 'case-1',
    'status': 'finished',
    'created_at': '2026-11-04T10:02:00+00:00',
    'submitted_at': '2026-11-04T10:15:00+00:00',
    'reports': [
      {
        'id': 'report-1',
        'body_site': {'code': 'headFront', 'name': 'Face and neck'},
        'media_status': 'stored',
        'answers': [
          {'question': 'Desde cuándo', 'answer': 'Hace 3 semanas'},
        ],
        'photos': [
          {'type': 'observation', 'url': 'https://s3/photo.jpg'},
          {'type': 'macroscopic', 'url': null},
        ],
      },
    ],
    'outcome': {
      'dermatologist': {'name': 'Dra. Marta Ruiz', 'license_number': '08/12345'},
      'report_url': 'https://s3/report.pdf',
      'prescription_url': null,
    },
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
              return http.Response(jsonEncode(respond(request)), 200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }),
          ),
        );

    test('parses the finished case detail', () async {
      final c = await clientFor((_) => _caseDetail).getCase('case-1');
      expect(c.status, CaseStatus.finished);
      expect(c.title, 'Face and neck');
      expect(c.submittedAt, DateTime.utc(2026, 11, 4, 10, 15).toLocal());
      expect(c.reports.single.answers.single.answer, 'Hace 3 semanas');
      expect(c.reports.single.photos.map((p) => p.url), ['https://s3/photo.jpg', null]);
      expect(c.outcome!.dermatologist, 'Dra. Marta Ruiz');
      expect(c.outcome!.licenseNumber, '08/12345');
      expect(c.outcome!.prescriptionUrl, isNull);
    });

    test('reads the legal consent like sdk-web and accepts it', () async {
      final requests = <http.Request>[];
      final client = ApiChatTeledermaClient(
        ApiChatClient(
          apiKey: 'k',
          token: 't',
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/login/v1/token') {
              return http.Response(
                jsonEncode({
                  'access_token': 's',
                  'patient': {
                    'legal_consent': {
                      'accepted_at': '2025-01-01 10:00:00',
                      'last_version_at': '2026-01-01 10:00:00',
                      'terms_url': 'https://patient/terms',
                      'privacy_url': 'https://patient/privacy',
                      'has_commercial_communications': true,
                    },
                  },
                }),
                200,
              );
            }
            if (request.url.path == '/organizations/v1/setup') {
              return http.Response(
                jsonEncode({
                  'data': {
                    'legal_consent': {'terms_url': 'https://org/terms', 'privacy_url': null},
                  },
                }),
                200,
              );
            }
            return http.Response('', 204);
          }),
        ),
      );

      final consent = await client.legalConsent();
      expect(consent.status, LegalConsentStatus.outdated);
      expect(consent.termsUrl, 'https://org/terms');
      expect(consent.privacyUrl, 'https://patient/privacy');

      await client.acceptLegalConsent(consent);
      expect(requests.last.url.path, '/profile/v1/legal-consent');
      expect(jsonDecode(requests.last.body), {
        'terms_accepted': true,
        'privacy_accepted': true,
        'commercial_accepted': true,
      });
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

    test('a consent never accepted is not accepted', () {
      const consent = LegalConsent(termsUrl: 't', privacyUrl: 'p');
      expect(consent.status, LegalConsentStatus.notAccepted);
      expect(
        LegalConsent(acceptedAt: DateTime(2026, 2), lastVersionAt: DateTime(2026), termsUrl: 't', privacyUrl: 'p')
            .status,
        LegalConsentStatus.accepted,
      );
    });
  });

  test('parses the MediCore icon paths', () {
    expect(parseSvgPath(MqIcons.chevronRight.path).getBounds(), const Rect.fromLTRB(7.5, 5, 12.5, 15));
    expect(parseSvgPath('M0 0H4V3Z').getBounds(), const Rect.fromLTRB(0, 0, 4, 3));
    for (final icon in [MqIcons.heartRate, MqIcons.camera, MqIcons.file, MqIcons.receipt, MqIcons.lock]) {
      final bounds = parseSvgPath(icon.path).getBounds();
      expect(bounds.isEmpty, isFalse);
      expect(Rect.fromLTWH(0, 0, icon.viewBox, icon.viewBox).inflate(0.01).contains(bounds.bottomRight), isTrue);
    }
    expect(() => parseSvgPath('M0 0A1 1 0 0 1 2 2'), throwsFormatException);
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
      final repo = MockTeledermaRepository(latency: Duration.zero);
      final c = await repo.createCase();
      expect(c.status, CaseStatus.draft);
      await expectLater(repo.submitCase(c.id), throwsA(isA<ApiChatException>()));

      await repo.attachReport(c.id, 'mock_lesion_pigmented_back_changed_1');
      final zone = await repo.attachReport(c.id, 'mock_lesion_pigmented_back_changed_1');
      expect(zone.bodySite, 'Espalda');

      final submitted = await repo.submitCase(c.id);
      expect(submitted.status, CaseStatus.submitted);
      expect(submitted.reports, hasLength(1));
      await expectLater(repo.createIframeSession(c.id), throwsA(isA<ApiChatException>()));
      await expectLater(repo.discardCase(c.id), throwsA(isA<ApiChatException>()));
    });
  });

  Widget app(TeledermaRepository repository, {void Function(String)? onLoadUrl, Future<void> Function()? onCamera}) =>
      MaterialApp(
        home: MediquoTeledermaCases(
          repository: repository,
          onLoadUrl: onLoadUrl ?? (_) {},
          onCameraPermission: onCamera,
        ),
      );

  testWidgets('asks for the camera before opening the iframe on Android', (tester) async {
    var asked = 0;
    await tester.pumpWidget(app(
      MockTeledermaRepository(latency: Duration.zero, scenario: MockScenario.sendError),
      onCamera: () async => asked++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva consulta'));
    await tester.pumpAndSettle();
    expect(find.byType(LegitIframeScreen), findsOneWidget);
    expect(asked, 1);
  });

  testWidgets('lists the consultations and opens the documents of a finished one', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.resetPhysicalSize);
    final opened = <String>[];
    await tester.pumpWidget(app(MockTeledermaRepository(latency: Duration.zero), onLoadUrl: opened.add));
    await tester.pumpAndSettle();

    expect(find.text('Tus consultas'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Finalizada'), findsNWidgets(2));
    await tester.tap(find.text('Tronco (pecho y abdomen)'));
    await tester.pumpAndSettle();

    expect(find.text('Tu informe está listo'), findsOneWidget);
    expect(find.text('Hace 3 semanas'), findsOneWidget);
    await tester.tap(find.text('Informe del dermatólogo'));
    expect(opened, hasLength(1));
  });

  testWidgets('the first consultation asks for the terms, then retries a failed iframe session', (tester) async {
    final repo = _SessionFailingRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva consulta'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de continuar'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de continuar'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(LegitIframeScreen), findsOneWidget);
    expect(repo.sessions, 1);
    expect(find.text('No hemos podido enviar tu consulta'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repo.sessions, 2);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    final cases = await tester.runAsync(repo.listCases);
    expect(cases!.where((c) => c.status == CaseStatus.draft), isEmpty);

    await tester.tap(find.text('Nueva consulta'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de continuar'), findsNothing);
    expect(repo.sessions, 3);
  });

  testWidgets('reloads the list until the photos of a new consultation are stored', (tester) async {
    final repo = _PendingMediaRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(repo.lists, 1);
    expect(find.text('Espalda'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(repo.lists, 2);
    expect(find.text('Espalda'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(repo.lists, 2);
  });

  testWidgets('the info button opens the service information', (tester) async {
    await tester.pumpWidget(app(MockTeledermaRepository(latency: Duration.zero)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Más información'));
    await tester.pumpAndSettle();
    expect(find.text('Qué incluye'), findsOneWidget);
  });

  testWidgets('an outdated consent asks again with the update title', (tester) async {
    await tester.pumpWidget(app(MockTeledermaRepository(latency: Duration.zero, scenario: MockScenario.termsOutdated)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva consulta'));
    await tester.pumpAndSettle();
    expect(find.text('Hemos actualizado los términos y condiciones'), findsOneWidget);
  });

  testWidgets('a failed load shows the error banner', (tester) async {
    await tester.pumpWidget(app(MockTeledermaRepository(latency: Duration.zero, scenario: MockScenario.loadError)));
    await tester.pumpAndSettle();

    expect(find.text('No hemos podido cargar tus consultas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('patients without access see no telederma flow', (tester) async {
    await tester.pumpWidget(app(MockTeledermaRepository(latency: Duration.zero, scenario: MockScenario.forbidden)));
    await tester.pumpAndSettle();

    expect(find.text('Servicio no disponible'), findsOneWidget);
    expect(find.text('Nueva consulta'), findsNothing);
  });
}
