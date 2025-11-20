import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40); // تم التعديل ليتطابق مع الـ Container

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        await windowManager.startDragging();
      },
      child: Container(
        height: 40,
        alignment: Alignment.centerRight,
        // حافظت على لونك، لكن يمكنك تقليل الشفافية إذا أردت
        color: const Color.fromARGB(156, 0, 0, 0), 
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 15.0), // تعديل بسيط للمسافة
              child: Text(
                'VA File Manager',
                style: TextStyle(
                  fontSize: 14, // حجم مناسب أكثر لشريط العنوان
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            
            // --- زر الإغلاق (أحمر) ---
            VenomWindowButton(
              color: const Color(0xFFFF5F57), // لون ماك الأحمر
              icon: Icons.close,
              onPressed: () => windowManager.close(),
            ),
            
            const SizedBox(width: 8), // مسافة بين الأزرار
            
            // --- زر التصغير (أصفر) ---
            VenomWindowButton(
              color: const Color(0xFFFFBD2E), // لون ماك الأصفر
              icon: Icons.remove,
              onPressed: () => windowManager.minimize(),
            ),
            
            const SizedBox(width: 8),
            
            // --- زر التكبير (أخضر) ---
            VenomWindowButton(
              color: const Color(0xFF28C840), // لون ماك الأخضر
              icon: Icons.check_box_outline_blank_rounded, // أيقونة البوكس
              // إضافة لوجيك للتبديل بين التكبير والاستعادة
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// --- الويدجت السحري الجديد للأزرار ---
class VenomWindowButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const VenomWindowButton({
    Key? key,
    required this.color,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<VenomWindowButton> createState() => _VenomWindowButtonState();
}

class _VenomWindowButtonState extends State<VenomWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // تغيير شكل الماوس ليد عند المرور
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        // AnimatedContainer للتعامل مع التوهج (Shadow)
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 14, // حجم الزر (قياسي في ماك)
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _isHovered
                ? [
                    // التوهج عند مرور الماوس
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          // سنترنا الأيقونة داخل الزر
          child: Center(
            // AnimatedOpacity لإظهار وإخفاء الأيقونة بنعومة
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0, // تظهر فقط عند الهوفر
              child: Icon(
                widget.icon,
                size: 10, // حجم الأيقونة مناسب لزر 14
                color: Colors.black.withOpacity(0.6), // لون الأيقونة داكن قليلاً
              ),
            ),
          ),
        ),
      ),
    );
  }
}


