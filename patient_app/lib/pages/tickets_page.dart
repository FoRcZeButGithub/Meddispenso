import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../model.dart';
import '../services/api.dart';

/// เปิดเป็น true เพื่อให้ปุ่ม "Create ticket" สร้าง PIN/QR แบบ mock โดยไม่เรียก backend
const bool kMockTicketMode = true;

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});
  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  late Future<List<Prescription>> _future;
  @override
  void initState() {
    super.initState();
    _future = fetchPrescriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Qr code/Pin')),
      body: FutureBuilder<List<Prescription>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No active prescriptions'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (_, i) => _PrescriptionTile(p: items[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _PrescriptionTile extends StatefulWidget {
  final Prescription p;
  const _PrescriptionTile({required this.p});
  @override
  State<_PrescriptionTile> createState() => _PrescriptionTileState();
}

class _PrescriptionTileState extends State<_PrescriptionTile> {
  bool _busy = false;
  String? _error;
  String? _pin;
  String? _qr;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kMockTicketMode) {
        // สร้าง PIN 6 หลัก และ QR payload แบบจำลอง
        await Future.delayed(const Duration(milliseconds: 600));
        final rnd = Random();
        final pin = List.generate(6, (_) => rnd.nextInt(10)).join();
        final fakeId =
            'tkt_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
        _pin = pin;
        _qr = 'ticket:$fakeId|otp:$pin';
      } else {
        final t = await createTicket(widget.p.id);
        _pin = t.otp;
        _qr = t.qrText;
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medName = widget.p.medicine.name;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('unit : ${widget.p.doseUnits}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.subtext)),
          const SizedBox(height: 4),
          Text('Medicine : $medName',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 12),
          if (_pin == null) ...[
            FilledButton(
              onPressed: _busy ? null : _create,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Create ticket'),
            )
          ] else ...[
            const Text('PIN',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 8),
            PinDisplay(pin: _pin!),
            const SizedBox(height: 12),
            if (_qr != null) Center(child: QrImageView(data: _qr!, size: 140)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RoundAction(
                    icon: Icons.backspace_outlined,
                    fill: AppColors.dangerSoft,
                    iconColor: AppColors.danger,
                    onPressed: () => setState(() {
                          _pin = null;
                          _qr = null;
                        })),
                const SizedBox(width: 12),
                const RoundAction(
                    icon: Icons.check_circle_outline,
                    fill: AppColors.successSoft,
                    iconColor: AppColors.success,
                    onPressed: null),
              ],
            )
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
