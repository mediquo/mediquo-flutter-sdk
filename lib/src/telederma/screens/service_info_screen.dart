import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../widgets/common.dart';

class ServiceInfoScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final void Function(String url) onLoadUrl;

  const ServiceInfoScreen({super.key, required this.repository, required this.onLoadUrl});

  @override
  State<ServiceInfoScreen> createState() => _ServiceInfoScreenState();
}

class _ServiceInfoScreenState extends State<ServiceInfoScreen> {
  late final Future<LegalConsent> _consent = widget.repository.legalConsent();
  final _privacy = TapGestureRecognizer();
  final _terms = TapGestureRecognizer();

  @override
  void dispose() {
    _privacy.dispose();
    _terms.dispose();
    super.dispose();
  }

  static const _faqs = [
    (
      '¿Cuándo puedo usar este servicio?',
      'Cuando tengas una duda sobre tu piel que no sea urgente: manchas, lunares, granos, picores o erupciones. '
          'Puedes enviar tu consulta a cualquier hora.',
    ),
    (
      '¿Tiene algún coste?',
      'No. El servicio está incluido en tu seguro y no pagas nada por cada consulta.',
    ),
    (
      '¿Qué respuesta voy a recibir?',
      'Un informe del dermatólogo con su valoración y los pasos a seguir. Si hace falta, también una receta electrónica.',
    ),
    (
      '¿Quién ve mis fotos?',
      'Solo el dermatólogo que valora tu caso. No se comparten con nadie más.',
    ),
    (
      '¿Puedo resolver dudas después?',
      'Puedes hacer una nueva consulta cuando quieras. Si el dermatólogo necesita verte en persona, te lo dirá en el informe.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Más información')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Qué incluye', style: headingStyle),
          const SizedBox(height: 16),
          const _Benefit(
            icon: MqIcons.clock,
            title: 'Sin cita previa',
            description: 'Cuando lo necesites y desde donde estés.',
          ),
          const _Benefit(
            icon: MqIcons.receipt,
            title: 'Receta si hace falta',
            description: 'Si tu caso lo requiere, el dermatólogo te la prescribe en el mismo informe.',
          ),
          const _Benefit(
            icon: MqIcons.heartRate,
            title: 'Respuesta en menos de 48 h',
            description: 'Un dermatólogo colegiado valora tu caso y te dice qué hacer.',
          ),
          const SizedBox(height: 16),
          const Text('Cómo funciona', style: headingStyle),
          for (final (i, step) in const [
            'Responde unas preguntas sobre tu piel',
            'Indica la zona afectada',
            'Sube de 1 a 3 fotos',
            'Recibe la valoración en menos de 48 h',
          ].indexed) ...[
            const SizedBox(height: 20),
            NumberedStep(number: i + 1, text: step),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              MqIcon(MqIcons.infoCircle, size: 16, color: t.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No es para urgencias. Si sangra, crece rápido o tienes fiebre, llama al 112.',
                  style: secondaryText(context, fontSize: MqFontSize.xs),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const MqBanner(
            icon: MqIcons.camera,
            title: 'Antes de empezar',
            description: 'Ten a mano de 1 a 3 fotos nítidas de la zona, con buena luz natural.',
          ),
          const SizedBox(height: 32),
          const Text('Preguntas frecuentes', style: headingStyle),
          const SizedBox(height: 4),
          for (final (question, answer) in _faqs) _Faq(question: question, answer: answer),
          const SizedBox(height: 32),
          FutureBuilder(
            future: _consent,
            builder: (context, snapshot) {
              final consent = snapshot.data;
              final link = TextStyle(decoration: TextDecoration.underline, color: t.textSecondary);
              _privacy.onTap = consent == null ? null : () => widget.onLoadUrl(consent.privacyUrl);
              _terms.onTap = consent == null ? null : () => widget.onLoadUrl(consent.termsUrl);
              return Text.rich(
                TextSpan(
                  style: secondaryText(context, fontSize: MqFontSize.xs),
                  children: [
                    const TextSpan(
                      text: 'Servicio prestado por mediQuo. Tus fotos solo las ve el dermatólogo que valora tu caso. ',
                    ),
                    if (consent != null) ...[
                      TextSpan(text: 'Privacidad', style: link, recognizer: _privacy),
                      const TextSpan(text: ' · '),
                      TextSpan(text: 'Términos', style: link, recognizer: _terms),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final MqIconData icon;
  final String title;
  final String description;

  const _Benefit({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MqIconContainer(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: MqFontSize.sm, fontWeight: FontWeight.w500, height: 1.35)),
                const SizedBox(height: 4),
                Text(description, style: secondaryText(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatefulWidget {
  final String question;
  final String answer;

  const _Faq({required this.question, required this.answer});

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(MqRadius.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.question, style: const TextStyle(fontSize: MqFontSize.base, height: 1.5)),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const MqIcon(MqIcons.chevronRight),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(widget.answer, style: secondaryText(context)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
