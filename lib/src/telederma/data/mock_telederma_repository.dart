import 'dart:ui';

import '../../api_client/api_chat_client.dart';
import '../legit/legit_iframe.dart';
import '../models.dart';
import 'telederma_repository.dart';

class MockTeledermaRepository implements TeledermaRepository {
  MockTeledermaRepository({this.latency = const Duration(milliseconds: 600), this.withAnalysis = false})
      : _cases = _seed(withAnalysis);

  final Duration latency;

  final bool withAnalysis;
  final List<TeledermaCase> _cases;

  @override
  Future<Color?> primaryColor() async => null;

  @override
  Future<List<TeledermaCase>> listCases() async {
    await Future.delayed(latency);
    return [
      for (final c in _cases)
        TeledermaCase(
          id: c.id,
          status: c.status,
          consultationReason: c.consultationReason,
          createdAt: c.createdAt,
          reports: [for (final r in c.reports) CaseReport(id: r.id, bodySite: r.bodySite)],
        ),
    ];
  }

  @override
  Future<TeledermaCase> getCase(String caseId) async {
    await Future.delayed(latency);
    return _find(caseId);
  }

  @override
  Future<TeledermaCase> createCase({String? consultationReason}) async {
    await Future.delayed(latency);
    final reason = consultationReason?.trim();
    final created = TeledermaCase(
      id: 'case-${DateTime.now().microsecondsSinceEpoch}',
      status: CaseStatus.draft,
      consultationReason: reason == null || reason.isEmpty ? null : reason,
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
    final report = CaseReport(
      id: reportId,
      bodySite: _bodySites[parts.length > 3 ? parts[3] : null] ?? 'Other',
      analysis: withAnalysis ? _analyses[parts.length > 2 ? parts[2] : null] ?? _analyses['rash'] : null,
    );
    _replace(_copy(c, reports: [...c.reports, report]));
    return report;
  }

  @override
  Future<TeledermaCase> submitCase(String caseId) async {
    await Future.delayed(latency);
    final c = _draft(caseId);
    if (c.reports.isEmpty) throw const ApiChatException(422, 'The case has no reports.');
    final submitted = _copy(c, status: CaseStatus.submitted);
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

  static TeledermaCase _copy(TeledermaCase c, {CaseStatus? status, List<CaseReport>? reports}) => TeledermaCase(
        id: c.id,
        status: status ?? c.status,
        consultationReason: c.consultationReason,
        createdAt: c.createdAt,
        reports: reports ?? c.reports,
      );

  static List<TeledermaCase> _seed(bool withAnalysis) {
    final now = DateTime.now();
    return [
      TeledermaCase(
        id: 'case-nevus',
        status: CaseStatus.submitted,
        consultationReason: 'Lunar que ha cambiado de color',
        createdAt: now.subtract(const Duration(days: 3)),
        reports: [
          CaseReport(
            id: 'mock_lesion_pigmented_back_changed_0',
            bodySite: 'Espalda',
            analysis: withAnalysis ? _analyses['pigmented'] : null,
          ),
        ],
      ),
      TeledermaCase(
        id: 'case-old',
        status: CaseStatus.submitted,
        createdAt: now.subtract(const Duration(days: 40)),
        reports: [
          CaseReport(
            id: 'mock_lesion_pimples_face_stable_0',
            bodySite: 'Cabeza y cuello',
            analysis: withAnalysis ? _analyses['pimples'] : null,
          ),
        ],
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

  static const _analyses = {
    'pigmented': Analysis(
      hypotheses: [
        Hypothesis(name: 'Melanocytic nevus', icd11: '2F20', probability: 58),
        Hypothesis(name: 'Melanoma', icd11: '2C30', probability: 31),
        Hypothesis(name: 'Seborrheic keratosis', icd11: '2F21.0', probability: 11),
      ],
      risk: Risk(hasCondition: 92, malignancy: 34, pigmentedLesion: 95, urgentReferral: 12, highPriorityReferral: 41),
    ),
    'rash': Analysis(
      hypotheses: [
        Hypothesis(name: 'Atopic dermatitis', icd11: 'EA80', probability: 64),
        Hypothesis(name: 'Contact dermatitis', icd11: 'EK00', probability: 24),
        Hypothesis(name: 'Psoriasis', icd11: 'EA90', probability: 12),
      ],
      risk: Risk(hasCondition: 88, malignancy: 2, pigmentedLesion: 4, urgentReferral: 3, highPriorityReferral: 9),
      severity: [Severity(name: 'ASCORAD', score: 34, severity: 'Moderate')],
    ),
    'pimples': Analysis(
      hypotheses: [
        Hypothesis(name: 'Acne', icd11: 'ED80', probability: 72.5),
        Hypothesis(name: 'Rosacea', icd11: 'ED90', probability: 27.5),
      ],
      risk: Risk(hasCondition: 88, malignancy: 1, pigmentedLesion: 3, urgentReferral: 2, highPriorityReferral: 5),
      severity: [Severity(name: 'ALEGI', score: 12, severity: 'Mild')],
    ),
  };
}
