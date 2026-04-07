// import 'package:flutter/material.dart';
// import 'theme/app_theme.dart';
// import 'screens/home/profile_page.dart';
//
// // ═══════════════════════════════════════════════════════════════════════════════
// //  Global navigator key — shared between MaterialApp and the bar
// // ═══════════════════════════════════════════════════════════════════════════════
//
// final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
//
// // ═══════════════════════════════════════════════════════════════════════════════
// //  Global bar controller (singleton)
// // ═══════════════════════════════════════════════════════════════════════════════
//
// class PersistentBarController extends ChangeNotifier {
//   static final PersistentBarController instance = PersistentBarController._();
//   PersistentBarController._();
//
//   bool _visible = false;
//   bool _inLesson = false;
//
//   bool get visible => _visible;
//   bool get inLesson => _inLesson;
//
//   void show() {
//     if (!_visible) { _visible = true; notifyListeners(); }
//   }
//
//   void hide() {
//     if (_visible) { _visible = false; notifyListeners(); }
//   }
//
//   /// Call when entering a lesson screen.
//   void enterLesson() {
//     if (!_inLesson) { _inLesson = true; notifyListeners(); }
//   }
//
//   /// Call when leaving a lesson screen.
//   void exitLesson() {
//     if (_inLesson) { _inLesson = false; notifyListeners(); }
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════════════════════
// //  Bar wrapper — inserted via MaterialApp.builder
// // ═══════════════════════════════════════════════════════════════════════════════
//
// class PersistentBarWrapper extends StatefulWidget {
//   final Widget child;
//   const PersistentBarWrapper({super.key, required this.child});
//
//   @override
//   State<PersistentBarWrapper> createState() => _PersistentBarWrapperState();
// }
//
// class _PersistentBarWrapperState extends State<PersistentBarWrapper> {
//   final _ctrl = PersistentBarController.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     _ctrl.addListener(_onChange);
//   }
//
//   void _onChange() {
//     if (mounted) setState(() {});
//   }
//
//   @override
//   void dispose() {
//     _ctrl.removeListener(_onChange);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_ctrl.visible) return widget.child;
//
//     return Column(
//       children: [
//         Expanded(child: widget.child),
//         _PersistentBottomBar(),
//       ],
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════════════════════
// //  The bar
// // ═══════════════════════════════════════════════════════════════════════════════
//
// class _PersistentBottomBar extends StatelessWidget {
//   NavigatorState get _nav => appNavigatorKey.currentState!;
//   PersistentBarController get _ctrl => PersistentBarController.instance;
//
//   /// If in a lesson, show a warning dialog. Returns true if user chose to leave.
//   Future<bool> _confirmLeaveLesson() async {
//     final context = _nav.overlay!.context;
//     final result = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         backgroundColor: AppColors.surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           'Leave lesson?',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         content: const Text(
//           'Your progress in this lesson will not be saved.',
//           style: TextStyle(color: AppColors.textSecondary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Stay here'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: Text('Leave', style: TextStyle(color: AppColors.error)),
//           ),
//         ],
//       ),
//     );
//     return result ?? false;
//   }
//
//   void _onBack() async {
//     if (!_nav.canPop()) return;
//
//     if (_ctrl.inLesson) {
//       final leave = await _confirmLeaveLesson();
//       if (!leave) return;
//       _ctrl.exitLesson();
//     }
//
//     _nav.pop();
//   }
//
//   void _onHome() async {
//     if (_ctrl.inLesson) {
//       final leave = await _confirmLeaveLesson();
//       if (!leave) return;
//       _ctrl.exitLesson();
//     }
//
//     _nav.popUntil((route) => route.isFirst);
//   }
//
//   void _onProfile() {
//     // No warning needed — profile doesn't discard lesson state.
//     // If in a lesson and they want profile, they can go — but we should
//     // still warn since the lesson screen will be popped from the stack.
//     // Actually, push on top so lesson stays in stack.
//     _nav.push(
//       MaterialPageRoute(builder: (_) => const ProfilePage()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         border: const Border(
//           top: BorderSide(color: AppColors.inputBorder, width: 0.5),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _BarItem(
//                 icon: Icons.arrow_back_rounded,
//                 label: 'Back',
//                 onTap: _onBack,
//               ),
//               _BarItem(
//                 icon: Icons.home_rounded,
//                 label: 'Home',
//                 onTap: _onHome,
//               ),
//               _BarItem(
//                 icon: Icons.person_rounded,
//                 label: 'Profile',
//                 onTap: _onProfile,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _BarItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//
//   const _BarItem({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: AppColors.textSecondary, size: 24),
//             const SizedBox(height: 3),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w400,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home/profile_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Global navigator key — shared between MaterialApp and the bar
// ═══════════════════════════════════════════════════════════════════════════════

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// ═══════════════════════════════════════════════════════════════════════════════
//  Global bar controller (singleton)
// ═══════════════════════════════════════════════════════════════════════════════

class PersistentBarController extends ChangeNotifier {
  static final PersistentBarController instance = PersistentBarController._();
  PersistentBarController._();

  bool _visible = false;
  bool _inLesson = false;

  bool get visible => _visible;
  bool get inLesson => _inLesson;

  void show() {
    if (!_visible) { _visible = true; notifyListeners(); }
  }

  void hide() {
    if (_visible) { _visible = false; notifyListeners(); }
  }

  /// Call when entering a lesson screen.
  void enterLesson() {
    if (!_inLesson) { _inLesson = true; notifyListeners(); }
  }

  /// Call when leaving a lesson screen.
  void exitLesson() {
    if (_inLesson) { _inLesson = false; notifyListeners(); }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Bar wrapper — inserted via MaterialApp.builder
//
//  NOTE: The old persistent bottom bar is temporarily disabled.
//        The new AppNavBar (lib/widgets/app_nav_bar.dart) is used instead.
//        To re-enable, uncomment the _PersistentBottomBar() line below.
// ═══════════════════════════════════════════════════════════════════════════════

class PersistentBarWrapper extends StatefulWidget {
  final Widget child;
  const PersistentBarWrapper({super.key, required this.child});

  @override
  State<PersistentBarWrapper> createState() => _PersistentBarWrapperState();
}

class _PersistentBarWrapperState extends State<PersistentBarWrapper> {
  final _ctrl = PersistentBarController.instance;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Old bar temporarily disabled — new AppNavBar handles navigation.
    // if (!_ctrl.visible) return widget.child;
    // return Column(
    //   children: [
    //     Expanded(child: widget.child),
    //     _PersistentBottomBar(),    // ← re-enable this to restore old bar
    //   ],
    // );

    return widget.child;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  The old bar — kept intact below for easy re-activation
// ═══════════════════════════════════════════════════════════════════════════════

class _PersistentBottomBar extends StatelessWidget {
  NavigatorState get _nav => appNavigatorKey.currentState!;
  PersistentBarController get _ctrl => PersistentBarController.instance;

  /// If in a lesson, show a warning dialog. Returns true if user chose to leave.
  Future<bool> _confirmLeaveLesson() async {
    final context = _nav.overlay!.context;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave lesson?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your progress in this lesson will not be saved.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay here'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onBack() async {
    if (!_nav.canPop()) return;
    if (_ctrl.inLesson) {
      final leave = await _confirmLeaveLesson();
      if (!leave) return;
      _ctrl.exitLesson();
    }
    _nav.pop();
  }

  void _onHome() async {
    if (_ctrl.inLesson) {
      final leave = await _confirmLeaveLesson();
      if (!leave) return;
      _ctrl.exitLesson();
    }
    _nav.popUntil((route) => route.isFirst);
  }

  void _onProfile() {
    _nav.push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.inputBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarItem(icon: Icons.arrow_back_rounded, label: 'Back', onTap: _onBack),
              _BarItem(icon: Icons.home_rounded, label: 'Home', onTap: _onHome),
              _BarItem(icon: Icons.person_rounded, label: 'Profile', onTap: _onProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}