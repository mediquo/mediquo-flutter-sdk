import 'dart:ui';

import '../models.dart';

abstract class TeledermaRepository {
  Future<Color?> primaryColor();

  Future<LegalConsent> legalConsent();

  Future<void> acceptLegalConsent(LegalConsent consent);

  Future<List<TeledermaCase>> listCases();

  Future<TeledermaCase> getCase(String caseId);

  Future<TeledermaCase> createCase();

  Future<void> discardCase(String caseId);

  Future<Uri> createIframeSession(String caseId);

  Future<CaseReport> attachReport(String caseId, String reportId);

  Future<TeledermaCase> submitCase(String caseId);
}
