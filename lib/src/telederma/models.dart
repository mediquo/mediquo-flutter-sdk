library;

enum CaseStatus {
  draft('Borrador'),
  submitted('Pendiente'),
  assigned('Pendiente'),
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

  const CaseReport({
    required this.id,
    required this.bodySite,
    this.answers = const [],
    this.photos = const [],
  });

  factory CaseReport.fromJson(Map<String, dynamic> json) => CaseReport(
        id: json['id'] as String,
        bodySite: (json['body_site'] as Map?)?['name'] as String? ?? '',
        answers: [for (final a in json['answers'] as List? ?? const []) CaseAnswer.fromJson(a)],
        photos: [for (final p in json['photos'] as List? ?? const []) CasePhoto.fromJson(p)],
      );
}

class CaseDocument {
  static const report = 'report';
  static const prescription = 'prescription';
  static const diagnosticTestPrescription = 'diagnostic_test_prescription';

  final String type;
  final String id;
  final Uri? downloadUrl;

  const CaseDocument({required this.type, required this.id, this.downloadUrl});

  factory CaseDocument.fromJson(Map<String, dynamic> json) => CaseDocument(
        type: json['type'] as String,
        id: '${json['id']}',
        downloadUrl: switch (json['download_url']) { final String url => Uri.tryParse(url), _ => null },
      );
}

class CaseProfessional {
  final String name;
  final String speciality;
  final String? collegiateNumber;
  final String? avatarUrl;

  const CaseProfessional({required this.name, required this.speciality, this.collegiateNumber, this.avatarUrl});

  String get detail => [speciality, if (collegiateNumber case final number?) number].join(' · ');

  String get initials => name
      .split(' ')
      .where((word) => word.isNotEmpty && !word.endsWith('.'))
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  factory CaseProfessional.fromJson(Map<String, dynamic> json) => CaseProfessional(
        name: json['name'] as String,
        speciality: json['speciality'] as String,
        collegiateNumber: json['collegiate_number'] as String?,
        avatarUrl: json['avatar'] as String?,
      );
}

class TeledermaCase {
  final String id;
  final CaseStatus status;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? finishedAt;
  final String? thumbnailUrl;
  final CaseProfessional? professional;
  final List<CaseReport> reports;
  final List<CaseDocument> documents;

  const TeledermaCase({
    required this.id,
    required this.status,
    this.createdAt,
    this.submittedAt,
    this.finishedAt,
    this.thumbnailUrl,
    this.professional,
    this.reports = const [],
    this.documents = const [],
  });

  String get title {
    final site = reports.firstOrNull?.bodySite ?? '';
    return site.isEmpty ? 'Consulta de dermatología' : site;
  }

  factory TeledermaCase.fromJson(Map<String, dynamic> json) => TeledermaCase(
        id: json['id'] as String,
        status: CaseStatus.fromJson(json['status'] as String),
        createdAt: _date(json['created_at']),
        submittedAt: _date(json['submitted_at']),
        finishedAt: _date(json['finished_at']),
        thumbnailUrl: json['thumbnail_url'] as String?,
        professional: switch (json['professional']) {
          final Map<String, dynamic> p => CaseProfessional.fromJson(p),
          _ => null,
        },
        reports: [for (final r in json['reports'] as List? ?? const []) CaseReport.fromJson(r)],
        documents: [for (final d in json['documents'] as List? ?? const []) CaseDocument.fromJson(d)],
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
