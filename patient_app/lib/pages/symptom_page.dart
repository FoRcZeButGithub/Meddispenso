import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class SymptomPage extends StatefulWidget {
  const SymptomPage({super.key});
  @override
  State<SymptomPage> createState() => _SymptomPageState();
}

class _SymptomPageState extends State<SymptomPage> {
  final _symptom = TextEditingController();
  final _allergy = TextEditingController();
  String? _msg; bool _busy = false;

  Future<void> _submit() async {
    setState(() { _busy = true; _msg = null; });
    try {
      // เรียก use case จริงของคุณ (ผมคงชื่อฟังก์ชันไว้)
      final latest = await getLatestTicket();
      if (latest?.jobId == null) { _msg = 'No ticket found.'; }
      else {
        final ok = await reportSymptoms(
          jobId: latest!.jobId!,
          symptoms: _symptom.text.trim().isEmpty ? null : _symptom.text.trim(),
          allergies: _allergy.text.trim().isEmpty ? null : _allergy.text.trim(),
        );
        _msg = ok ? 'Sent!' : 'Failed to send.';
      }
    } catch (e) { _msg = '$e'; }
    if (mounted) setState(() { _busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send symtom')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('symtom', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 8),
              TextField(controller: _symptom, maxLines: 5),
              const SizedBox(height: 24),
              const Text('Drug allergy (Optional)', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 8),
              TextField(controller: _allergy, maxLines: 4),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                child: _busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send symtom'),
              ),
              if (_msg != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_msg!, style: const TextStyle(color: AppColors.subtext))),
            ],
          ),
        ),
      ),
    );
  }
}
