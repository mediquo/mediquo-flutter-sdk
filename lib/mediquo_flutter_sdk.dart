library mediquo_flutter_sdk;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum MediquoWidgetEnvironment {
  production,
  sandbox
}

class MediquoWidget extends StatefulWidget {
  final MediquoWidgetEnvironment environment;
  final String apiKey;
  final String token;
  final Function(String) onDownload;
  final Function(String) onLoadUrl;
  final Function() onMicrophonePermission;
  final Function() onCameraPermission;

  const MediquoWidget({
    Key? key,
    this.environment = MediquoWidgetEnvironment.production,
    required this.apiKey,
    required this.token,
    required this.onDownload,
    required this.onLoadUrl,
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
    url = 'https://widget.mediquo.com/integration/index.html?api_key=${widget.apiKey}&token=${widget.token}&environment=${widget.environment.name}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        /* onPopInvoked: (bool didPop) async {
          if  (didPop) {
            return;
          }
          return;
        },*/
        child:  Scaffold(
          /*appBar: AppBar(
              title: const Text('')
          ),*/
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
                        useOnDownloadStart: true,
                        cacheEnabled: false
                      ),
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
                      onWebViewCreated: (controller) {
                        controller.addJavaScriptHandler(
                            handlerName: 'mediquo_flutter_sdk_close',
                            callback: (args) {
                              Navigator.pop(context);
                            });
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
                      shouldOverrideUrlLoading: (InAppWebViewController controller, NavigationAction navigationAction) async {
                        final uri = navigationAction.request.url!;
                        if (uri.toString().contains('mediquo.com')) {

                          if (uri.toString().contains('privacy') | uri.toString().contains('terms')) {
                            widget.onLoadUrl(uri.toString());
                            return NavigationActionPolicy.CANCEL;
                          }
                          
                          return NavigationActionPolicy.ALLOW;
                        }

                        widget.onLoadUrl(uri.toString());
                        return NavigationActionPolicy.CANCEL;
                        },
                    ),
                  ],
                )),
          ]),
        )
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