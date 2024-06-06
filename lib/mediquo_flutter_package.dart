library mediquo_flutter_package;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class MediquoWidget extends StatefulWidget {
  final String apiKey;
  final String token;
  final Function(String) onDownload;
  final Function() onMicrophonePermission;
  final Function() onCameraPermission;

  const MediquoWidget({
    Key? key,
    required this.apiKey,
    required this.token,
    required this.onDownload,
    required this.onMicrophonePermission,
    required this.onCameraPermission
  }) : super(key: key);

  @override
  State<MediquoWidget> createState() => _MediquoWidgetState();
}

class _MediquoWidgetState extends State<MediquoWidget> {
  final GlobalKey webViewKey = GlobalKey();

  String url = '';
  String title = '';
  // double progress = 0;
  bool? isSecure;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    url = 'https://deploy-preview-197--mediquo-widget.netlify.app/integration/index.html?apiKey=${widget.apiKey}?token=${widget.token}';
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
                  initialUrlRequest: URLRequest(url: WebUri('https://deploy-preview-197--mediquo-widget.netlify.app/integration/index.html?api_key=ePa2hnje9RqnEq97&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vY2hhdC1kZXYubWVkaXF1by5jb20vc2RrL3YxL3BhdGllbnRzL2F1dGhlbnRpY2F0ZSIsImlhdCI6MTY5OTYwOTAzNiwibmJmIjoxNjk5NjA5MDM2LCJqdGkiOiJCUWhwWmVQYm5kOTRmOGtkIiwic3ViIjoiNWQ3MjUzODEtMWM3Zi00MTI5LWE1MmMtNjdkNTE2NzNmYzVlIiwicHJ2IjoiOWVhNDBmMDk5MzU4OWE3OGQ1MmFjZThjNTNjMzA1OTM1MjBlZDQyNyJ9.tUP1YzbJQC6hbbEchKffLw_y8FZPUJSOhUK__8ZE5X0')),
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