import 'dart:ui';

import '../../api_client/api_chat_client.dart';
import '../models.dart';
import 'telederma_repository.dart';

class ApiChatTeledermaClient implements TeledermaRepository {
  ApiChatTeledermaClient(this._api);

  final ApiChatClient _api;

  static String _case(String caseId) => '/imq/telederma/v1/cases/${Uri.encodeComponent(caseId)}';

  Future<Map<String, dynamic>>? _setup;

  Future<Map<String, dynamic>> _organization() => _setup ??= _fetchOrganization();

  Future<Map<String, dynamic>> _fetchOrganization() async {
    try {
      final json = await _api.send('GET', '/organizations/v1/setup');
      return json['data'] as Map<String, dynamic>;
    } catch (_) {
      _setup = null;
      rethrow;
    }
  }

  @override
  Future<Color?> primaryColor() async {
    final hex = ((await _organization())['primary_color'] as String?)?.replaceFirst('#', '');
    final rgb = hex?.length == 6 ? int.tryParse(hex!, radix: 16) : null;
    return rgb == null ? null : Color(0xFF000000 | rgb);
  }

  @override
  Future<LegalConsent> legalConsent() async {
    Map<String, dynamic>? organization;
    try {
      organization = (await _organization())['legal_consent'] as Map<String, dynamic>?;
    } on ApiChatException {
      organization = null;
    }
    return LegalConsent.fromJson((await _api.patient())['legal_consent'], organization: organization);
  }

  @override
  Future<void> acceptLegalConsent(LegalConsent consent) => _api.send('POST', '/profile/v1/legal-consent', body: {
        'terms_accepted': true,
        'privacy_accepted': true,
        'commercial_accepted': consent.hasCommercialCommunications,
      });

  @override
  Future<List<TeledermaCase>> listCases() async {
    final json = await _api.send('GET', '/imq/telederma/v1/cases');
    return [for (final c in json['data'] as List) TeledermaCase.fromJson(c)];
  }

  @override
  Future<TeledermaCase> getCase(String caseId) async {
    final json = await _api.send('GET', _case(caseId));
    return TeledermaCase.fromJson(json['data']);
  }

  @override
  Future<TeledermaCase> createCase() async {
    final json = await _api.send('POST', '/imq/telederma/v1/cases', body: {});
    return TeledermaCase.fromJson(json['data']);
  }

  @override
  Future<void> discardCase(String caseId) => _api.send('DELETE', _case(caseId));

  @override
  Future<Uri> createIframeSession(String caseId) async {
    final json = await _api.send('POST', '${_case(caseId)}/iframe-sessions');
    return Uri.parse((json['data'] ?? json)['url'] as String);
  }

  @override
  Future<CaseReport> attachReport(String caseId, String reportId) async {
    final json = await _api.send('POST', '${_case(caseId)}/reports', body: {'report_id': reportId});
    return CaseReport.fromJson(json['data']);
  }

  @override
  Future<TeledermaCase> submitCase(String caseId) async {
    final json = await _api.send('POST', '${_case(caseId)}/submit');
    return TeledermaCase.fromJson(json['data']);
  }
}
