library mediquo_flutter_package;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

enum MediquoWidgetEnvironment {
  production,
  sandbox
}

class MediquoWidget extends StatefulWidget {
  final MediquoWidgetEnvironment environment;
  final String apiKey;
  final String token;
  final Function(String) onDownload;
  final Function() onMicrophonePermission;
  final Function() onCameraPermission;

  const MediquoWidget({
    Key? key,
    this.environment = MediquoWidgetEnvironment.production,
    required this.apiKey,
    required this.token,
    required this.onDownload,
    required this.onMicrophonePermission,
    required this.onCameraPermission,
  }) : super(key: key);

  @override
  State<MediquoWidget> createState() => _MediquoWidgetState();
}

class _MediquoWidgetState extends State<MediquoWidget> {
  final GlobalKey webViewKey = GlobalKey();

  String url = '';
  String title = '';
  bool? isSecure;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    url = widget.environment == MediquoWidgetEnvironment.production
        ? 'https://widget.mediquo.com/integration/index.html?api_key=${widget.apiKey}&token=${widget.token}'
        : 'https://widget.dev.mediquo.com/integration/index.html?api_key=${widget.apiKey}&token=${widget.token}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat de MediQuo')
        /*leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),*/
      ),
      body: Column(children: <Widget>[
        Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri(url)),
                  initialSettings: InAppWebViewSettings(
                      transparentBackground: true,
                      safeBrowsingEnabled: true,
                      isFraudulentWebsiteWarningEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      iframeAllow: "camera; microphone",
                      iframeAllowFullscreen: true,
                      useOnDownloadStart: true
                  ),
                  /*onReceivedHttpError: (controller, request, errorResponse) async {
                    // Handle HTTP errors here
                    var isForMainFrame = request.isForMainFrame ?? false;
                    if (!isForMainFrame) {
                      return;
                    }
                  },*/
                  /*onWebViewCreated: (controller) async {
                    webViewController = controller;
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android) {
                      await controller.startSafeBrowsing();
                    }
                  },*/
                  onLoadStart: (controller, url) {
                    if (url != null) {
                      setState(() {
                        this.url = url.toString();
                        isSecure = urlIsSecure(url);
                      });
                    }
                  },
                  onLoadStop: (controller, url) async {
                    if (url != null) {
                      setState(() {
                        this.url = url.toString();
                      });
                    }
                  },
                  onDownloadStartRequest: (InAppWebViewController controller, DownloadStartRequest request) {
                    widget.onDownload(request.url.rawValue);
                  },
                  onPermissionRequest: (InAppWebViewController controller, PermissionRequest request) async {
                    if (request.resources.contains(PermissionResourceType.MICROPHONE)) {
                      await widget.onMicrophonePermission();
                    }

                    if (request.resources.contains(PermissionResourceType.CAMERA)) {
                      await widget.onCameraPermission();
                    }

                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT
                    );
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url;
                    if (navigationAction.isForMainFrame &&
                        url != null &&
                        ![
                          'http',
                          'https',
                          'file',
                          'chrome',
                          'data',
                          'javascript',
                          'about'
                        ].contains(url.scheme)) {
                      if (await canLaunchUrl(url)) {
                        launchUrl(url);
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
                /* progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),*/
              ],
            )),
      ]),
    );
  }

  static bool urlIsSecure(Uri url) {
    return (url.scheme == "https") || isLocalizedContent(url);
  }

  static bool isLocalizedContent(Uri url) {
    return (url.scheme == "file" ||
        url.scheme == "chrome" ||
        url.scheme == "data" ||
        url.scheme == "javascript" ||
        url.scheme == "about");
  }
}