import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../../design_system/design_system.dart';
import 'common.dart';

class AnalysisView extends StatelessWidget {
  final Analysis analysis;

  const AnalysisView({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final risk = analysis.risk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (analysis.severity.isNotEmpty) _SeverityCard(severity: analysis.severity),
        if (risk != null) _RiskCard(risk: risk),
        if (analysis.hypotheses.isNotEmpty) _HypothesesCard(hypotheses: analysis.hypotheses),
        const _RegulatoryLabel(),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  final Risk risk;

  const _RiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    return MqCard(
      title: 'Valoración de riesgo',
      child: Row(
        children: [
          _MalignancyGauge(risk: risk),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Metric(label: 'Derivación urgente', value: formatPercent(risk.urgentReferral)),
                _Metric(label: 'Derivación prioritaria', value: formatPercent(risk.highPriorityReferral)),
                _Metric(label: 'Lesión pigmentada', value: formatPercent(risk.pigmentedLesion)),
                _Metric(label: 'Presencia de patología', value: formatPercent(risk.hasCondition)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: secondaryText(context, fontSize: 12))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MalignancyGauge extends StatelessWidget {
  final Risk risk;

  const _MalignancyGauge({required this.risk});

  @override
  Widget build(BuildContext context) {
    final theme = MqTheme.of(context);
    final value = risk.malignancy;
    final color = risk.isMalignancyAlert ? theme.error : theme.brand;
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          SizedBox(
            width: 110,
            height: 62,
            child: CustomPaint(
              painter: _GaugePainter(value: value / 100, color: color, track: theme.borderDefault),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  formatPercent(value),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Malignidad', style: TextStyle(fontSize: 12, color: theme.textSecondary)),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _GaugePainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, (size.width - 16));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, stroke..color = track);
    canvas.drawArc(rect, pi, pi * value.clamp(0.02, 1), false, stroke..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color || old.track != track;
}

class _HypothesesCard extends StatelessWidget {
  final List<Hypothesis> hypotheses;

  const _HypothesesCard({required this.hypotheses});

  @override
  Widget build(BuildContext context) {
    final theme = MqTheme.of(context);
    return MqCard(
      title: 'Hipótesis diagnósticas (top 5)',
      child: Column(
        children: [
          for (final (i, h) in hypotheses.take(5).indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${i + 1}. ', style: TextStyle(color: theme.textSecondary)),
                      Expanded(
                        child: Text(h.name, style: TextStyle(fontWeight: i == 0 ? FontWeight.w500 : FontWeight.w400)),
                      ),
                      if (h.icd11.isNotEmpty)
                        Text('ICD-11 ${h.icd11}', style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          formatPercent(h.probability),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: theme.borderDefault,
                      borderRadius: BorderRadius.circular(MqRadius.full),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (h.probability / 100).clamp(0, 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i == 0 ? theme.brand : MqColors.grey300,
                          borderRadius: BorderRadius.circular(MqRadius.full),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SeverityCard extends StatelessWidget {
  final List<Severity> severity;

  const _SeverityCard({required this.severity});

  @override
  Widget build(BuildContext context) {
    return MqCard(
      title: 'Gravedad',
      child: Column(
        children: [
          for (final s in severity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(s.name, style: secondaryText(context))),
                  Text(s.score.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  if (s.severity.isNotEmpty) ...[const SizedBox(width: 8), MqBadge(label: s.severity)],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RegulatoryLabel extends StatelessWidget {
  const _RegulatoryLabel();

  static const _ifuUrl = 'https://ifu-eu-mdr.legit.health';

  @override
  Widget build(BuildContext context) {
    final theme = MqTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MqRadius.xl),
        border: Border.all(color: theme.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(4)),
            child: const Text('CE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Legit.Health Plus · producto sanitario\nEtiqueta regulatoria e instrucciones de uso: $_ifuUrl\n(placeholder: sustituir por la etiqueta oficial)',
              style: TextStyle(fontSize: 11, color: theme.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
