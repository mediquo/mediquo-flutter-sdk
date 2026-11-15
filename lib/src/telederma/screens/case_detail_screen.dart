import 'dart:io';

import 'package:flutter/material.dart';

import '../../api_client/api_chat_client.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../../design_system/design_system.dart';
import '../widgets/common.dart';

class CaseDetailScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final String caseId;
  final Future<void> Function(String filePath) onOpenDocument;

  const CaseDetailScreen({super.key, required this.repository, required this.caseId, required this.onOpenDocument});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<TeledermaCase> _case;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _case = _load();
    _lifecycle = AppLifecycleListener(onResume: _reload);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<TeledermaCase> _load() => widget.repository.getCase(widget.caseId);

  void _reload() {
    setState(() {
      _case = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de dermatología')),
      body: FutureBuilder<TeledermaCase>(
        future: _case,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => _LoadError(onRetry: _reload),
          AsyncSnapshot(hasData: true, :final data!) => RefreshIndicator.adaptive(
              onRefresh: () async => _reload(),
              child: _CaseBody(
                teledermaCase: data,
                repository: widget.repository,
                onOpenDocument: widget.onOpenDocument,
              ),
            ),
          _ => const _CaseSkeleton(),
        },
      ),
    );
  }
}

class _CaseBody extends StatelessWidget {
  final TeledermaCase teledermaCase;
  final TeledermaRepository repository;
  final Future<void> Function(String filePath) onOpenDocument;

  const _CaseBody({required this.teledermaCase, required this.repository, required this.onOpenDocument});

  @override
  Widget build(BuildContext context) {
    final c = teledermaCase;
    final finished = c.status == CaseStatus.finished;
    final finishedAt = c.finishedAt;
    final sentAt = c.submittedAt ?? c.createdAt;
    final notes = [
      if (finishedAt != null) 'Finalizada el ${formatDateTime(finishedAt)}',
      if (c.documents.isEmpty) 'El dermatólogo no ha adjuntado documentos.',
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!finished)
          const MqBanner(
            icon: MqIcons.infoCircle,
            title: 'Un dermatólogo revisará tu consulta',
            description: 'Te avisaremos por email cuando tengas el informe.',
          )
        else
          MqBanner(
            icon: MqIcons.checkCircle,
            tone: MqTone.success,
            title: c.documents.any((d) => d.type == CaseDocument.report)
                ? 'Tu informe está listo'
                : 'Tu consulta ha finalizado',
            description: notes.isEmpty ? null : notes.join('\n'),
          ),
        if (finished && c.documents.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Documentos', style: headingStyle),
          const SizedBox(height: 8),
          for (final d in c.documents) _DocumentRow(document: d, repository: repository, onOpen: onOpenDocument),
          const Divider(height: 48),
        ] else
          const SizedBox(height: 24),
        const Text('Resumen de tu consulta', style: headingStyle),
        if (sentAt != null) ...[
          const SizedBox(height: 12),
          Text('Enviada el ${formatDateTime(sentAt)}', style: secondaryText(context, fontSize: MqFontSize.xs)),
        ],
        for (final report in c.reports) _ReportSummary(report: report),
      ],
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final CaseReport report;

  const _ReportSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    final rows = [CaseAnswer('Zona', report.bodySite), ...report.answers];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 112, child: Text(row.question, style: secondaryText(context))),
                const SizedBox(width: 12),
                Expanded(child: Text(row.answer, style: const TextStyle(fontSize: MqFontSize.sm, height: 1.35))),
              ],
            ),
          ),
        if (report.photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 192,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: report.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CaseImageView(url: report.photos[i].url, size: 192, radius: MqRadius.md),
            ),
          ),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatefulWidget {
  final CaseDocument document;
  final TeledermaRepository repository;
  final Future<void> Function(String filePath) onOpen;

  const _DocumentRow({required this.document, required this.repository, required this.onOpen});

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _opening = false;
  File? _file;

  @override
  void dispose() {
    _deleteFile();
    super.dispose();
  }

  // Medical PDFs must not outlive the detail screen. Viewers like Android's open the file after the callback returns.
  void _deleteFile() {
    _file?.delete().catchError((_) => _file!);
    _file = null;
  }

  Future<void> _open() async {
    final d = widget.document;
    setState(() => _opening = true);
    _deleteFile();
    final File file;
    try {
      final bytes = await widget.repository.downloadDocument(d);
      final name = '${d.type}-${d.id}'.replaceAll(RegExp(r'[^\w-]'), '_');
      file = await File('${Directory.systemTemp.path}/$name.pdf').writeAsBytes(bytes);
    } catch (e) {
      if (!mounted) return;
      final notReady = e is ApiChatException && e.statusCode == 404;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(notReady
            ? 'El documento todavía no está disponible. Inténtalo más tarde.'
            : 'No se ha podido abrir el documento. Inténtalo de nuevo.'),
      ));
      return;
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    _file = file;
    await widget.onOpen(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final available = widget.document.downloadUrl != null;
    final (icon, title, subtitle) = switch (widget.document.type) {
      CaseDocument.report => (MqIcons.file, 'Informe del dermatólogo', 'PDF'),
      CaseDocument.prescription => (MqIcons.receipt, 'Receta electrónica', 'Muéstrala con tu DNI'),
      CaseDocument.diagnosticTestPrescription => (MqIcons.heartRate, 'Pruebas diagnósticas', 'Volante para pedirlas'),
      _ => (MqIcons.file, 'Documento', 'PDF'),
    };
    return InkWell(
      onTap: available && !_opening ? _open : null,
      borderRadius: BorderRadius.circular(MqRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            MqIconContainer(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: MqFontSize.base, height: 1.5)),
                  Text(available ? subtitle : 'Todavía no disponible', style: secondaryText(context)),
                ],
              ),
            ),
            if (_opening)
              const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
            else if (available)
              MqIcon(MqIcons.chevronRight, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CaseSkeleton extends StatelessWidget {
  const _CaseSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        MqSkeleton(height: 76, radius: MqRadius.lg),
        SizedBox(height: 24),
        MqSkeleton(width: 220, height: 24),
        SizedBox(height: 12),
        MqSkeleton(width: 160, height: 14),
        SizedBox(height: 16),
        MqSkeleton(height: 120),
        SizedBox(height: 16),
        MqSkeleton(width: 192, height: 192, radius: MqRadius.lg),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se ha podido cargar el caso.'),
          const SizedBox(height: 8),
          MqButton(label: 'Reintentar', variant: MqButtonVariant.secondary, onPressed: onRetry),
        ],
      ),
    );
  }
}
