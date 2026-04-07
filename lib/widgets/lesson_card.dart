import 'package:flutter/material.dart';


class LessonEntry {
  final String id;
  final String title;
  final String description;
  final String practiceInfo;
  final bool unlocked;


  final void Function(BuildContext context)? onTap;

  const LessonEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.practiceInfo,
    this.unlocked = false,
    this.onTap,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LessonCard — expandable white card shown in the lesson list.
//
//  Usage:
//    LessonCard(
//      lesson:      entry,
//      accentColor: AppLanguage.navi.accentColor,
//      onBegin:     entry.unlocked ? () => entry.onTap?.call(context) : null,
//    )
// ═══════════════════════════════════════════════════════════════════════════════

class LessonCard extends StatefulWidget {
  final LessonEntry lesson;
  final Color accentColor;

  final VoidCallback? onBegin;

  const LessonCard({
    super.key,
    required this.lesson,
    this.accentColor = const Color(0xFF5B4FFF),
    this.onBegin,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.lesson.unlocked;
    final accent = widget.accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: locked
                            ? const Color(0xFFF0F0F0)
                            : accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        locked
                            ? Icons.lock_outline_rounded
                            : Icons.star_rounded,
                        color: locked
                            ? const Color(0xFFBBBBBB)
                            : accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.lesson.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: locked
                              ? const Color(0xFF999999)
                              : const Color(0xFF111111),
                        ),
                      ),
                    ),
                    // Animated chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded
                            ? accent
                            : const Color(0xFF888888),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.lesson.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.lesson.practiceInfo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // BEGIN / LOCKED button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: GestureDetector(
                        onTap: widget.onBegin,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: locked
                                ? const Color(0xFFF0F0F0)
                                : accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: locked
                                  ? const Color(0xFFE0E0E0)
                                  : accent.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            locked ? 'LOCKED' : 'BEGIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: locked
                                  ? const Color(0xFFBBBBBB)
                                  : accent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
