// import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
//
// class TextPage extends StatelessWidget {
//   final String text;
//   final int lessonId;
//   final VoidCallback onNext;
//
//   const TextPage({
//     super.key,
//     required this.text,
//     required this.lessonId,
//     required this.onNext,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Lesson ${lessonid} - ${lesson.title}'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: AppColors.textPrimary,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//
//             const SizedBox(height: 20),
//
//             // Icon
//             Center(
//               child: Container(
//                 width: 120,
//                 height: 120,
//                 decoration: const BoxDecoration(
//                   color: AppColors.primaryLight,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.menu_book_rounded,
//                   size: 60,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 40),
//
//             // Lesson text
//             Text(
//               text,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 color: AppColors.textPrimary,
//                 height: 1.5,
//                 fontSize: 18,
//               ),
//             ),
//
//             const Spacer(),
//
//             // Continue button
//             ElevatedButton(
//               onPressed: onNext,
//               child: const Text("Continue"),
//             ),
//
//             const SizedBox(height: 12),
//           ],
//         ),
//       ),
//     );
//   }
// }
