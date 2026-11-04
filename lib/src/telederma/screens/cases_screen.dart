import 'package:flutter/material.dart';

import '../../api_client/api_chat_client.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../../design_system/design_system.dart';
import '../widgets/common.dart';
import 'case_detail_screen.dart';
import 'legit_iframe_screen.dart';

class MediquoTeledermaCases extends StatefulWidget {
  final TeledermaRepository repository;

  final MqTheme? theme;
  final Future<void> Function()? onCameraPermission;

  const MediquoTeledermaCases({
    super.key,
    required this.repository,
    this.theme,
    this.onCameraPermission,
  });

  @override
  State<MediquoTeledermaCases> createState() => _MediquoTeledermaCasesState();
}

class _MediquoTeledermaCasesState extends State<MediquoTeledermaCases> {
  late Future<List<TeledermaCase>> _cases;
  bool _creating = false;
  MqTheme? _brand;

  MqTheme get _theme => widget.theme ?? _brand ?? const MqTheme();
  bool get _branded => widget.theme != null || _brand != null;

  @override
  void initState() {
    super.initState();
    _cases = widget.repository.listCases();
    if (widget.theme == null) _loadBrand();
  }

  Future<void> _loadBrand() async {
    final color = await widget.repository.primaryColor().catchError((_) => null);
    if (mounted) setState(() => _brand = color == null ? const MqTheme() : MqTheme.fromBrand(color));
  }

  void _reload() {
    setState(() {
      _cases = widget.repository.listCases();
    });
  }

  Future<void> _startNewCase(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewCaseSheet(),
    );
    if (reason == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final created = await widget.repository.createCase(consultationReason: reason);
      if (!context.mounted) return;
      final report = await openLegitIframe(
        context,
        repository: widget.repository,
        caseId: created.id,
        theme: _theme,
        onCameraPermission: widget.onCameraPermission,
      );
      if (!mounted) return;
      if (report == null) {
        widget.repository.discardCase(created.id).ignore();
        _reload();
      } else {
        await _openCase(created);
      }
    } catch (e) {
      if (!context.mounted) return;
      final forbidden = e is ApiChatException && e.statusCode == 403;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(forbidden
            ? 'El servicio de dermatología no está disponible para tu cuenta.'
            : 'No se ha podido crear el caso. Inténtalo de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openCase(TeledermaCase c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _theme.wrap(CaseDetailScreen(repository: widget.repository, caseId: c.id)),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _theme.wrap(FutureBuilder<List<TeledermaCase>>(
      future: _cases,
      builder: (context, snapshot) {
        final error = snapshot.error;
        final forbidden = error is ApiChatException && error.statusCode == 403;
        final loading = snapshot.connectionState != ConnectionState.done || !_branded;
        final cases = [
          for (final c in snapshot.data ?? const <TeledermaCase>[])
            if (c.status != CaseStatus.draft) c
        ];
        return Scaffold(
          appBar: AppBar(title: const Text('Dermatología')),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
          floatingActionButton: error != null || loading || cases.isEmpty
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(MqRadius.md)),
                    boxShadow: [BoxShadow(color: Color(0x1F0A0A23), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: MqButton(
                    label: 'Nuevo caso',
                    icon: Icons.add,
                    onPressed: _creating ? null : () => _startNewCase(context),
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
      return const _EmptyState(
        icon: Icons.lock_outline,
        title: 'Servicio no disponible',
        description: 'El servicio de dermatología no está incluido en tu cuenta.',
      );
    }
    if (error) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No se han podido cargar tus casos',
        description: 'Revisa tu conexión e inténtalo de nuevo.',
        action: MqButton(label: 'Reintentar', variant: MqButtonVariant.outline, onPressed: _reload),
      );
    }
    if (!loading && cases.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: () async => _reload(),
        child: _EmptyState(
          icon: Icons.photo_camera_outlined,
          title: 'Aún no tienes casos',
          description: 'Haz fotos de la zona de la piel que te preocupa y un dermatólogo te responderá '
              'por el chat en menos de 48 h.',
          action: MqButton(
            label: 'Nuevo caso',
            icon: Icons.add,
            onPressed: _creating ? null : () => _startNewCase(context),
          ),
        ),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Tus casos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Fotos de tu piel revisadas por dermatólogos', style: secondaryText(context)),
          const SizedBox(height: 16),
          if (loading)
            const _Skeleton()
          else
            MqCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final (i, c) in cases.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _CaseRow(teledermaCase: c, onTap: () => _openCase(c)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  final TeledermaCase teledermaCase;
  final VoidCallback onTap;

  const _CaseRow({required this.teledermaCase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = teledermaCase;
    final t = MqTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CaseImageView(url: c.thumbnailUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  if (c.createdAt case final createdAt?)
                    Text(formatDate(createdAt), style: secondaryText(context, fontSize: 13)),
                  const SizedBox(height: 8),
                  MqBadge(label: c.status.label),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _NewCaseSheet extends StatefulWidget {
  const _NewCaseSheet();

  @override
  State<_NewCaseSheet> createState() => _NewCaseSheetState();
}

class _NewCaseSheetState extends State<_NewCaseSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nuevo caso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Después harás las fotos de la zona que quieras enseñar.', style: secondaryText(context)),
          const SizedBox(height: 16),
          MqTextarea(
            controller: _reason,
            label: 'Motivo de consulta (opcional)',
            placeholder: 'Cuéntanos qué te preocupa',
            maxLength: 2000,
          ),
          const SizedBox(height: 16),
          MqButton(label: 'Empezar', expand: true, onPressed: () => Navigator.of(context).pop(_reason.text)),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: MqSkeleton(height: 76, radius: MqRadius.xl),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const _EmptyState({required this.icon, required this.title, required this.description, this.action});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: t.brandSubtle, shape: BoxShape.circle),
                  child: Icon(icon, size: 28, color: t.textBrand),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(description, textAlign: TextAlign.center, style: secondaryText(context)),
                ),
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
