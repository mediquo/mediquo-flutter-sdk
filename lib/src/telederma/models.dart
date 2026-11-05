library;

enum CaseStatus {
  draft('Borrador'),
  submitted('Pendiente'),
  finished('Finalizada');

  final String label;
  const CaseStatus(this.label);
  static CaseStatus fromJson(String value) => values.firstWhere((s) => s.name == value, orElse: () => submitted);
}

class CasePhoto {
  final String type;
  final String? url;

  const CasePhoto({required this.type, this.url});

  factory CasePhoto.fromJson(Map<String, dynamic> json) =>
      CasePhoto(type: json['type'] as String, url: json['url'] as String?);
}

class CaseAnswer {
  final String question;
  final String answer;

  const CaseAnswer(this.question, this.answer);

  factory CaseAnswer.fromJson(Map<String, dynamic> json) =>
      CaseAnswer(json['question'] as String, json['answer'] as String);
}

class CaseReport {
  final String id;
  final String bodySite;
  final List<CaseAnswer> answers;
  final List<CasePhoto> photos;
  final bool mediaPending;

  const CaseReport({
    required this.id,
    required this.bodySite,
    this.answers = const [],
    this.photos = const [],
    this.mediaPending = false,
  });

  factory CaseReport.fromJson(Map<String, dynamic> json) => CaseReport(
        id: json['id'] as String,
        bodySite: (json['body_site'] as Map?)?['name'] as String? ?? '',
        answers: [for (final a in json['answers'] as List? ?? const []) CaseAnswer.fromJson(a)],
        photos: [for (final p in json['photos'] as List? ?? const []) CasePhoto.fromJson(p)],
        mediaPending: json['media_status'] == 'pending',
      );
}

class CaseOutcome {
  final String dermatologist;
  final String? licenseNumber;
  final String? reportUrl;
  final String? prescriptionUrl;

  const CaseOutcome({required this.dermatologist, this.licenseNumber, this.reportUrl, this.prescriptionUrl});

  factory CaseOutcome.fromJson(Map<String, dynamic> json) => CaseOutcome(
        dermatologist: (json['dermatologist'] as Map)['name'] as String,
        licenseNumber: (json['dermatologist'] as Map)['license_number'] as String?,
        reportUrl: json['report_url'] as String?,
        prescriptionUrl: json['prescription_url'] as String?,
      );
}

class TeledermaCase {
  final String id;
  final CaseStatus status;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final String? thumbnailUrl;
  final List<CaseReport> reports;
  final CaseOutcome? outcome;

  const TeledermaCase({
    required this.id,
    required this.status,
    this.createdAt,
    this.submittedAt,
    this.thumbnailUrl,
    this.reports = const [],
    this.outcome,
  });

  bool get mediaPending => reports.any((r) => r.mediaPending);

  String get title {
    final site = reports.firstOrNull?.bodySite ?? '';
    return site.isEmpty ? 'Consulta de dermatología' : site;
  }

  factory TeledermaCase.fromJson(Map<String, dynamic> json) => TeledermaCase(
        id: json['id'] as String,
        status: CaseStatus.fromJson(json['status'] as String),
        createdAt: _date(json['created_at']),
        submittedAt: _date(json['submitted_at']),
        thumbnailUrl: json['thumbnail_url'] as String?,
        reports: [for (final r in json['reports'] as List? ?? const []) CaseReport.fromJson(r)],
        outcome: json['outcome'] == null ? null : CaseOutcome.fromJson(json['outcome']),
      );

  static DateTime? _date(Object? value) => DateTime.tryParse(value as String? ?? '')?.toLocal();
}

enum LegalConsentStatus { accepted, outdated, notAccepted }

class LegalConsent {
  final DateTime? acceptedAt;
  final DateTime? lastVersionAt;
  final String termsUrl;
  final String privacyUrl;
  final bool hasCommercialCommunications;

  const LegalConsent({
    this.acceptedAt,
    this.lastVersionAt,
    required this.termsUrl,
    required this.privacyUrl,
    this.hasCommercialCommunications = false,
  });

  LegalConsentStatus get status {
    final accepted = acceptedAt, lastVersion = lastVersionAt;
    if (accepted == null || lastVersion == null) return LegalConsentStatus.notAccepted;
    return accepted.isBefore(lastVersion) ? LegalConsentStatus.outdated : LegalConsentStatus.accepted;
  }

  factory LegalConsent.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? organization}) => LegalConsent(
        acceptedAt: DateTime.tryParse(json['accepted_at'] as String? ?? ''),
        lastVersionAt: DateTime.tryParse(json['last_version_at'] as String? ?? ''),
        termsUrl: organization?['terms_url'] as String? ?? json['terms_url'] as String,
        privacyUrl: organization?['privacy_url'] as String? ?? json['privacy_url'] as String,
        hasCommercialCommunications: json['has_commercial_communications'] as bool? ?? false,
      );
}
