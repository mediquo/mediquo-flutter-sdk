import 'dart:convert';

abstract final class LegitIframe {
  static const simulatorAsset = 'packages/mediquo_flutter_sdk/assets/telederma/legit_iframe_mock.html';

  static bool isTrustedOrigin(Uri? uri) =>
      uri != null && (uri.scheme == 'file' || uri.host == 'legit.health' || uri.host.endsWith('.legit.health'));
}

class LegitMessage {
  static const analysisCompleted = 'analysis_completed';
  static const imageRejected = 'image_rejected';
  static const invalidCompanyKey = 'invalid_company_key';

  final String message;
  final String? id;
  final dynamic payload;

  const LegitMessage({required this.message, this.id, this.payload});

  static LegitMessage? parse(dynamic raw) {
    try {
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map || data['message'] is! String) return null;
      return LegitMessage(message: data['message'], id: data['id']?.toString(), payload: data['payload']);
    } on FormatException {
      return null;
    }
  }
}

const legitBridgeHandler = 'legitHealth';

// The iframe posts to `webkit.messageHandlers.bridge` (iOS) or `legitHealthJsObject` (Android); neither exists in an InAppWebView.
const legitBridgeScript = '''
(function () {
  if (window.__mediquoLegitBridge) return;
  window.__mediquoLegitBridge = true;
  function forward(message) {
    var json = typeof message === 'string' ? message : JSON.stringify(message);
    window.flutter_inappwebview.callHandler('$legitBridgeHandler', json);
  }
  if (!window.legitHealthJsObject) {
    window.legitHealthJsObject = { postMessage: forward };
  }
  try {
    var handlers = window.webkit && window.webkit.messageHandlers;
    if (handlers && !handlers.bridge) {
      Object.defineProperty(handlers, 'bridge', { value: { postMessage: forward } });
    }
  } catch (e) {}
  window.addEventListener('message', function (event) {
    if (event.data && event.data.message) forward(event.data);
  });
})();
''';
