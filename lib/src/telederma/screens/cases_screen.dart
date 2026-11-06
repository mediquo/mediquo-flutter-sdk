import 'dart:async';

import 'package:flutter/material.dart';

import '../../api_client/api_chat_client.dart';
import '../../design_system/design_system.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'case_detail_screen.dart';
import 'legit_iframe_screen.dart';
import 'service_info_screen.dart';
import 'terms_screen.dart';

class MediquoTeledermaCases extends StatefulWidget {
  final TeledermaRepository repository;
  final void Function(String url) onLoadUrl;
  final MqTheme? theme;
  final Future<void> Function()? onCameraPermission;

  const MediquoTeledermaCases({
    super.key,
    required this.repository,
    required this.onLoadUrl,
    this.theme,
    this.onCameraPermission,
  });

  @override
  State<MediquoTeledermaCases> createState() => _MediquoTeledermaCasesState();
}

class _MediquoTeledermaCasesState extends State<MediquoTeledermaCases> {
  late Future<List<TeledermaCase>> _cases;
  Timer? _mediaPoll;
  int _mediaPolls = 0;
  bool _starting = false;
  bool _consentAccepted = false;
  MqTheme? _brand;

  MqTheme get _theme => widget.theme ?? _brand ?? const MqTheme();
  bool get _branded => widget.theme != null || _brand != null;

  @override
  void initState() {
    super.initState();
    _cases = _load();
    if (widget.theme == null) _loadBrand();
  }

  @override
  void dispose() {
    _mediaPoll?.cancel();
    super.dispose();
  }

  Future<List<TeledermaCase>> _load() async {
    final cases = await widget.repository.listCases();
    _mediaPoll?.cancel();
    if (cases.any((c) => c.mediaPending) && _mediaPolls++ < 20) {
      _mediaPoll = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _cases = _load();
        });
      });
    }
    return cases;
  }

  Future<void> _loadBrand() async {
    final color = await widget.repository.primaryColor().catchError((_) => null);
    if (mounted) setState(() => _brand = color == null ? const MqTheme() : MqTheme.fromBrand(color));
  }

  void _reload() {
    _mediaPolls = 0;
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
        final consent = await widget.repository.legalConsent();
        _consentAccepted = consent.status == LegalConsentStatus.accepted ||
            await _push<bool>(TermsScreen(
                  repository: widget.repository,
                  consent: consent,
                  onLoadUrl: widget.onLoadUrl,
                )) ==
                true;
        if (!_consentAccepted) return;
      }
      final created = await widget.repository.createCase();
      final sent = await _push<bool>(
        LegitIframeScreen(
          repository: widget.repository,
          caseId: created.id,
          onCameraPermission: widget.onCameraPermission,
        ),
        fullscreenDialog: true,
      );
      if (sent != true) widget.repository.discardCase(created.id).ignore();
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

  Future<void> _openCase(TeledermaCase c) async {
    await _push(CaseDetailScreen(repository: widget.repository, caseId: c.id, onLoadUrl: widget.onLoadUrl));
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
        final cases = [
          for (final c in snapshot.data ?? const <TeledermaCase>[])
            if (c.status != CaseStatus.draft) c
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dermatología'),
            actions: [
              if (error == null)
                IconButton(
                  icon: const MqIcon(MqIcons.infoCircle),
                  tooltip: 'Más información',
                  onPressed: () => _push(ServiceInfoScreen(repository: widget.repository, onLoadUrl: widget.onLoadUrl)),
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
        padding: const EdgeInsets.all(24),
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
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
                child: _CaseCard(teledermaCase: c, onTap: () => _openCase(c)),
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
          child: IntrinsicHeight(
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
                        Text(capitalize(formatDateTime(date)), style: secondaryText(context, fontSize: MqFontSize.xs)),
                      ],
                      const SizedBox(height: 8),
                      MqBadge(label: c.status.label),
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
