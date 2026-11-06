import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/telederma_repository.dart';
import '../widgets/common.dart';
import 'consultation_sent_screen.dart';
import '../legit/legit_iframe.dart';
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
      // Android's file chooser only offers the camera once the permission is granted.
      if (defaultTargetPlatform == TargetPlatform.android) await widget.onCameraPermission?.call();
      final url = await widget.repository.createIframeSession(widget.caseId);
      if (!mounted) return;
      setState(() {
        _url = url;
        _phase = _Phase.iframe;
      });
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (mounted) setState(() => _phase = _Phase.error);
  }

  Future<void> _close() async {
    if (_phase == _Phase.saving) return;
    if (_phase == _Phase.iframe && !await _confirmExit()) return;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<bool> _confirmExit() async {
    final exit = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewPaddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Salir sin enviar tu consulta?',
                style: TextStyle(fontSize: MqFontSize.xl, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(
              'Si sales ahora, perderás lo que has rellenado y tendrás que empezar de nuevo.',
              style: secondaryText(context, fontSize: MqFontSize.base),
            ),
            const SizedBox(height: 24),
            MqButton(label: 'Seguir con la consulta', expand: true, onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 8),
            MqButton(
              label: 'Salir',
              variant: MqButtonVariant.outline,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    return exit ?? false;
  }

  Future<void> _attachReport(String reportId) async {
    setState(() => _phase = _Phase.saving);
    try {
      await widget.repository.attachReport(widget.caseId, reportId);
      await widget.repository.submitCase(widget.caseId);
      if (!mounted) return;
      final theme = MqTheme.of(context);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => theme.wrap(const ConsultationSentScreen())),
        result: true,
      );
    } catch (_) {
      _fail();
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
        _fail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: _phase == _Phase.error
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(icon: const MqIcon(MqIcons.xClose), tooltip: 'Cerrar', onPressed: _close),
                title: const Text('Nueva consulta'),
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
          _Phase.error => const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: ScreenHero(
                    icon: MqIcons.alertCircle,
                    tone: MqTone.error,
                    centered: true,
                    title: 'No hemos podido enviar tu consulta',
                    description: 'Revisa tu conexión e inténtalo de nuevo. Si vuelve a fallar, prueba en unos minutos.',
                  ),
                ),
              ),
            ),
        },
        bottomNavigationBar: _phase == _Phase.error
            ? BottomActions(
                children: [
                  MqButton(label: 'Reintentar', expand: true, onPressed: _prepare),
                  MqButton(
                    label: 'Volver',
                    variant: MqButtonVariant.outline,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              )
            : null,
      ),
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
        if (request.isForMainFrame ?? true) _fail();
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
          Text('Enviando tu consulta…'),
        ],
      ),
    );
  }
}
