import 'dart:async';

import 'package:flutter/material.dart';

import '../data/telederma_repository.dart';
import '../models.dart';
import '../../design_system/design_system.dart';
import '../widgets/common.dart';

class CaseDetailScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final String caseId;
  final void Function(String url) onLoadUrl;

  const CaseDetailScreen({super.key, required this.repository, required this.caseId, required this.onLoadUrl});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<TeledermaCase> _case;
  Timer? _mediaPoll;
  int _mediaPolls = 0;

  @override
  void initState() {
    super.initState();
    _case = _load();
  }

  @override
  void dispose() {
    _mediaPoll?.cancel();
    super.dispose();
  }

  Future<TeledermaCase> _load() async {
    final c = await widget.repository.getCase(widget.caseId);
    _mediaPoll?.cancel();
    if (c.mediaPending && _mediaPolls++ < 20) {
      _mediaPoll = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _case = _load();
        });
      });
    }
    return c;
  }

  void _reload() {
    _mediaPolls = 0;
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
              child: _CaseBody(teledermaCase: data, onLoadUrl: widget.onLoadUrl),
            ),
          _ => const _CaseSkeleton(),
        },
      ),
    );
  }
}

class _CaseBody extends StatelessWidget {
  final TeledermaCase teledermaCase;
  final void Function(String url) onLoadUrl;

  const _CaseBody({required this.teledermaCase, required this.onLoadUrl});

  @override
  Widget build(BuildContext context) {
    final c = teledermaCase;
    final outcome = c.outcome;
    final sentAt = c.submittedAt ?? c.createdAt;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (outcome == null)
          const MqBanner(
            icon: MqIcons.infoCircle,
            title: 'Un dermatólogo revisará tu consulta',
            description: 'Te avisaremos por email cuando tengas el informe.',
          )
        else ...[
          MqBanner(
            icon: MqIcons.checkCircle,
            tone: MqTone.success,
            title: 'Tu informe está listo',
            description: [
              outcome.dermatologist,
              if (outcome.licenseNumber != null) 'N.º de colegiación ${outcome.licenseNumber}',
            ].join('\n'),
          ),
          if (outcome.reportUrl != null || outcome.prescriptionUrl != null) ...[
            const SizedBox(height: 24),
            const Text('Documentos', style: headingStyle),
            const SizedBox(height: 8),
            if (outcome.reportUrl case final url?)
              _DocumentRow(
                icon: MqIcons.file,
                title: 'Informe del dermatólogo',
                subtitle: 'PDF',
                onTap: () => onLoadUrl(url),
              ),
            if (outcome.prescriptionUrl case final url?)
              _DocumentRow(
                icon: MqIcons.receipt,
                title: 'Receta electrónica',
                subtitle: 'Muéstrala con tu DNI',
                onTap: () => onLoadUrl(url),
              ),
          ],
          const Divider(height: 48),
        ],
        if (outcome == null) const SizedBox(height: 24),
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

class _DocumentRow extends StatelessWidget {
  final MqIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocumentRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                  Text(subtitle, style: secondaryText(context)),
                ],
              ),
            ),
            MqIcon(MqIcons.chevronRight, color: MqTheme.of(context).textSecondary),
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
