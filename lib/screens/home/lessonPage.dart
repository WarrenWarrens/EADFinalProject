import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../screens/content/page_types.dart';
import '../../models/lessons.dart';
import '../../services/dictionary_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_language.dart';

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({super.key, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {

  int currentContentIndex = 0;
  late final List<Content> content = widget.lesson.content;
  late final int lessonLength = widget.lesson.content.length;

  // ── Preload state ─────────────────────────────────────────────────────────
  bool _preloading = true;
  int _preloadedCount = 0;
  int _preloadTotal = 0;
  String _preloadStatus = 'Preparing lesson…';

  @override
  void initState() {
    super.initState();
    _preloadLessonAssets();
  }

  /// Walk through the lesson's content and warm every cache we can before the
  /// user starts swiping through slides — so we don't hit a loading spinner
  /// between every step.
  ///
  /// Covers all lesson types:
  ///   • `word` / `phrase` — warms DictionaryService (dictionary lookup +
  ///     Reykunyu audio file on disk). Later WordPage/PhrasePage lookups hit
  ///     the warm cache and render effectively instantly.
  ///   • `character`       — warms the on-device TTS engine (has a cold-start
  ///     cost on first invocation).
  ///   • `text` / `exercise` — nothing to load, but still counts toward the
  ///     progress ring so every lesson gets a consistent intro.
  Future<void> _preloadLessonAssets() async {
    // Build a task list — one entry per content item that needs work, plus
    // one for the TTS engine warm-up if the lesson has any character slides.
    final tasks = <Future<void> Function()>[];

    final hasCharacters = content.any((c) => c.type == 'character');
    if (hasCharacters) {
      tasks.add(() async {
        if (mounted) setState(() => _preloadStatus = 'Warming up speech engine…');
        try {
          // Initialises FlutterTts (language/rate/pitch/volume) without
          // actually speaking — an empty speak() can leave the engine
          // stuck on some platforms.
          await TtsService.warmUp();
        } catch (e) {
          debugPrint('[LessonPreload] TTS warm-up failed: $e');
        }
      });
    }

    final dict = DictionaryService();
    for (final c in content) {
      if (c.type == 'word' || c.type == 'phrase') {
        final ref = (c.data['ref'] as String?)?.trim();
        if (ref == null || ref.isEmpty) continue;
        tasks.add(() async {
          if (mounted) {
            setState(() => _preloadStatus = 'Loading "$ref"…');
          }
          try {
            await dict.lookupWord(ref, AppLanguage.navi);
          } catch (e) {
            debugPrint('[LessonPreload] Failed for "$ref": $e');
          }
        });
      }
    }

    // Always run the ring through a full sweep — even a lesson with no
    // network-dependent items gets a brief "Preparing lesson…" beat so the
    // intro feels consistent across all lessons.
    if (tasks.isEmpty) {
      if (mounted) setState(() => _preloadTotal = 1);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _preloadedCount = 1;
          _preloading = false;
          _preloadStatus = 'Ready!';
        });
      }
      return;
    }

    if (mounted) setState(() => _preloadTotal = tasks.length);

    for (var i = 0; i < tasks.length; i++) {
      if (!mounted) return;
      await tasks[i]();
      if (mounted) setState(() => _preloadedCount = i + 1);
    }

    if (mounted) {
      setState(() {
        _preloading = false;
        _preloadStatus = 'Ready!';
      });
    }
  }



  void nextSlide() {
    if (currentContentIndex < lessonLength+1) {
      setState(() {
        currentContentIndex++;
      });
    }
  }

  void lastSlide() {
    if (currentContentIndex > 0) {
      setState(() {
        currentContentIndex--;
      });
    }
  }

  AppLanguage _getLanguageFromId(int id) {
    switch (id) {
      case 1:
        return AppLanguage.navi;
      case 2:
        return AppLanguage.klingon;
      case 3:
        return AppLanguage.highValyrian;
      default:
        return AppLanguage.navi; // Fallback
    }
  }

  Widget buildContentPage() {
    final contentObject = content.firstWhere((c) => c.id == currentContentIndex);


    Map<String, dynamic> dataAttrs = contentObject.data;


    switch (contentObject.type) {
      case 'text':
        return TextPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide, onLast: lastSlide);
        // return TextPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      case 'character':
        return CharacterPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide, onLast: lastSlide);
      case 'word':
        return WordPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide, onLast: lastSlide);
      case 'phrase':
        return PhrasePage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide, onLast: lastSlide);
      case 'exercise':
        return ExercisePage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide, onLast: lastSlide);
      default:
        return const Placeholder();
    }
  }

  double get progress{
    return currentContentIndex / (lessonLength+1);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    // 2. Convert the JSON languageId to the enum
    // final currentLanguage = _getLanguageFromId(widget.lesson.languageId);
    final currentLanguage = _getLanguageFromId(widget.lesson.languageId);
    // 3. Grab the correct accent color (Blue for Na'vi, Red for Klingon)
    // final accent = currentLanguage.accentColor;
    final accentColor = currentLanguage.accentColor;
    final accentLight = currentLanguage.accentLight;

    Widget body;

    if (_preloading) {
      body = _LessonLoadingView(
        progress: _preloadTotal == 0 ? 0.0 : _preloadedCount / _preloadTotal,
        status: _preloadStatus,
        palette: palette,
      );
    }

    else if (currentContentIndex == 0) {
      body = LessonIntroPage(
        lesson: widget.lesson,
        onStart: nextSlide,
        palette: palette,
        accentColor: accentColor,
        accentLight: accentLight,
      );
    }

    else if (currentContentIndex == lessonLength+1){
      body = LessonCompletePage(
        lessonTitle: widget.lesson.title,
        onContinue: (){
          Navigator.pop(
            context,
          );
        },
        palette: palette,
        accentColor: accentColor,
        accentLight: accentLight,
      );
    }

    else{

      body = buildContentPage();
    }

    return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: accentColor,
            primaryContainer: accentLight,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        child: Scaffold(
          // Switch the main background based on Dark/Light mode
          backgroundColor: palette.background,

          appBar: AppBar(
            // Match the AppBar background to the Scaffold
            backgroundColor: palette.background,
            elevation: 0, // Removes the drop shadow

            // Ensure the back button icon changes color in Dark/Light mode
            iconTheme: IconThemeData(color: palette.textPrimary),

            title: Text(
              'Lesson ${widget.lesson.id} - ${widget.lesson.title}',
              // Ensure the title text changes color in Dark/Light mode
              style: TextStyle(color: palette.textPrimary),
            ),

            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      // Use the soft background color (e.g., light red or light blue)
                      backgroundColor: accentLight,
                      // Use the strong accent color (e.g., solid red or solid blue)
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  ),
                )
            ),
          ),
          body: body, // Your existing body goes here!
        ));
  }
}

class LessonIntroPage extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onStart;
  final AppTheme palette;
  final Color accentColor;
  final Color accentLight;

  const LessonIntroPage({
    super.key,
    required this.lesson,
    required this.onStart,
    required this.palette,
    required this.accentColor,
    required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const SizedBox(height: 20),

          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            lesson.objective,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
            ),
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: onStart,
            child: const Text("Start Lesson"),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class LessonCompletePage extends StatelessWidget {
  final String lessonTitle;
  final VoidCallback onContinue;
  final AppTheme palette;
  final Color accentColor;
  final Color accentLight;

  const LessonCompletePage({
    super.key,
    required this.lessonTitle,
    required this.onContinue,
    required this.palette,
    required this.accentColor,
    required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 60,
                    color: accentColor,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  "Lesson Complete!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  lessonTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Text(
                  "Great job! You're one step closer to mastering the language.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              child: const Text("Back to Home"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
// ── Lesson Loading View ─────────────────────────────────────────────────────
//
// Shown while _preloadLessonAssets() warms dictionary + audio caches. Uses
// the rune-frame PNG as a progress ring — an arc sweeps around the circle
// in gold as items finish loading, with the owl mascot in the center.

class _LessonLoadingView extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final String status;
  final AppTheme palette;

  const _LessonLoadingView({required this.progress, required this.status, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the ring to the viewport so it looks right on a Pixel 2
        // (~411 logical px wide) and up through larger phones / tablets.
        // Never exceed 60% of the shorter axis so status text stays on-screen.
        final shortest = constraints.biggest.shortestSide;
        final ringSize = shortest * 0.65;
        // Clamp to a sensible range.
        final size = ringSize.clamp(200.0, 360.0);
        // Inset for the owl — keeps it clear of the rune ring at any size.
        final owlInset = size * 0.22;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // No dim base layer — the filling arc is the only ring
                      // visible, so progress reads unambiguously. The owl
                      // and status text provide visual anchoring.
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          builder: (context, value, _) {
                            // Clip the full runic image to a pie-wedge whose
                            // angle matches current progress. Explicit geometry
                            // via Path.arcTo — no gradient/tile mode quirks.
                            return ClipPath(
                              clipper: _ArcProgressClipper(value),
                              child: Image.asset(
                                'assets/images/magic_circle.png',
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                      // Owl mascot centered inside the ring.
                      Padding(
                        padding: EdgeInsets.all(owlInset),
                        child: Image.asset(
                          'assets/images/owl.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Constrain text width so long Na'vi words wrap instead of
                // pushing the layout off-screen on narrow devices.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.85,
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clips a rectangle to a pie-wedge starting at 12 o'clock and sweeping
/// clockwise through [progress] * 2π radians. Used to progressively reveal
/// the runic ring image as loading advances.
///
/// Built with explicit path geometry (moveTo center → arcTo with sweepAngle)
/// instead of SweepGradient stops, which have subtle platform-specific tile
/// behavior that can under-render the filled portion.
class _ArcProgressClipper extends CustomClipper<Path> {
  final double progress;
  _ArcProgressClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.0) return path; // fully clipped — show nothing
    if (p >= 1.0) {
      // Full circle — just return the whole rect so nothing is clipped.
      path.addRect(Offset.zero & size);
      return path;
    }
    final center = Offset(size.width / 2, size.height / 2);
    // Radius large enough to cover the entire rect from center, so the
    // pie edge always extends past the image bounds and the clip is tight
    // against the ring itself rather than a visible wedge line.
    final radius = math.sqrt(
        math.pow(size.width, 2) + math.pow(size.height, 2)) /
        2 +
        1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Flutter angles: 0 = 3 o'clock, +π/2 = 6 o'clock (clockwise on screen).
    // Start at -π/2 (12 o'clock); sweep clockwise by progress * 2π.
    const startAngle = -math.pi / 2;
    final sweepAngle = p * 2 * math.pi;
    path.moveTo(center.dx, center.dy);
    path.arcTo(rect, startAngle, sweepAngle, false);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ArcProgressClipper old) =>
      old.progress != progress;
}

AppLanguage _getLanguageFromId(int id) {
  switch (id) {
    case 1:
      return AppLanguage.navi;
    case 2:
      return AppLanguage.klingon;
    case 3: // If you add it later!
      return AppLanguage.highValyrian;
    default:
      return AppLanguage.navi;
  }
}