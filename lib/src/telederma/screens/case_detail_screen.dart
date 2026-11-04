import 'package:flutter/material.dart';

import '../data/telederma_repository.dart';
import '../models.dart';
import '../../design_system/design_system.dart';
import '../widgets/common.dart';
import '../widgets/report_view.dart';

class CaseDetailScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final String caseId;

  const CaseDetailScreen({super.key, required this.repository, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<TeledermaCase> _case;

  @override
  void initState() {
    super.initState();
    _case = widget.repository.getCase(widget.caseId);
  }

  void _reload() {
    setState(() {
      _case = widget.repository.getCase(widget.caseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del caso')),
      body: FutureBuilder<TeledermaCase>(
        future: _case,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => _LoadError(onRetry: _reload),
          AsyncSnapshot(hasData: true, :final data!) => RefreshIndicator.adaptive(
              onRefresh: () async => _reload(),
              child: _CaseBody(teledermaCase: data),
            ),
          _ => const _CaseSkeleton(),
        },
      ),
    );
  }
}

class _CaseBody extends StatelessWidget {
  final TeledermaCase teledermaCase;

  const _CaseBody({required this.teledermaCase});

  @override
  Widget build(BuildContext context) {
    final c = teledermaCase;
    final createdAt = c.createdAt;
    final reason = c.consultationReason;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MqBadge(label: c.status.label),
            if (createdAt != null) Text(formatDate(createdAt), style: secondaryText(context, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        if (c.status == CaseStatus.submitted)
          const _Notice(
            icon: Icons.schedule,
            text: 'Un dermatólogo revisará tu caso y te responderá por el chat en menos de 48 h.',
          ),
        if (reason != null) MqCard(title: 'Motivo de consulta', child: Text(reason)),
        for (final report in c.reports) _ZoneSection(report: report),
      ],
    );
  }
}

class _CaseSkeleton extends StatelessWidget {
  const _CaseSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        MqSkeleton(width: 220, height: 24),
        SizedBox(height: 12),
        Row(
          children: [
            MqSkeleton(width: 90, height: 22, radius: MqRadius.full),
            SizedBox(width: 8),
            MqSkeleton(width: 80, height: 14),
          ],
        ),
        SizedBox(height: 16),
        MqSkeleton(height: 64, radius: MqRadius.xl),
        SizedBox(height: 12),
        MqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MqSkeleton(width: 120, height: 18),
              SizedBox(height: 16),
              Row(
                children: [
                  MqSkeleton(width: 120, height: 120, radius: MqRadius.xl),
                  SizedBox(width: 8),
                  MqSkeleton(width: 120, height: 120, radius: MqRadius.xl),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoneSection extends StatelessWidget {
  final CaseReport report;

  const _ZoneSection({required this.report});

  @override
  Widget build(BuildContext context) {
    final analysis = report.analysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MqCard(
          title: 'Fotos',
          child: SizedBox(
            height: 148,
            child: report.photos.isEmpty
                ? const Align(alignment: Alignment.centerLeft, child: CaseImageView(size: 120, radius: MqRadius.xl))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _Photo(photo: report.photos[i]),
                  ),
          ),
        ),
        if (analysis != null) AnalysisView(analysis: analysis),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  final CasePhoto photo;

  const _Photo({required this.photo});

  @override
  Widget build(BuildContext context) {
    final score = photo.qualityScore;
    final ok = score != null && score >= CasePhoto.qualityThreshold;
    return Column(
      children: [
        CaseImageView(url: photo.url, size: 120, radius: MqRadius.xl),
        const SizedBox(height: 6),
        if (score != null)
          MqBadge(
            label: 'Calidad $score/100',
            icon: ok ? Icons.check_circle : Icons.error,
            tone: ok ? MqBadgeTone.neutral : MqBadgeTone.error,
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = MqTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(MqRadius.xl)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
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
          MqButton(label: 'Reintentar', variant: MqButtonVariant.ghost, onPressed: onRetry),
        ],
      ),
    );
  }
}
