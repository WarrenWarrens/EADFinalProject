import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../widgets/app_language.dart';


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

  /// Controlled expansion. When provided, the parent owns the expanded state
  /// (used to enforce single-card-open behavior on the lesson list). When
  /// null, the card manages its own state.
  final bool? expanded;
  final VoidCallback? onExpansionChanged;

  const LessonCard({
    super.key,
    required this.lesson,
    this.accentColor = const Color(0xFF80D8FF), // Na'vi
    this.onBegin,
    this.expanded,
    this.onExpansionChanged,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard>
    with SingleTickerProviderStateMixin {
  bool _internalExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  bool get _expanded => widget.expanded ?? _internalExpanded;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant LessonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync animation when parent flips controlled expansion.
    if (widget.expanded != oldWidget.expanded && widget.expanded != null) {
      widget.expanded! ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onExpansionChanged != null) {
      // Parent-controlled — let it decide.
      widget.onExpansionChanged!();
      return;
    }
    setState(() => _internalExpanded = !_internalExpanded);
    _internalExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.lesson.unlocked;
    final accent = widget.accentColor;
    final palette = AppTheme.of(context);
    // Inner contrast block: in dark mode use the lighter surfaceAlt;
    // in light mode use the darker parchment divider tone for visible contrast.
    final innerBlockColor =
    palette.isDark ? palette.surfaceAlt : palette.divider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
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
                            ? palette.surfaceAlt
                            : accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        locked
                            ? Icons.lock_outline_rounded
                            : Icons.star_rounded,
                        color: locked ? palette.textMuted : accent,
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
                              ? palette.textMuted
                              : palette.textPrimary,
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
                        color: _expanded ? accent : palette.textMuted,
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
                        color: innerBlockColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.lesson.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.isDark
                                  ? Colors.white
                                  : palette.textPrimary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.lesson.practiceInfo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.isDark
                                  ? Colors.white
                                  : palette.textPrimary,
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
                                ? palette.surfaceAlt
                                : accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: locked
                                  ? palette.border
                                  : accent.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            locked ? 'LOCKED' : 'BEGIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: locked ? palette.textMuted : accent,
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