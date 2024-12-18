library mediquo_flutter_sdk;

import 'dart:async';
import 'dart:io';
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
  final Future Function() onMicrophonePermission;
  final Future Function() onCameraPermission;
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
    this.theme = const MediquoWidgetTheme()
  }) : super(key: key);

  @override
  State<MediquoWidget> createState() => _MediquoWidgetState();
}

class _MediquoWidgetState extends State<MediquoWidget> with WidgetsBindingObserver {
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
    initConnectivity();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    url = 'https://widget.mediquo.com/integration/index.html?api_key=${widget.apiKey}&token=${widget.token}&platform=${_getPlatform()}&environment=${widget.environment.name}';
    super.initState();
  }

  _getPlatform()
  {
    if (Platform.isIOS) {
      return 'ios';
    }

    return 'android';
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await webViewController?.evaluateJavascript(source: "window.parent.postMessage({ command: 'mediquo_native_lifecycle_changed',  payload: {state:'${state.name}'} }, '*');");
    }
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

  Future<void> _checkRequestError(WebUri failedUrl) async {
    if (_isMainPage(failedUrl)) {
      Navigator.pop(context);
      _showConnectionErrorAlertDialog();
    }

    if (_isFileDownload(failedUrl)) {
      _showConnectionErrorAlertDialog();

      if (Platform.isAndroid) {
        await webViewController?.clearHistory();
      }

      return webViewController?.loadUrl(urlRequest: new URLRequest(url: new WebUri(this.url)));
    }

    if (_isInmediateVideocallUrl(failedUrl)) {
      _showConnectionErrorAlertDialog();
    }

    return Future.value(null);
  }

  _isMainPage(WebUri failedUrl) {
    return failedUrl.toString() == url;
  }

  _isInmediateVideocallUrl(WebUri failedUrl) {
    return failedUrl.toString().contains('consultations/v1/immediate-videocall');
  }

  _isFileDownload(WebUri failedUrl) {
    return failedUrl.toString().contains('mediquo.com') && failedUrl.toString().contains('getFile');
  }

  Future<String> _checkWidgetLoading() async {
    late List<ConnectivityResult> result;
    result = await _connectivity.checkConnectivity();
    if (result[0] == ConnectivityResult.none) {
      return Future.error("No connectivity");
    }

    return Future.value("ok");
  }

  _loadWidget() {
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
                            onReceivedHttpError: (
                                InAppWebViewController controller,
                                WebResourceRequest request,
                                WebResourceResponse errorResponse
                            ) async => await _checkRequestError(request.url),
                            onReceivedError: (
                                InAppWebViewController controller,
                                WebResourceRequest request,
                                WebResourceError error
                            ) async => await _checkRequestError(request.url),
                            onLoadStart: (controller, url) {
                              webViewController = controller;
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
                                  handlerName: 'mediquo_native_download',
                                  callback: (args) {
                                    final url = args[0]['url'];

                                    if (url != null) {
                                      widget.onDownload(url);
                                    }
                                  }
                              );

                              controller.addJavaScriptHandler(
                                  handlerName: 'mediquo_native_close',
                                  callback: (args) {
                                    Navigator.pop(context);
                                  }
                              );

                              controller.addJavaScriptHandler(
                                  handlerName: 'mediquo_native_reload',
                                  callback: (args) {
                                    webViewController?.reload();
                                  }
                              );

                              controller.addJavaScriptHandler(
                                  handlerName: 'mediquo_native_camera_permission',
                                  callback: (args) async {
                                    await widget.onCameraPermission();
                                  }
                              );

                              controller.addJavaScriptHandler(
                                  handlerName: 'mediquo_native_connection_error_alert',
                                  callback: (args) {
                                    _showConnectionErrorAlertDialog();
                                  }
                              );
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

                                if (uri.toString().contains('getFile')) {
                                  if (!uri.toString().contains('force_download')) {
                                    var forcedUrl = new WebUri('${uri.toString()}&force_download=1');
                                    controller.loadUrl(urlRequest: new URLRequest(url: forcedUrl));
                                    return NavigationActionPolicy.CANCEL;
                                  }
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
  _loadingPage() {
    return Container(
      color: widget.theme.containerColor,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cargando'),
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: Stack()
          ),
        ]),
      ),
    );
  }
  _errorPage() {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: Card.outlined(
          margin: EdgeInsets.only(right: 16.0, left: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 32.0, bottom: 16.0, left: 32.0, right: 32.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(
                      Icons.wifi_off,
                      color: Colors.red,
                      size: 32.0,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 0.0, bottom: 16.0, left: 32.0, right: 32.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Error de conexión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 0.0, bottom: 16.0, left: 32.0, right: 32.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'El contenido no se ha podido cargar. Verifica tu conexión o inténtalo más tarde.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(width: 8),
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _checkWidgetLoading(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasError) {
            return _errorPage();
          } else if (snapshot.hasData) {
            return _loadWidget();
          }
          return _loadingPage();
        }
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