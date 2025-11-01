import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api.dart' as api;
import 'config.dart' as cfg;
import 'models.dart';

// ---------------- THEME ----------------
const Color themePrimary   = Color(0xFF6BB2E1);
const Color themeBg        = Color(0xFFF7FAFC);
const Color themeCard      = Colors.white;
const Color themeTextDark  = Color(0xFF1A3A5A);
const Color themeTextLight = Color(0xFF718096);
const Color themeSuccess   = Color(0xFF48BB78);
const Color themeError     = Color(0xFFF56565);
const Color themeBorder    = Color(0xFFE2E8F0);

// Keypad overall scale (เล็ก/ใหญ่ทั้งชุด)
const double kKeypadScale = 0.75;
// --------------------------------------

// HID payload formats
final _qrRe  = RegExp(r'^ticket:([0-9a-fA-F-]{36})\|otp:(\d{6})$');
final _uriRe = RegExp(r'^meddisp://v1/redeem\?tid=([0-9a-fA-F-]{36})&otp=(\d{6})$');

enum Mode { hid, pin }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ รองรับทั้งแนวตั้ง/แนวนอน (auto-rotate)
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const KioskApp());
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meddispenso Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themePrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: themeBg,
        textTheme: GoogleFonts.promptTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: themeBg,
          foregroundColor: themeTextDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: themeTextDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

/// Portrait-first kiosk:
/// - HID scanner via hidden TextField (auto-refocus)
/// - PIN keypad with animations
/// - Calls api.api.redeem / api.api.redeemPin (kept). Report stubbed in _reportToBackend()
class _HomePageState extends State<HomePage> {
  Mode _mode = Mode.hid;
  String _pin = "";

  // HID focus handling
  final _hidFocus = FocusNode();
  final _hidController = TextEditingController();
  Timer? _refocusTimer;

  bool _busy = false;
  String? _message;
  RedeemResp? _lastResult;

  @override
  void initState() {
    super.initState();
    Future.microtask(_focusHid);
    _refocusTimer = Timer.periodic(const Duration(seconds: 3), (_) => _focusHid());
  }

  void _focusHid() {
    if (!mounted) return;
    _hidFocus.requestFocus();
  }

  @override
  void dispose() {
    _hidController.dispose();
    _hidFocus.dispose();
    _refocusTimer?.cancel();
    super.dispose();
  }

// ---------- Popup helpers (auto-dismiss 2s) ----------
Future<void> _showAutoPopup({
  required IconData icon,
  required Color color,
  required String title,
  String? subtitle,
}) async {
  if (!mounted) return;

  final navigator = Navigator.of(context);

  // ตั้ง auto dismiss 2 วิ (ไม่ return ออกไป)
  Future<void>.delayed(const Duration(seconds: 2), () {
    if (navigator.canPop()) navigator.pop();
  });

  // ระบุ generic <void> ชัดเจน และ await ให้ชนิดกลับเป็น Future<void>
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    barrierLabel: 'Status',
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) {
      return SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.6), // ลอยด้านบนเล็กน้อย
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: themeCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(color: themeTextDark),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    // บังคับชนิด Animation<double> และใช้ Tween<double>
    transitionBuilder: (_, Animation<double> anim, __, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
          child: child,
        ),
      );
    },
  );
}


  Future<void> _showSuccessPopup(RedeemResp r) async {
    final name = r.patientName ?? (r.patientId != null ? 'Patient #${r.patientId}' : 'N/A');
    final lines = [
      'Patient: $name',
      if (r.units != null) 'Units: ${r.units}',
    ].where((e) => e.isNotEmpty).join(' • ');
    await _showAutoPopup(
      icon: Icons.check_circle_rounded,
      color: themeSuccess,
      title: 'Dispensing Complete',
      subtitle: lines.isEmpty ? null : lines,
    );
  }

  Future<void> _showErrorPopup(String msg) async {
    await _showAutoPopup(
      icon: Icons.error_outline_rounded,
      color: themeError,
      title: 'Verification Failed',
      subtitle: msg,
    );
  }
  // -----------------------------------------------------

  // ==================== Core flows ====================

  Future<void> _handlePayload(String payload) async {
    final s = payload.trim();
    String? tid, otp;

    final m1 = _qrRe.firstMatch(s);
    if (m1 != null) {
      tid = m1.group(1);
      otp = m1.group(2);
    }
    if (tid == null || otp == null) {
      final m2 = _uriRe.firstMatch(s);
      if (m2 != null) {
        tid = m2.group(1);
        otp = m2.group(2);
      }
    }

    if (tid != null && otp != null) {
      await _redeemTicket(tid, otp);
      return;
    }
    if (RegExp(r'^\d{6}$').hasMatch(s)) {
      await _redeemPin(s);
      return;
    }

    setState(() => _message = 'Invalid data format');
    unawaited(_showErrorPopup('Invalid data format'));
  }

  Future<void> _redeemTicket(String ticketId, String otp) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; _lastResult = null; });
    try {
      final r = await api.api.redeem(
        deviceId: cfg.deviceId,
        deviceKeyPlain: cfg.deviceKey,
        ticketId: ticketId,
        otp: otp,
      );
      await _finalizeAfterRedeem(r);
    } catch (e) {
      setState(() => _message = 'Network Error: $e');
      unawaited(_showErrorPopup('Network Error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeemPin(String otp) async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; _lastResult = null; });
    try {
      final r = await api.api.redeemPin(
        deviceId: cfg.deviceId,
        otp: otp,
      );
      await _finalizeAfterRedeem(r);
    } catch (e) {
      setState(() => _message = 'Network Error: $e');
      unawaited(_showErrorPopup('Network Error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// (Optional) Reporting hook — คง workflow เดิม โดยไม่พัง build ถ้าไม่มี method ฝั่ง API
  Future<void> _reportToBackend({
    required String jobId,
    required int pulses,
  }) async {
    // ถ้ามีเมธอด report ใน api.dart ให้เปลี่ยนมาเรียกตรงนี้
    // try {
    //   await api.api.reportJob(
    //     deviceId: cfg.deviceId,
    //     jobId: jobId,
    //     okFlag: true,
    //     pulses: pulses,
    //   );
    // } catch (_) {}
  }

  Future<void> _finalizeAfterRedeem(RedeemResp r) async {
    if (!mounted) return;

    if (!r.ok) {
      setState(() => _message = r.error ?? 'Verification failed');
      unawaited(_showErrorPopup(r.error ?? 'Verification failed'));
      _resetStateAfterDelay();
      return;
    }

    setState(() => _lastResult = r);
    unawaited(_showSuccessPopup(r));

    // pulses = units * stepsPerUnit (kept)
    final pulses = (r.units ?? 1) * (r.stepsPerUnit ?? 120);

    if (r.jobId != null) {
      await _reportToBackend(jobId: r.jobId!, pulses: pulses);
    }

    _resetStateAfterDelay();
  }

  void _resetStateAfterDelay() {
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() {
        _pin = "";
        _message = null;
        _lastResult = null;
        _busy = false;
        _mode = Mode.hid; // default back
      });
      _focusHid();
    });
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;

    // Content max width
    final maxW = isPortrait ? 1100.0 : 1600.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Meddispenso Kiosk')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            const pad = 24.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: pad, vertical: pad),
                  child: Stack(
                    children: [
                      isPortrait
                          ? Column(
                              children: [
                                _LeftPane(
                                  mode: _mode,
                                  pin: _pin,
                                  message: _message,
                                  result: _lastResult,
                                  onSelectMode: (m) {
                                    setState(() => _mode = m);
                                    if (m == Mode.hid) _focusHid();
                                  },
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _RightPane(
                                    mode: _mode,
                                    onDigit: _pushDigit,
                                    onBackspace: _backspace,
                                    onSubmitPin: () { if (_pin.length == 6) _redeemPin(_pin); },
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _LeftPane(
                                    mode: _mode,
                                    pin: _pin,
                                    message: _message,
                                    result: _lastResult,
                                    onSelectMode: (m) {
                                      setState(() => _mode = m);
                                      if (m == Mode.hid) _focusHid();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _RightPane(
                                    mode: _mode,
                                    onDigit: _pushDigit,
                                    onBackspace: _backspace,
                                    onSubmitPin: () { if (_pin.length == 6) _redeemPin(_pin); },
                                  ),
                                ),
                              ],
                            ),

                      // Hidden TextField for HID scanner input
                      ExcludeSemantics(
                        child: Offstage(
                          offstage: false,
                          child: SizedBox(
                            width: 1,
                            height: 1,
                            child: TextField(
                              controller: _hidController,
                              focusNode: _hidFocus,
                              autofocus: true,
                              readOnly: true, // prevent soft keyboard
                              textInputAction: TextInputAction.done,
                              enableInteractiveSelection: false,
                              decoration: const InputDecoration.collapsed(hintText: ''),
                              onSubmitted: (s) {
                                _hidController.clear();
                                _handlePayload(s);
                              },
                              onEditingComplete: () {
                                final s = _hidController.text;
                                _hidController.clear();
                                if (s.isNotEmpty) _handlePayload(s);
                              },
                            ),
                          ),
                        ),
                      ),

                      if (_busy)
                        Container(
                          color: themeCard.withOpacity(0.7),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: themePrimary),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _pushDigit(String d) {
    if (_busy || _pin.length >= 6) return;
    setState(() => _pin += d);
    HapticFeedback.selectionClick();
    if (_pin.length == 6) {
      _redeemPin(_pin);
    }
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    HapticFeedback.selectionClick();
  }
}

// -------------------- LEFT PANE --------------------

class _LeftPane extends StatelessWidget {
  final Mode mode;
  final String pin;
  final String? message;
  final RedeemResp? result;
  final ValueChanged<Mode> onSelectMode;

  const _LeftPane({
    required this.mode,
    required this.pin,
    required this.message,
    required this.result,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meddispenso Kiosk',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeTextDark)),

          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: _Title(
              key: ValueKey(mode),
              mode == Mode.hid ? 'Scan QR Code to Dispense' : 'Verify with 6-digit PIN',
            ),
          ),

          const SizedBox(height: 18),

          // PIN dots (only when in PIN mode)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: mode == Mode.pin ? 1.0 : 0.0,
              child: mode == Mode.pin
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _PinDots(pin: pin),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          _ModeButton(
            title: 'Scan QR Code',
            subtitle: 'Scan the QR code from your application',
            icon: Icons.qr_code_scanner_rounded,
            isSelected: mode == Mode.hid,
            onTap: () => onSelectMode(Mode.hid),
          ),
          const SizedBox(height: 12),
          _ModeButton(
            title: 'Enter PIN',
            subtitle: 'Use the on-screen keypad',
            icon: Icons.pin_rounded,
            isSelected: mode == Mode.pin,
            onTap: () => onSelectMode(Mode.pin),
          ),

          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: message != null
                ? _ErrorBanner(message!)
                : result != null
                    ? _ResultCard(result!)
                    : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          const Text('Please follow the on-screen instructions.',
              style: TextStyle(color: themeTextLight)),
        ],
      ),
    );
  }
}

// -------------------- RIGHT PANE --------------------

class _RightPane extends StatelessWidget {
  final Mode mode;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmitPin;

  const _RightPane({
    required this.mode,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmitPin,
  });

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: themeCard,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: themeBorder),
      boxShadow: [
        BoxShadow(color: Colors.grey.shade200, blurRadius: 18, offset: const Offset(0, 6)),
      ],
    );

    return Container(
      decoration: cardDecoration,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: mode == Mode.hid
            ? const _HidPane()
            : _Keypad(onDigit: onDigit, onBackspace: onBackspace, onSubmit: onSubmitPin),
      ),
    );
  }
}

class _HidPane extends StatelessWidget {
  const _HidPane();
  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('hid'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.qr_code_2_rounded, size: 180, color: themePrimary),
            SizedBox(height: 24),
            Text('Ready to Scan',
                style: TextStyle(fontSize: 24, color: themeTextDark, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Please use your HID scanner to scan the QR code from the mobile app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: themeTextLight, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keypad with explicit diameter control (kKeypadScale shrinks from fit size)
class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('pin'),
      padding: const EdgeInsets.all(20.0),
      child: LayoutBuilder(
        builder: (context, c) {
          const cols = 3;
          const rows = 4;
          const gap  = 14.0;

          final maxDiaByWidth  = (c.maxWidth  - gap * (cols - 1)) / cols;
          final maxDiaByHeight = (c.maxHeight - gap * (rows - 1)) / rows;
          final baseDia = maxDiaByWidth < maxDiaByHeight ? maxDiaByWidth : maxDiaByHeight;

          // shrink from the “fit” size
          final dia = (baseDia * kKeypadScale).clamp(64.0, 150.0);

          final gridW = cols * dia + (cols - 1) * gap;
          final gridH = rows * dia + (rows - 1) * gap;

          return Center(
            child: SizedBox(
              width: gridW,
              height: gridH,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  if (i < 9) {
                    final d = '${i + 1}';
                    return _KeyButton(label: d, diameter: dia, onTap: () => onDigit(d));
                  } else if (i == 9) {
                    return _KeyButton(
                      icon: Icons.backspace_outlined,
                      diameter: dia,
                      onTap: onBackspace,
                      backgroundColor: themeError.withOpacity(0.08),
                      iconColor: themeError,
                    );
                  } else if (i == 10) {
                    return _KeyButton(label: '0', diameter: dia, onTap: () => onDigit('0'));
                  } else {
                    return _KeyButton(
                      icon: Icons.check_circle_outline_rounded,
                      diameter: dia,
                      onTap: onSubmit,
                      backgroundColor: themeSuccess.withOpacity(0.08),
                      iconColor: themeSuccess,
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------- Shared widgets --------------------

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: themeTextDark));
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? themePrimary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? themePrimary : themeBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? themePrimary : themeTextLight),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: themeTextDark)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: themeTextLight)),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(Icons.check_circle, color: themePrimary, key: ValueKey(true))
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final String pin;
  const _PinDots({required this.pin});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: List.generate(6, (i) {
        final filled = i < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? themePrimary : themeCard,
            border: Border.all(color: filled ? themePrimary : themeBorder, width: 2),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: themePrimary.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double diameter;

  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    required this.diameter,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    final contentSize = (d * 0.36).clamp(18.0, 34.0); // digit/icon size relative to button

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 1.10 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: SizedBox.square(
          dimension: d,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor ?? Colors.white,
              border: Border.all(color: themeBorder),
              boxShadow: _isPressed
                  ? [BoxShadow(color: themePrimary.withOpacity(0.28), blurRadius: 10, spreadRadius: 2)]
                  : [],
            ),
            child: Center(
              child: widget.label != null
                  ? Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: contentSize,
                        color: themeTextDark,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      color: widget.iconColor ?? themeTextDark,
                      size: contentSize,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RedeemResp r;
  const _ResultCard(this.r);
  @override
  Widget build(BuildContext context) {
    final name = r.patientName ?? (r.patientId != null ? 'Patient #${r.patientId}' : 'N/A');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeSuccess.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: themeSuccess, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Dispensing Complete',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeSuccess)),
                const SizedBox(height: 4),
                Text('Patient: $name', style: const TextStyle(color: themeTextDark)),
                Text('Units: ${r.units ?? "-"}', style: const TextStyle(color: themeTextDark)),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeError.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: themeError),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: themeError, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
