/// Telederma model, mirroring api-chat `/imq/telederma/v1/cases`.
///
/// Probabilities and scores stay on Legit.Health's 0-100 scale and its texts
/// (body site, hypotheses, severity) arrive in English.
library;

enum CaseStatus {
  draft('Borrador'),
  submitted('Pendiente de revisión');

  final String label;
  const CaseStatus(this.label);

  // shortcut: reviewed/closed arrive with MQB-18444 and show as submitted until they are added here.
  static CaseStatus fromJson(String value) => values.firstWhere((s) => s.name == value, orElse: () => submitted);
}

class CasePhoto {
  final String type;

  /// Signed URL that expires after 15 minutes: never cache it, fetch the case again.
  final String url;

  /// DIQA image quality, 0-100. Null for macroscopic photos.
  final int? qualityScore;

  const CasePhoto({required this.type, required this.url, this.qualityScore});

  static const int qualityThreshold = 50;

  factory CasePhoto.fromJson(Map<String, dynamic> json) => CasePhoto(
        type: json['type'] as String,
        url: json['url'] as String,
        qualityScore: (json['quality_score'] as num?)?.round(),
      );
}

class Hypothesis {
  final String name;
  final String icd11;
  final double probability;

  const Hypothesis({required this.name, required this.icd11, required this.probability});

  factory Hypothesis.fromJson(Map<String, dynamic> json) => Hypothesis(
        name: json['name'] as String,
        icd11: json['icd11'] as String? ?? '',
        probability: (json['probability'] as num).toDouble(),
      );
}

class Risk {
  final double hasCondition;
  final double malignancy;
  final double pigmentedLesion;
  final double urgentReferral;
  final double highPriorityReferral;

  const Risk({
    required this.hasCondition,
    required this.malignancy,
    required this.pigmentedLesion,
    required this.urgentReferral,
    required this.highPriorityReferral,
  });

  static const double malignancyAlertThreshold = 30;

  bool get isMalignancyAlert => malignancy >= malignancyAlertThreshold;

  factory Risk.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return Risk(
      hasCondition: read('has_condition'),
      malignancy: read('malignancy'),
      pigmentedLesion: read('pigmented_lesion'),
      urgentReferral: read('urgent_referral'),
      highPriorityReferral: read('high_priority_referral'),
    );
  }
}

class Severity {
  final String name;
  final double score;

  final String severity;

  const Severity({required this.name, required this.score, required this.severity});

  factory Severity.fromJson(Map<String, dynamic> json) => Severity(
        name: json['name'] as String,
        score: (json['score'] as num).toDouble(),
        severity: json['severity'] as String? ?? '',
      );
}

/// Legit.Health's AI result. Only sent when the patient may see it (`enableResult`).
class Analysis {
  final List<Hypothesis> hypotheses;
  final Risk? risk;
  final List<Severity> severity;

  const Analysis({required this.hypotheses, this.risk, this.severity = const []});

  factory Analysis.fromJson(Map<String, dynamic> json) => Analysis(
        hypotheses: [for (final h in json['hypotheses'] as List? ?? const []) Hypothesis.fromJson(h)],
        risk: json['risk'] == null ? null : Risk.fromJson(json['risk']),
        severity: [for (final s in json['severity'] as List? ?? const []) Severity.fromJson(s)],
      );
}

/// One body zone of a case: one pass through the Legit.Health iframe.
class CaseReport {
  final String id;

  final String bodySite;

  /// Empty in the list and while the photos are still being copied.
  final List<CasePhoto> photos;
  final Analysis? analysis;

  const CaseReport({required this.id, required this.bodySite, this.photos = const [], this.analysis});

  factory CaseReport.fromJson(Map<String, dynamic> json) => CaseReport(
        id: json['id'] as String,
        bodySite: (json['body_site'] as Map?)?['name'] as String? ?? '',
        photos: [for (final p in json['photos'] as List? ?? const []) CasePhoto.fromJson(p)],
        analysis: json['analysis'] == null ? null : Analysis.fromJson(json['analysis']),
      );
}

class TeledermaCase {
  final String id;
  final CaseStatus status;
  final String? consultationReason;

  /// Missing in the create and submit responses.
  final DateTime? createdAt;

  /// First lesion photo, only in the list. Signed for 15 minutes.
  final String? thumbnailUrl;
  final List<CaseReport> reports;

  const TeledermaCase({
    required this.id,
    required this.status,
    this.consultationReason,
    this.createdAt,
    this.thumbnailUrl,
    this.reports = const [],
  });

  /// The body zone: a case has one, and the consultation reason is free text too long for a title.
  String get title {
    final site = reports.firstOrNull?.bodySite ?? '';
    return site.isEmpty ? 'Consulta dermatológica' : site;
  }

  factory TeledermaCase.fromJson(Map<String, dynamic> json) => TeledermaCase(
        id: json['id'] as String,
        status: CaseStatus.fromJson(json['status'] as String),
        consultationReason: json['consultation_reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
        thumbnailUrl: json['thumbnail_url'] as String?,
        reports: [for (final r in json['reports'] as List? ?? const []) CaseReport.fromJson(r)],
      );
}
