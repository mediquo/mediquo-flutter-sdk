import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../widgets/common.dart';

class ConsultationSentScreen extends StatelessWidget {
  const ConsultationSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const ScreenHero(
                  icon: MqIcons.checkCircle,
                  tone: MqTone.success,
                  centered: true,
                  title: 'Consulta enviada',
                  description: 'Te enviaremos el informe del dermatólogo en menos de 48 horas laborables.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MqTheme.of(context).surfaceRaised,
                    borderRadius: BorderRadius.circular(MqRadius.lg),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Y ahora qué?', style: TextStyle(fontSize: MqFontSize.sm, fontWeight: FontWeight.w500)),
                      SizedBox(height: 12),
                      NumberedStep(number: 1, text: 'Un dermatólogo revisa tus fotos y tus respuestas.'),
                      SizedBox(height: 12),
                      NumberedStep(number: 2, text: 'Te avisamos por email cuando tengas el informe.'),
                      SizedBox(height: 12),
                      NumberedStep(number: 3, text: 'También lo verás en «Dermatología», con la receta si hace falta.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          MqButton(label: 'Ver mis consultas', expand: true, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
