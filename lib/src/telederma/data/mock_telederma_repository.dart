import 'dart:ui';

import '../../api_client/api_chat_client.dart';
import '../legit/legit_iframe.dart';
import '../models.dart';
import 'telederma_repository.dart';

enum MockScenario { consultations, empty, termsOutdated, loadError, forbidden, sendError }

class MockTeledermaRepository implements TeledermaRepository {
  MockTeledermaRepository(
      {this.latency = const Duration(milliseconds: 600), this.scenario = MockScenario.consultations})
      : _cases = scenario == MockScenario.empty ? [] : _seed(),
        _acceptedAt = switch (scenario) {
          MockScenario.empty => null,
          MockScenario.termsOutdated => DateTime(2025),
          _ => DateTime(2026, 2),
        };

  final Duration latency;
  final MockScenario scenario;
  final List<TeledermaCase> _cases;
  DateTime? _acceptedAt;

  @override
  Future<Color?> primaryColor() async => null;

  @override
  Future<LegalConsent> legalConsent() async {
    await Future.delayed(latency);
    return LegalConsent(
      acceptedAt: _acceptedAt,
      lastVersionAt: DateTime(2026),
      termsUrl: 'https://example.com/terminos',
      privacyUrl: 'https://example.com/privacidad',
    );
  }

  @override
  Future<void> acceptLegalConsent(LegalConsent consent) async {
    await Future.delayed(latency);
    _acceptedAt = DateTime.now();
  }

  @override
  Future<List<TeledermaCase>> listCases() async {
    await Future.delayed(latency);
    if (scenario == MockScenario.loadError) throw const ApiChatException(500, 'Server error.');
    if (scenario == MockScenario.forbidden) throw const ApiChatException(403, 'Not an IMQ patient.');
    return List.of(_cases);
  }

  @override
  Future<TeledermaCase> getCase(String caseId) async {
    await Future.delayed(latency);
    return _find(caseId);
  }

  @override
  Future<TeledermaCase> createCase() async {
    await Future.delayed(latency);
    final created = TeledermaCase(
      id: 'case-${DateTime.now().microsecondsSinceEpoch}',
      status: CaseStatus.draft,
      createdAt: DateTime.now(),
    );
    _cases.insert(0, created);
    return created;
  }

  @override
  Future<void> discardCase(String caseId) async {
    await Future.delayed(latency);
    _cases.remove(_draft(caseId));
  }

  @override
  Future<Uri> createIframeSession(String caseId) async {
    await Future.delayed(latency);
    if (scenario == MockScenario.sendError) throw const ApiChatException(502, 'Legit Health down.');
    _draft(caseId);
    return Uri.parse(LegitIframe.simulatorAsset);
  }

  @override
  Future<CaseReport> attachReport(String caseId, String reportId) async {
    await Future.delayed(latency * 2);
    final c = _draft(caseId);
    for (final r in c.reports) {
      if (r.id == reportId) return r;
    }
    final parts = reportId.split('_');
    final report = _report(reportId, _bodySites[parts.length > 3 ? parts[3] : null] ?? 'Otra zona');
    _replace(_copy(c, reports: [...c.reports, report]));
    return report;
  }

  @override
  Future<TeledermaCase> submitCase(String caseId) async {
    await Future.delayed(latency);
    final c = _draft(caseId);
    if (c.reports.isEmpty) throw const ApiChatException(422, 'The case has no reports.');
    final submitted = _copy(c, status: CaseStatus.submitted, submittedAt: DateTime.now());
    _replace(submitted);
    return submitted;
  }

  TeledermaCase _find(String caseId) =>
      _cases.firstWhere((c) => c.id == caseId, orElse: () => throw const ApiChatException(404, 'Case not found.'));

  TeledermaCase _draft(String caseId) {
    final c = _find(caseId);
    if (c.status != CaseStatus.draft) throw const ApiChatException(422, 'The case was already submitted.');
    return c;
  }

  void _replace(TeledermaCase c) => _cases[_cases.indexWhere((x) => x.id == c.id)] = c;

  static TeledermaCase _copy(TeledermaCase c, {CaseStatus? status, DateTime? submittedAt, List<CaseReport>? reports}) =>
      TeledermaCase(
        id: c.id,
        status: status ?? c.status,
        createdAt: c.createdAt,
        submittedAt: submittedAt ?? c.submittedAt,
        reports: reports ?? c.reports,
        outcome: c.outcome,
      );

  static CaseReport _report(String id, String bodySite) => CaseReport(
        id: id,
        bodySite: bodySite,
        answers: const [
          CaseAnswer('Desde cuándo', 'Hace 3 semanas'),
          CaseAnswer('Síntomas', 'Picor leve'),
          CaseAnswer('Medicación', 'Ninguna'),
          CaseAnswer('Alergias', 'Ninguna'),
        ],
        photos: const [CasePhoto(type: 'observation'), CasePhoto(type: 'macroscopic')],
      );

  static TeledermaCase _submitted(String id, DateTime at, String bodySite, {CaseOutcome? outcome}) => TeledermaCase(
        id: id,
        status: outcome == null ? CaseStatus.submitted : CaseStatus.finished,
        createdAt: at,
        submittedAt: at,
        reports: [_report('$id-report', bodySite)],
        outcome: outcome,
      );

  static const _outcome = CaseOutcome(
    dermatologist: 'Dra. Marta Ruiz',
    licenseNumber: '08/12345',
    reportUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    prescriptionUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  );

  static List<TeledermaCase> _seed() {
    final now = DateTime.now();
    return [
      _submitted('case-arm', now.subtract(const Duration(days: 1)), 'Brazo derecho (inc. axilas)'),
      _submitted('case-trunk', now.subtract(const Duration(days: 17)), 'Tronco (pecho y abdomen)', outcome: _outcome),
      _submitted(
        'case-face',
        now.subtract(const Duration(days: 22)),
        'Cabeza y cuello',
        outcome: const CaseOutcome(
            dermatologist: 'Dr. Jordi Puig',
            licenseNumber: '08/67890',
            reportUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
      ),
    ];
  }

  static const _bodySites = {
    'face': 'Cabeza y cuello',
    'neck': 'Cabeza y cuello',
    'chest': 'Tronco (pecho y abdomen)',
    'back': 'Espalda',
    'arm': 'Brazo derecho (inc. axilas)',
    'hand': 'Mano derecha',
    'leg': 'Pierna derecha',
    'foot': 'Pie derecho',
  };
}
