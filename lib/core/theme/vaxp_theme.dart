import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors/vaxp_colors.dart';
import '../text/vaxp_text_theme.dart';

class VaxpTheme {
  /// 🎨 الثيم الرسمي (دارك + زجاجي)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: VaxpColors.primary,
          secondary: VaxpColors.secondary,
          // ignore: deprecated_member_use
          background: VaxpColors.darkGlassBackground,
          surface: VaxpColors.glassSurface,
        ),
        scaffoldBackgroundColor: VaxpColors.darkGlassBackground,
        primaryColor: VaxpColors.primary,
        textTheme: VaxpTextTheme.darkText,


        // ⚡️ AppBar شفاف بزجاجية
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // 📦 Card
        cardTheme: CardThemeData(
          color: VaxpColors.glassSurface,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(8),
        ),

        // 🔘 ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            // ignore: deprecated_member_use
            backgroundColor: VaxpColors.primary.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // ⚪ OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            // ignore: deprecated_member_use
            side: BorderSide(color: VaxpColors.primary.withOpacity(0.5)),
            foregroundColor: VaxpColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),

        // 🧭 NavigationBar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          height: 72,
          // ignore: deprecated_member_use
          indicatorColor: VaxpColors.primary.withOpacity(0.25),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: Colors.white),
          ),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),

        // ⚙️ Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: VaxpColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),

        // 💬 TextFields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: VaxpColors.glassSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                // ignore: deprecated_member_use
                BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: VaxpColors.primary, width: 1.3),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white),
        ),

        // 🧩 Drawer
        drawerTheme: DrawerThemeData(
          backgroundColor: VaxpColors.glassSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),

        // 💬 Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: VaxpColors.glassSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titleTextStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          contentTextStyle:
              const TextStyle(fontSize: 15, color: Colors.white70),
        ),

        // ✅ Checkbox / Switch / Slider
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(VaxpColors.primary),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
        switchTheme: SwitchThemeData(
          thumbColor:
              // ignore: deprecated_member_use
              WidgetStateProperty.all(VaxpColors.primary.withOpacity(0.9)),
          trackColor:
              // ignore: deprecated_member_use
              WidgetStateProperty.all(VaxpColors.primary.withOpacity(0.4)),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: VaxpColors.primary,
          thumbColor: VaxpColors.primary,
          // ignore: deprecated_member_use
          inactiveTrackColor: VaxpColors.primary.withOpacity(0.2),
        ),

        // 🧭 BottomSheet
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: VaxpColors.glassSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      );
}

/// 🧊 أداة جاهزة لتطبيق الزجاج (Blur) على أي Widget
class VaxpGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? radius;

  const VaxpGlass({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.25,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(opacity * 0.8),
            borderRadius: radius ?? BorderRadius.circular(20),
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}
