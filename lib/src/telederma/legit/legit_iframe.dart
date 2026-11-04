import 'dart:convert';

/// Where the Legit.Health iframe may come from. The URL itself, with every
/// parameter (key, locale, branding, `extraData`), is built by our backend.
abstract final class LegitIframe {
  /// Bundled simulator, returned by [MockTeledermaRepository] as a URL without scheme.
  static const simulatorAsset = 'packages/mediquo_flutter_sdk/assets/telederma/legit_iframe_mock.html';

  static bool isTrustedOrigin(Uri? uri) =>
      uri != null && (uri.scheme == 'file' || uri.host == 'legit.health' || uri.host.endsWith('.legit.health'));
}

/// Callback sent by the iframe: `{ message, id, payload? }`, posted as a JSON
/// string on mobile and as an object through `window.postMessage` on web.
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

/// Routes every iframe transport to [legitBridgeHandler]. The iframe calls
/// `webkit.messageHandlers.bridge` on iOS and `legitHealthJsObject` on
/// Android; neither exists in an InAppWebView, so both are shimmed.
/// `postMessage` covers the web transport.
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
