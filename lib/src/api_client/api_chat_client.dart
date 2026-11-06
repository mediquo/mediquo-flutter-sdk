import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiChatException implements Exception {
  final int statusCode;
  final String message;

  const ApiChatException(this.statusCode, this.message);

  @override
  String toString() => 'ApiChatException($statusCode): $message';
}

class ApiChatClient {
  ApiChatClient({
    required this.apiKey,
    required this.token,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String token;
  static const _baseUrl = 'https://chat.mediquo.com';
  final http.Client _http;
  Future<Map<String, dynamic>>? _session;

  Future<Map<String, dynamic>> patient() async => (await (_session ??= _login()))['patient'] as Map<String, dynamic>;

  Future<dynamic> send(String method, String path, {Object? body}) async {
    var response = await _request(method, path, body, await _accessToken(_session ??= _login()));
    if (response.statusCode == 401) {
      _session = _login();
      response = await _request(method, path, body, await _accessToken(_session!));
    }
    return _decode(response);
  }

  static Future<String> _accessToken(Future<Map<String, dynamic>> session) async =>
      (await session)['access_token'] as String;

  Future<Map<String, dynamic>> _login() async {
    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/login/v1/token'),
        headers: _headers(),
        body: jsonEncode({'token': token}),
      );
      return _decode(response) as Map<String, dynamic>;
    } catch (_) {
      _session = null;
      rethrow;
    }
  }

  Future<http.Response> _request(String method, String path, Object? body, String session) {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))..headers.addAll(_headers(session: session));
    if (body != null) request.body = jsonEncode(body);
    return _http.send(request).then(http.Response.fromStream);
  }

  Map<String, String> _headers({String? session}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': apiKey,
        if (session != null) 'Authorization': 'Bearer $session',
      };

  static dynamic _decode(http.Response response) {
    dynamic json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    final message = json is Map && json['message'] is String ? json['message'] as String : response.reasonPhrase;
    throw ApiChatException(response.statusCode, message ?? '');
  }
}
