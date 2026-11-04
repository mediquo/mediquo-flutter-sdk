import 'dart:ui';

import '../models.dart';

abstract class TeledermaRepository {
  Future<Color?> primaryColor();

  Future<List<TeledermaCase>> listCases();

  Future<TeledermaCase> getCase(String caseId);

  Future<TeledermaCase> createCase({String? consultationReason});

  Future<void> discardCase(String caseId);

  Future<Uri> createIframeSession(String caseId);

  Future<CaseReport> attachReport(String caseId, String reportId);

  Future<TeledermaCase> submitCase(String caseId);
}
