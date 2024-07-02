library mediquo_flutter_sdk;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


enum MediquoWidgetEnvironment {
  production,
  sandbox
}

class MediquoWidgetTheme {
  final Color containerColor;

  const MediquoWidgetTheme({
    this.containerColor = Colors.white
  });
}

class MediquoWidget extends StatefulWidget {
  final MediquoWidgetEnvironment environment;
  final String apiKey;
  final String token;
  final Function(String) onDownload;
  final Function(String) onLoadUrl;
  final Function() onMicrophonePermission;
  final Function() onCameraPermission;
  final MediquoWidgetTheme theme;

  const MediquoWidget({
    Key? key,
    this.environment = MediquoWidgetEnvironment.production,
    required this.apiKey,
    required this.token,
    required this.onDownload,
    required this.onLoadUrl,
    required this.onMicrophonePermission,
    required this.onCameraPermission,
    this.theme = const MediquoWidgetTheme(),
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

  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    url = 'https://widget.mediquo.com/integration/index.html?api_key=${widget.apiKey}&token=${widget.token}&environment=${widget.environment.name}';

    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  _showConnectionErrorAlertDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error de conexión'),
        content: const Text('El contenido no se ha podido cargar. Verifica tu conexión o inténtalo más tarde.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cerrar'),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  _isNotConnectedToInternet() {
    return _connectionStatus[0] == ConnectivityResult.none;
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
        child: new Container(
          color: widget.theme.containerColor,
          child: new SafeArea(
              child: Scaffold(
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
                              /*
                              if (_isNotConnectedToInternet()) {
                                _showConnectionErrorAlertDialog();
                              }*/

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
                              if (_isNotConnectedToInternet()) {
                                _showConnectionErrorAlertDialog();
                                return NavigationActionPolicy.CANCEL;
                              }

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
          ),
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