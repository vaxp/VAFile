import 'dart:ui'; // مهم للـ ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/presentation/pages/widgets/BuildCurrentPath.dart';
import 'package:vafile/presentation/pages/widgets/navigation_controls.dart';
import 'package:window_manager/window_manager.dart';
import '../../../application/file_manager/file_manager_bloc.dart' as fm;
import 'package:vafile/search/application/search_handler.dart';
import 'package:vafile/search/application/search_cubit.dart';
// ignore: unused_import
import '../widgets/menu_options.dart';


// 1. هذا هو الـ Layout الرئيسي الذي ستستخدمه في تطبيقك
class VenomScaffold extends StatefulWidget {
  final Widget body; // محتوى الصفحة (الإعدادات)
  // final String title;

  const VenomScaffold({
    Key? key,
    required this.body,
    // this.title = "VA File",

  }) : super(key: key);

  @override
  State<VenomScaffold> createState() => _VenomScaffoldState();
}

class _VenomScaffoldState extends State<VenomScaffold> {
  // متغير الحالة للتحكم في الضبابية
  bool _isCinematicBlurActive = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setBlur(bool active) {
    if (_isCinematicBlurActive != active) {
      setState(() {
        _isCinematicBlurActive = active;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // مهم لشفافية النافذة
      body: Stack(
        children: [
          // --- الطبقة 1: محتوى التطبيق ---
          // نستخدم TweenAnimationBuilder لتحريك قيمة الـ Blur بنعومة
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: _isCinematicBlurActive
                  ? 10.0
                  : 0.0, // قوة البلور (10 قوية وجميلة)
            ),
            duration: const Duration(milliseconds: 300), // سرعة الأنيميشن
            curve: Curves.easeOutCubic, // منحنى حركة ناعم
            builder: (context, blurValue, child) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurValue,
                  sigmaY: blurValue,
                ),
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 40), // نترك مساحة للـ Appbar
              child: widget.body,
            ),
          ),

          // --- الطبقة 2: شريط العنوان (فوق الكل) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VenomAppbar(
              // title: widget.title,
              searchController: _searchController,
              // تمرير دالة للتحكم في البلور عند لمس الأزرار
              onHoverEnter: () => _setBlur(true),
              onHoverExit: () => _setBlur(false),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. شريط العنوان المعدل (يرسل إشارات الهوفر)
class VenomAppbar extends StatelessWidget {
  final String? title;
  final TextEditingController searchController;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  const VenomAppbar({
    Key? key,
     this.title,
    required this.searchController,
    required this.onHoverEnter,
    required this.onHoverExit,
  }) : super(key: key);

Widget _buildMoreOptionsButton(BuildContext context) {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.white70),
          tooltip: 'More Options',
          onPressed: () {
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
            
            final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

            // --- إعدادات التوسيط ---
            // بما أن عرض القائمة ديناميكي (يعتمد على النص)، نضع قيمة تقديرية.
            // القوائم المنسدلة عادة عرضها بين 150 إلى 200 بكسل.
            // جرب تغيير هذا الرقم (مثلاً 160 أو 180) حتى تصبح القائمة في المنتصف تماماً.
            const double estimatedMenuWidth = 170.0; 

            // المعادلة: (موقع الزر + نصف عرضه) - (نصف عرض القائمة التقديري)
            // هذا يجعل منتصف القائمة ينطبق على منتصف الزر
            final double centeredDx = offset.dx + (button.size.width / 2) - (estimatedMenuWidth / 2);

            final Rect positionRect = Rect.fromLTWH(
              centeredDx, // الإحداثية الجديدة المحسوبة
              offset.dy + button.size.height + 5, // أسفل الزر مع مسافة صغيرة
              estimatedMenuWidth, // نمرر العرض التقديري هنا أيضاً
              0 
            );

            final RelativeRect position = RelativeRect.fromRect(
              positionRect,
              Offset.zero & overlay.size,
            );
          
            MenuOptions.showMoreOptionsMenu(context, position: position);
          },
        );
      },
    );
  }




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
        // خلفية نصف شفافة للشريط نفسه
        color: const Color.fromARGB(100, 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
           const NavigationControls(),
             const Buildcurrentpath(),
            FileManagerSearchBar(searchController: searchController),
            _buildMoreOptionsButton(context),
            const Spacer(),

            // مجموعة الأزرار
            // نستخدم MouseRegion واحد كبير حول الأزرار الثلاثة
            // لضمان استمرار البلور عند التنقل بين زر وآخر
            MouseRegion(
              onEnter: (_) => onHoverEnter(),
              onExit: (_) => onHoverExit(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VenomWindowButton(
                    color: const Color(0xFFFFBD2E),
                    icon: Icons.remove,
                    onPressed: () => windowManager.minimize(),
                  ),

                  const SizedBox(width: 8),
                  VenomWindowButton(
                    color: const Color(0xFF28C840),
                    icon: Icons.check_box_outline_blank_rounded,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  VenomWindowButton(
                    color: const Color(0xFFFF5F57),
                    icon: Icons.close,
                    onPressed: () => windowManager.close(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. زر النافذة (نفس الذي صممناه سابقاً مع تحسينات طفيفة)
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: 10, // زيادة التوهج قليلاً
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Icon(
                widget.icon,
                size: 10,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 4. Search Bar Widget
class FileManagerSearchBar extends StatelessWidget {
  final TextEditingController searchController;

  const FileManagerSearchBar({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: TextField(
          controller: searchController,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white54, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: false,
          ),
          onChanged: (value) {
            // Update the dedicated SearchCubit (for advanced searches / suggestions)
            try {
              context.read<SearchCubit>().updateQuery(value);
            } catch (_) {}

            // Keep existing quick filter behavior for the file grid
            context.read<fm.FileManagerBloc>().add(fm.SearchFiles(value));
          },
          onSubmitted: (value) {
            final handler = SearchHandler(
              context: context,
              onResetSearch: () {
                searchController.clear();
                try {
                  context.read<SearchCubit>().clearQuery();
                } catch (_) {}
              },
            );

            // If the handler recognizes the input as a special command (ai:, g:, vafile:, etc.) it will
            // handle it and return true. Otherwise, fall back to the FileManager search behavior.
            final handled = handler.handleSearch(value);
            if (!handled) {
              context.read<fm.FileManagerBloc>().add(fm.SearchFiles(value));
            }
          },
        ),
      ),
    );
  }
}

