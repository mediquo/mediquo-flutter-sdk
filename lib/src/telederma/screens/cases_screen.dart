import 'package:flutter/material.dart';

import '../../api_client/api_chat_client.dart';
import '../../design_system/design_system.dart';
import '../data/api_chat_telederma_client.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'case_detail_screen.dart';
import 'legit_iframe_screen.dart';
import 'service_info_screen.dart';
import 'terms_screen.dart';

sealed class TeledermaRoute {
  const TeledermaRoute();

  const factory TeledermaRoute.cases() = _CasesRoute;
  const factory TeledermaRoute.caseDetail(String caseId) = _CaseDetailRoute;
  const factory TeledermaRoute.newConsultation() = _NewConsultationRoute;
}

class _CasesRoute extends TeledermaRoute {
  const _CasesRoute();
}

class _CaseDetailRoute extends TeledermaRoute {
  final String caseId;
  const _CaseDetailRoute(this.caseId);
}

class _NewConsultationRoute extends TeledermaRoute {
  const _NewConsultationRoute();
}

class MediquoTelederma extends StatefulWidget {
  final String apiKey;
  final String token;
  final void Function(String url) onLoadUrl;
  final Future<void> Function(String filePath) onOpenDocument;
  final TeledermaRoute initialRoute;
  final MqTheme? theme;
  final Future<void> Function()? onCameraPermission;
  final TeledermaRepository? _repository;

  const MediquoTelederma({
    super.key,
    required this.apiKey,
    required this.token,
    required this.onLoadUrl,
    required this.onOpenDocument,
    this.initialRoute = const TeledermaRoute.cases(),
    this.theme,
    this.onCameraPermission,
  }) : _repository = null;

  @visibleForTesting
  const MediquoTelederma.withRepository(
    TeledermaRepository repository, {
    super.key,
    required this.onLoadUrl,
    required this.onOpenDocument,
    this.initialRoute = const TeledermaRoute.cases(),
    this.theme,
    this.onCameraPermission,
  })  : _repository = repository,
        apiKey = '',
        token = '';

  @override
  State<MediquoTelederma> createState() => _MediquoTeledermaState();
}

class _MediquoTeledermaState extends State<MediquoTelederma> {
  late final TeledermaRepository _repository =
      widget._repository ?? ApiChatTeledermaClient(ApiChatClient(apiKey: widget.apiKey, token: widget.token));
  late Future<List<TeledermaCase>> _cases;
  late final AppLifecycleListener _lifecycle;
  bool _starting = false;
  bool _consentAccepted = false;
  MqTheme? _brand;

  MqTheme get _theme => widget.theme ?? _brand ?? const MqTheme();
  bool get _branded => widget.theme != null || _brand != null;

  @override
  void initState() {
    super.initState();
    _cases = _load();
    // The dermatologist may finish a case while the app is in the background.
    _lifecycle = AppLifecycleListener(onResume: _reload);
    final ready = widget.theme == null ? _loadBrand() : Future<void>.value();
    ready.then((_) => WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialRoute()));
  }

  void _openInitialRoute() {
    if (!mounted) return;
    switch (widget.initialRoute) {
      case _CaseDetailRoute(:final caseId):
        _openCase(caseId);
      case _NewConsultationRoute():
        _startConsultation();
      case _CasesRoute():
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<List<TeledermaCase>> _load() => _repository.listCases();

  Future<void> _loadBrand() async {
    final color = await _repository.primaryColor().catchError((_) => null);
    if (mounted) setState(() => _brand = color == null ? const MqTheme() : MqTheme.fromBrand(color));
  }

  void _reload() {
    setState(() {
      _cases = _load();
    });
  }

  Future<T?> _push<T>(Widget page, {bool fullscreenDialog = false}) => Navigator.of(context).push<T>(
        MaterialPageRoute(fullscreenDialog: fullscreenDialog, builder: (_) => _theme.wrap(page)),
      );

  Future<void> _startConsultation() async {
    setState(() => _starting = true);
    try {
      if (!_consentAccepted) {
        final consent = await _repository.legalConsent();
        _consentAccepted = consent.status == LegalConsentStatus.accepted ||
            await _push<bool>(TermsScreen(
                  repository: _repository,
                  consent: consent,
                  onLoadUrl: widget.onLoadUrl,
                )) ==
                true;
        if (!_consentAccepted) return;
      }
      final created = await _repository.createCase();
      final sent = await _push<bool>(
        LegitIframeScreen(
          repository: _repository,
          caseId: created.id,
          onCameraPermission: widget.onCameraPermission,
        ),
        fullscreenDialog: true,
      );
      if (sent != true) _repository.discardCase(created.id).ignore();
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      final forbidden = e is ApiChatException && e.statusCode == 403;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(forbidden
            ? 'El servicio de dermatología no está disponible para tu cuenta.'
            : 'No se ha podido iniciar la consulta. Inténtalo de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openCase(String caseId) async {
    await _push(CaseDetailScreen(
      repository: _repository,
      caseId: caseId,
      onOpenDocument: widget.onOpenDocument,
    ));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _theme.wrap(FutureBuilder<List<TeledermaCase>>(
      future: _cases,
      builder: (context, snapshot) {
        final error = snapshot.error;
        final forbidden = error is ApiChatException && error.statusCode == 403;
        final loading = (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) || !_branded;
        final all = snapshot.data ?? const <TeledermaCase>[];
        final cases = [
          for (final c in all)
            if (c.status case CaseStatus.submitted || CaseStatus.assigned) c,
          for (final c in all)
            if (c.status == CaseStatus.finished) c,
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dermatología'),
            actions: [
              if (error == null)
                IconButton(
                  icon: const MqIcon(MqIcons.infoCircle),
                  tooltip: 'Más información',
                  onPressed: () => _push(ServiceInfoScreen(repository: _repository, onLoadUrl: widget.onLoadUrl)),
                ),
            ],
          ),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
          floatingActionButton: error != null || loading || cases.isEmpty
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(MqRadius.md)),
                    boxShadow: [BoxShadow(color: Color(0x2E0A0A21), blurRadius: 6, offset: Offset(0, 4))],
                  ),
                  child: MqButton(
                    label: 'Nueva consulta',
                    icon: MqIcons.plus,
                    onPressed: _starting ? null : _startConsultation,
                  ),
                ),
          body: _body(context, loading: loading, forbidden: forbidden, error: error != null, cases: cases),
        );
      },
    ));
  }

  Widget _body(
    BuildContext context, {
    required bool loading,
    required bool forbidden,
    required bool error,
    required List<TeledermaCase> cases,
  }) {
    if (forbidden) {
      return const _Centered(
        child: ScreenHero(
          icon: MqIcons.lock,
          title: 'Servicio no disponible',
          description: 'El servicio de dermatología no está incluido en tu cuenta.',
        ),
      );
    }
    if (error) {
      return ListView(
        padding: scrollPadding(context, const EdgeInsets.all(24)),
        children: [
          const MqBanner(
            icon: MqIcons.alertCircle,
            tone: MqTone.error,
            title: 'No hemos podido cargar tus consultas',
            description: 'Revisa tu conexión e inténtalo de nuevo.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: MqButton(label: 'Reintentar', variant: MqButtonVariant.secondary, onPressed: _reload),
          ),
        ],
      );
    }
    if (!loading && cases.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: () async => _reload(),
        child: _Centered(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHero(
                icon: MqIcons.heartRate,
                title: 'Tu consulta de dermatología',
                description:
                    'Envía fotos de la zona afectada y un dermatólogo te responderá en menos de 48 horas laborables.',
              ),
              const SizedBox(height: 32),
              MqButton(label: 'Nueva consulta', expand: true, onPressed: _starting ? null : _startConsultation),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: scrollPadding(context, const EdgeInsets.fromLTRB(24, 24, 24, 96)),
        children: [
          const Text('Tus consultas', style: headingStyle),
          const SizedBox(height: 12),
          if (loading)
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: MqSkeleton(height: 110, radius: MqRadius.lg),
              )
          else
            for (final c in cases)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CaseCard(teledermaCase: c, onTap: () => _openCase(c.id)),
              ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final TeledermaCase teledermaCase;
  final VoidCallback onTap;

  const _CaseCard({required this.teledermaCase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = teledermaCase;
    final t = MqTheme.of(context);
    final date = c.submittedAt ?? c.createdAt;
    return Material(
      color: t.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MqRadius.lg),
        side: BorderSide(color: t.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: CaseImageView(url: c.thumbnailUrl, size: 56, radius: 10)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.title, style: const TextStyle(fontSize: MqFontSize.base, fontWeight: FontWeight.w500)),
                          if (date != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              capitalize(formatDateTime(date)),
                              style: secondaryText(context, fontSize: MqFontSize.xs),
                            ),
                          ],
                          const SizedBox(height: 8),
                          CaseStatusBadge(status: c.status),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: MqIcon(MqIcons.arrowRight, color: t.textPrimary),
                    ),
                  ],
                ),
              ),
              if ((c.status, c.professional)
                  case (CaseStatus.assigned || CaseStatus.finished, final professional?)) ...[
                const Divider(height: 24),
                Text(professional.name, style: secondaryText(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final Widget child;

  const _Centered({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: scrollPadding(context, const EdgeInsets.fromLTRB(24, 24, 24, 64)),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
