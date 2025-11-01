import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'api.dart';
import 'config.dart' as cfg;
import 'models.dart';

void main() => runApp(const KioskApp());

final _qrRe  = RegExp(r'^ticket:([0-9a-fA-F-]{36})\|otp:(\d{6})$');
final _uriRe = RegExp(r'^meddisp://v1/redeem\?tid=([0-9a-fA-F-]{36})&otp=(\d{6})$');

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7CC5FF)),
      useMaterial3: true,
      textTheme: GoogleFonts.promptTextTheme(),
    );
    return MaterialApp(
      title: 'Meddisp Kiosk',
      theme: theme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF2F8FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE6F3FF),
          foregroundColor: Color(0xFF0F3D63),
          elevation: 0,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum Mode { scan, pin }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Mode mode = Mode.scan;

  // PIN keypad & HID (สแกนเนอร์ USB) state
  String pin = "";
  final _hidFocus = FocusNode();

  // กล้องสแกน QR (เปิดเมื่อพร้อม)
  bool useCamera = false;
  final _scannerCtrl = MobileScannerController();
  bool _scanLock = false; // กันอ่านซ้ำถี่เกิน

  // app state
  bool busy = false;
  String? message;
  RedeemResp? last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hidFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _hidFocus.dispose();
    super.dispose();
  }

  // ================= Redeem helpers =================
  Future<void> _handlePayload(String payload) async {
    String? tid, otp;
    final m1 = _qrRe.firstMatch(payload);
    if (m1 != null) { tid = m1.group(1); otp = m1.group(2); }
    if (tid == null || otp == null) {
      final m2 = _uriRe.firstMatch(payload);
      if (m2 != null) { tid = m2.group(1); otp = m2.group(2); }
    }

    if (tid != null && otp != null) {
      await _redeemTicket(tid, otp);
      return;
    }

    if (RegExp(r'^\d{6}$').hasMatch(payload)) {
      await _redeemPin(payload);
      return;
    }

    setState(() => message = 'รูปแบบ QR/PIN ไม่ถูกต้อง');
  }

  Future<void> _redeemTicket(String ticketId, String otp) async {
    if (busy) return;
    setState(() { busy = true; message = null; last = null; });
    try {
      final r = await api.redeem(
        deviceId: cfg.deviceId,
        deviceKeyPlain: cfg.deviceKey,
        ticketId: ticketId,
        otp: otp,
      );
      await _finalizeAfterRedeem(r);
    } catch (e) {
      setState(() => message = 'เครือข่ายผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _redeemPin(String otp) async {
    if (busy) return;
    setState(() { busy = true; message = null; last = null; });
    try {
      final r = await api.redeemPin(deviceId: cfg.deviceId, otp: otp);
      await _finalizeAfterRedeem(r);
    } catch (e) {
      setState(() => message = 'เครือข่ายผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _finalizeAfterRedeem(RedeemResp r) async {
    if (!mounted) return;
    if (!r.ok) {
      setState(() => message = r.error ?? 'ยืนยันไม่สำเร็จ');
      return;
    }
    setState(() => last = r);

    final pulses = (r.units ?? 1) * (r.stepsPerUnit ?? 120);
    await api.report(
      deviceId: cfg.deviceId,
      jobId: r.jobId!,
      okFlag: true,
      pulses: pulses,
    );

    final name = r.patientName ?? (r.patientId ?? '');
    _snack('ยืนยันสำเร็จ • $name');

    if (mode == Mode.pin) setState(() => pin = "");
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final pastelCard = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5))],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('คีออสก์จ่ายยา'),
        actions: [
          const SizedBox(width: 8),
          SegmentedButton<Mode>(
            segments: const [
              ButtonSegment(value: Mode.scan, label: Text('สแกน QR'), icon: Icon(Icons.qr_code_scanner)),
              ButtonSegment(value: Mode.pin,  label: Text('กรอก PIN'), icon: Icon(Icons.keyboard)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (st) => st.contains(WidgetState.selected) ? const Color(0xFFBEE3FF) : const Color(0xFFE6F3FF),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ซ้าย: สถานะ + ผลลัพธ์
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: pastelCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Title(mode == Mode.scan ? 'สแกน QR จากใบสั่งแพทย์' : 'ยืนยันด้วย PIN 6 หลัก'),
                          const SizedBox(height: 8),
                          if (mode == Mode.pin) _PinDots(pin: pin) else const SizedBox.shrink(),
                          const SizedBox(height: 12),
                          if (message != null) _ErrorBanner(message!),
                          if (last != null) _ResultCard(last!),
                          const Spacer(),
                          Text(
                            mode == Mode.scan
                                ? (useCamera ? 'หันกล้องไปยัง QR' : 'ยังไม่เปิดกล้อง • ใช้ PIN/สแกนเนอร์ USB ได้ทันที')
                                : 'แตะปุ่มตัวเลขด้านขวา หรือใช้สแกนเนอร์ USB',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // ขวา: กล้อง หรือ Keypad + HID TextField ซ่อน
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: pastelCard,
                      child: Column(
                        children: [
                          Expanded(
                            child: mode == Mode.scan ? _buildScanner() : _buildKeypad(),
                          ),
                          // TextField ซ่อน สำหรับรับจากสแกนเนอร์ USB (HID)
                          Opacity(
                            opacity: 0.0,
                            child: TextField(
                              focusNode: _hidFocus,
                              onSubmitted: (value) {
                                final v = value.trim();
                                if (RegExp(r'^\d{6}$').hasMatch(v)) {
                                  _redeemPin(v);
                                } else {
                                  _handlePayload(v); // รองรับ ticket:...|otp:... ด้วย
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (busy) const _BusyOverlay(),
      ]),
    );
  }

  Widget _buildScanner() {
    if (!useCamera) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                'ยังไม่เปิดกล้อง\nคุณยังใช้โหมด PIN หรือสแกนเนอร์ USB (HID) ได้ตามปกติ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => setState(() => useCamera = true),
            icon: const Icon(Icons.videocam),
            label: const Text('เปิดกล้องเมื่อพร้อม'),
          ),
          const SizedBox(height: 4),
          const Text(
            'ถ้าเครื่องไม่มีเว็บแคม ปุ่มนี้จะมีผล และคุณยังใช้งาน PIN/HID ได้ตามปกติ',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerCtrl,
                  onDetect: (capture) async {
                    if (busy || _scanLock) return;
                    final raw = capture.barcodes.isNotEmpty
                        ? capture.barcodes.first.rawValue
                        : null;
                    if (raw == null) return;
                    _scanLock = true;
                    await _handlePayload(raw);
                    Future.delayed(const Duration(seconds: 1), () {
                      _scanLock = false;
                    });
                  },
                  onScannerStarted: (args) {
                    if (args.error != null) {
                      setState(() {
                        useCamera = false;
                        message = 'เปิดกล้องไม่สำเร็จ: ${args.error}';
                      });
                    }
                  },
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF7CC5FF), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => _scannerCtrl.switchCamera(),
              child: const Text('สลับกล้อง'),
            ),
            const SizedBox(width: 12),
            const Text('รองรับ: ticket:<uuid>|otp:<6> และ meddisp://v1/redeem?...',
                style: TextStyle(color: Colors.black45, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final d in ['1','2','3','4','5','6','7','8','9'])
                _KeyButton(label: d, onTap: () => _pushDigit(d)),
              _KeyButton(icon: Icons.backspace_outlined, onTap: _backspace),
              _KeyButton(label: '0', onTap: () => _pushDigit('0')),
              _KeyButton(
                icon: Icons.check_circle_outline,
                color: const Color(0xFF0EA5E9),
                onTap: () { if (pin.length == 6) _redeemPin(pin); },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('โทนสีฟ้าพาสเทล • พร้อมใช้งานจอสัมผัส', style: TextStyle(color: Colors.black54)),
      ],
    );
  }

  // keypad helpers
  void _pushDigit(String d) { if (!busy && pin.length < 6) setState(() => pin += d); }
  void _backspace() { if (!busy && pin.isNotEmpty) setState(() => pin = pin.substring(0, pin.length - 1)); }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF7CC5FF),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ===== UI widgets =====
class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F3D63)));
  }
}

class _PinDots extends StatelessWidget {
  final String pin;
  const _PinDots({required this.pin});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: List.generate(6, (i) {
        final filled = i < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(0xFF38BDF8) : Colors.transparent,
            border: Border.all(color: const Color(0xFF93C5FD), width: 2),
          ),
        );
      }),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  const _KeyButton({this.label, this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Text(label!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        : Icon(icon, size: 28);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFFE6F3FF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RedeemResp r;
  const _ResultCard(this.r);
  @override
  Widget build(BuildContext context) {
    final name = r.patientName ?? (r.patientId != null ? 'ผู้รับ #${r.patientId}' : 'พร้อมจ่ายยา');
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ผลลัพธ์', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('ชื่อผู้รับ: $name'),
          Text('งาน: ${r.jobId ?? "-"}'),
          Text('ช่องมอเตอร์: ${r.motorIndex ?? "-"}'),
          Text('จำนวนหน่วยยา: ${r.units ?? "-"}'),
          Text('สเตป/หน่วย: ${r.stepsPerUnit ?? "-"}'),
          const SizedBox(height: 4),
          const Text('ระบบรายงานสำเร็จอัตโนมัติแล้ว', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x80E6F3FF),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SpinKitThreeBounce(color: Color(0xFF7CC5FF), size: 40),
          SizedBox(height: 12),
          Text('กำลังตรวจสอบ...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}