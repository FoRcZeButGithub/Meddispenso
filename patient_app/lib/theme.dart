import 'package:flutter/material.dart';

class AppColors {
  static const brand = Color(0xFF173A5E);
  static const bg = Color(0xFFF7FBFF);
  static const card = Color(0xFFF1F6FD);
  static const stroke = Color(0xFFE5EEF8);
  static const text = Color(0xFF0F2B46);
  static const subtext = Color(0xFF597493);
  static const success = Color(0xFF2BB673);
  static const successSoft = Color(0xFFEAF9F0);
  static const danger = Color(0xFFE05263);
  static const dangerSoft = Color(0xFFFDECEF);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      onPrimary: Colors.white,
      surface: AppColors.card,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.subtext, height: 1.4),
    ),
  );

  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: const Color(0xFFE7F1FF),
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.stroke),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand),
    ),
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        border: Border.all(color: AppColors.stroke),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0,6))],
      ),
      child: child,
    );
  }
}

class PinDisplay extends StatelessWidget {
  final String pin; // e.g. "123456"
  const PinDisplay({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    final count = pin.trim().length.clamp(0, 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(6, (i) {
        final filled = i < count;
        return Container(
          width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.stroke),
            color: Colors.white,
          ),
          child: filled ? const Text('•', style: TextStyle(fontSize: 20, color: AppColors.text))
                        : const SizedBox.shrink(),
        );
      }),
    );
  }
}

class RoundAction extends StatelessWidget {
  final IconData icon;
  final Color fill;
  final Color iconColor;
  final VoidCallback? onPressed;
  const RoundAction({super.key, required this.icon, required this.fill, required this.iconColor, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill, shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52, height: 52,
          child: Icon(icon, color: iconColor, size: 26),
        ),
      ),
    );
  }
}
