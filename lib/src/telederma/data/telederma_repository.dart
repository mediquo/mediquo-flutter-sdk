import 'dart:ui';

import '../models.dart';

abstract class TeledermaRepository {
  /// The organization's `primary_color`, null when it has none.
  Future<Color?> primaryColor();

  /// The patient's cases, newest first, without photos or analysis. 403 if the patient has no access.
  Future<List<TeledermaCase>> listCases();

  Future<TeledermaCase> getCase(String caseId);

  Future<TeledermaCase> createCase({String? consultationReason});

  /// Only drafts can be discarded.
  Future<void> discardCase(String caseId);

  /// Iframe URL with a single-use key that expires in 60 s: load it right away
  /// and ask for a new one on every zone and every reload.
  Future<Uri> createIframeSession(String caseId);

  /// Adds the zone analysed by the iframe. Idempotent per [reportId].
  Future<CaseReport> attachReport(String caseId, String reportId);

  Future<TeledermaCase> submitCase(String caseId);
}
