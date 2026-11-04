import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/telederma_repository.dart';
import '../legit/legit_iframe.dart';
import '../models.dart';
import '../../design_system/design_system.dart';

class LegitIframeScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final String caseId;
  final Future<void> Function()? onCameraPermission;

  const LegitIframeScreen({super.key, required this.repository, required this.caseId, this.onCameraPermission});

  @override
  State<LegitIframeScreen> createState() => _LegitIframeScreenState();
}

enum _Phase { loadingSession, iframe, saving, error }

class _LegitIframeScreenState extends State<LegitIframeScreen> {
  _Phase _phase = _Phase.loadingSession;
  late Uri _url;
  String _error = '';
  bool _pageLoading = true;
  int _attempt = 0;

  String? _completedReportId;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final reportId = _completedReportId;
    if (reportId != null) return _attachReport(reportId);
    setState(() {
      _phase = _Phase.loadingSession;
      _pageLoading = true;
      _attempt++;
    });
    try {
      final url = await widget.repository.createIframeSession(widget.caseId);
      if (!mounted) return;
      setState(() {
        _url = url;
        _phase = _Phase.iframe;
      });
    } catch (_) {
      _fail('No se ha podido iniciar el servicio de dermatología.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = message;
    });
  }

  Future<void> _attachReport(String reportId) async {
    setState(() => _phase = _Phase.saving);
    try {
      final report = await widget.repository.attachReport(widget.caseId, reportId);
      await widget.repository.submitCase(widget.caseId);
      if (mounted) Navigator.of(context).pop(report);
    } catch (_) {
      _fail('Las fotos se han analizado pero no hemos podido enviar el caso.');
    }
  }

  void _onMessage(LegitMessage message) {
    switch (message.message) {
      case LegitMessage.analysisCompleted:
        final id = message.id;
        if (_completedReportId != null || id == null) return;
        _completedReportId = id;
        _attachReport(id);
      case LegitMessage.imageRejected:
        final reasons = message.payload is List ? (message.payload as List).join(', ') : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto rechazada${reasons.isEmpty ? '' : ': $reasons'}. Repítela, por favor.')),
        );
      case LegitMessage.invalidCompanyKey:
        _fail('La sesión ha caducado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Nuevo caso'),
      ),
      body: switch (_phase) {
        _Phase.loadingSession => const Center(child: CircularProgressIndicator.adaptive()),
        _Phase.iframe => Stack(
            children: [
              _buildWebView(),
              if (_pageLoading) const Center(child: CircularProgressIndicator.adaptive()),
            ],
          ),
        _Phase.saving => const _SavingCase(),
        _Phase.error => _ErrorView(message: _error, onRetry: _prepare),
      },
    );
  }

  Widget _buildWebView() {
    final url = _url;
    return InAppWebView(
      key: ValueKey(_attempt),
      initialFile: url.hasScheme ? null : url.path,
      initialUrlRequest: url.hasScheme ? URLRequest(url: WebUri.uri(url)) : null,
      initialUserScripts: UnmodifiableListView([
        UserScript(source: legitBridgeScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      ]),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: 'camera',
        cacheEnabled: false,
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: legitBridgeHandler,
          callback: (args) async {
            if (!LegitIframe.isTrustedOrigin(await controller.getUrl())) return;
            final message = args.isEmpty ? null : LegitMessage.parse(args.first);
            if (message != null && mounted) _onMessage(message);
          },
        );
      },
      onLoadStop: (_, __) {
        if (mounted) setState(() => _pageLoading = false);
      },
      onReceivedError: (_, request, __) {
        if (request.isForMainFrame ?? true) _fail('No se ha podido cargar el servicio. Revisa tu conexión.');
      },
      onPermissionRequest: (_, request) async {
        final wantsCamera =
            request.resources.contains(PermissionResourceType.CAMERA) && LegitIframe.isTrustedOrigin(request.origin);
        if (!wantsCamera) return PermissionResponse(action: PermissionResponseAction.DENY);
        await widget.onCameraPermission?.call();
        return PermissionResponse(
          resources: [PermissionResourceType.CAMERA],
          action: PermissionResponseAction.GRANT,
        );
      },
    );
  }
}

class _SavingCase extends StatelessWidget {
  const _SavingCase();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator.adaptive(),
          SizedBox(height: 16),
          Text('Enviando tu caso…'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: MqTheme.of(context).textDisabled),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            MqButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

Future<CaseReport?> openLegitIframe(
  BuildContext context, {
  required TeledermaRepository repository,
  required String caseId,
  required MqTheme theme,
  Future<void> Function()? onCameraPermission,
}) {
  return Navigator.of(context).push<CaseReport>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => theme.wrap(LegitIframeScreen(
        repository: repository,
        caseId: caseId,
        onCameraPermission: onCameraPermission,
      )),
    ),
  );
}
