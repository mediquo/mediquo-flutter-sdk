import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../data/telederma_repository.dart';
import '../models.dart';
import '../widgets/common.dart';

class TermsScreen extends StatefulWidget {
  final TeledermaRepository repository;
  final LegalConsent consent;
  final void Function(String url) onLoadUrl;

  const TermsScreen({super.key, required this.repository, required this.consent, required this.onLoadUrl});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final _terms = TapGestureRecognizer()..onTap = () => widget.onLoadUrl(widget.consent.termsUrl);
  late final _privacy = TapGestureRecognizer()..onTap = () => widget.onLoadUrl(widget.consent.privacyUrl);
  bool _accepted = false;
  bool _saving = false;

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await widget.repository.acceptLegalConsent(widget.consent);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hemos podido guardar tu aceptación. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final link = TextStyle(color: t.textBrand, fontWeight: FontWeight.w500);
    final outdated = widget.consent.status == LegalConsentStatus.outdated;
    return Scaffold(
      appBar: AppBar(title: const Text('Dermatología')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outdated ? 'Hemos actualizado los términos y condiciones' : 'Antes de continuar', style: titleStyle),
              const SizedBox(height: 32),
              Text(
                'Este servicio lo presta mediQuo. Para hacer tu consulta, acepta los términos y condiciones.',
                style: secondaryText(context, fontSize: MqFontSize.base),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: Checkbox(
                      value: _accepted,
                      onChanged: _saving ? null : (v) => setState(() => _accepted = v ?? false),
                      side: BorderSide(color: t.textSecondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MqRadius.sm)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: MqFontSize.sm, height: 1.35),
                        children: [
                          const TextSpan(text: 'He leído y acepto los '),
                          TextSpan(text: 'términos y condiciones', style: link, recognizer: _terms),
                          const TextSpan(text: ' y la '),
                          TextSpan(text: 'política de privacidad', style: link, recognizer: _privacy),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          MqButton(label: 'Continuar', expand: true, onPressed: _accepted && !_saving ? _continue : null),
        ],
      ),
    );
  }
}
