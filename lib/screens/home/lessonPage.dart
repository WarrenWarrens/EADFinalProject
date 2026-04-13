import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

  // ── Reference collection ──────────────────────────────────────────────────
  //
  // Walk every content item and pull out every dictionary `ref` it touches —
  // including refs nested inside exercises (audio_mimicry, listen_choose,
  // matching with `refs`, fill_in_blank with `answer`). Returns a unique
  // ordered set so the same word isn't fetched twice in one lesson.
  Set<String> _collectRefs() {
    final refs = <String>{};

    void addIfString(dynamic v) {
      if (v is String && v.trim().isNotEmpty) refs.add(v.trim());
    }

    for (final c in content) {
      final d = c.data;
      switch (c.type) {
        case 'word':
        case 'phrase':
          addIfString(d['ref']);
          // Phrase breakdown can also reference dictionary entries.
          final breakdown = d['breakdown'] as List<dynamic>?;
          if (breakdown != null) {
            for (final item in breakdown) {
              if (item is Map) addIfString(item['ref']);
            }
          }
          break;
        case 'exercise':
          final ex = d['exerciseType'] as String?;
          // Almost every exercise type carries `ref` (single) or `refs`
          // (list); handle both unconditionally.
          addIfString(d['ref']);
          final list = d['refs'] as List<dynamic>?;
          if (list != null) {
            for (final r in list) addIfString(r);
          }
          // Matching exercises sometimes use `pairs` with embedded refs.
          final pairs = d['pairs'] as List<dynamic>?;
          if (pairs != null) {
            for (final p in pairs) {
              if (p is Map) addIfString(p['ref']);
            }
          }
          // fill_in_blank stores its answer as a wordId.
          if (ex == 'fill_in_blank') addIfString(d['answer']);
          break;
        default:
          break;
      }
    }
    return refs;
  }

  /// Walk through the lesson's content and warm every cache we can before the
  /// user starts swiping through slides — so we don't hit a loading spinner
  /// between every step.
  ///
  /// Now covers:
  ///   • Dictionary lookups for every referenced word (word/phrase pages
  ///     AND every exercise type that references vocabulary).
  ///   • Audio download via DictionaryService (already triggered by the
  ///     lookup) PLUS an explicit prefetch into the just_audio pipeline so
  ///     the first tap on Listen plays without a cold-start delay.
  ///   • TTS engine warm-up if the lesson has character or any non-ref
  ///     audio that will fall back to TTS.
  Future<void> _preloadLessonAssets() async {
    final tasks = <Future<void> Function()>[];

    final hasCharacters = content.any((c) => c.type == 'character');
    if (hasCharacters) {
      tasks.add(() async {
        if (mounted) {
          setState(() => _preloadStatus = 'Warming up speech engine…');
        }
        try {
          await TtsService.warmUp();
        } catch (e) {
          debugPrint('[LessonPreload] TTS warm-up failed: $e');
        }
      });
    }

    final dict = DictionaryService();
    final refs = _collectRefs();

    // Phase 1 — dictionary lookups (which also pull audio file to disk).
    final lookupResults = <String, dynamic>{};
    for (final ref in refs) {
      tasks.add(() async {
        if (mounted) {
          setState(() => _preloadStatus = 'Loading "$ref"…');
        }
        try {
          final r = await dict.lookupWord(ref, AppLanguage.navi);
          lookupResults[ref] = r;
        } catch (e) {
          debugPrint('[LessonPreload] Lookup failed for "$ref": $e');
        }
      });
    }

    // Phase 2 — prime the audio pipeline for every word that has a
    // local clip on disk. setFilePath() forces just_audio to decode and
    // cache the file so the first real Listen tap is instant. We use a
    // single throwaway player for all words sequentially (cheap and avoids
    // the "too many open audio sessions" issue some Android builds hit).
    tasks.add(() async {
      if (refs.isEmpty) return;
      if (mounted) {
        setState(() => _preloadStatus = 'Caching audio…');
      }
      final player = AudioPlayer();
      try {
        for (final ref in refs) {
          final r = lookupResults[ref];
          if (r == null) continue;
          // Be tolerant of the dictionary result shape — it has an
          // `audio` list of objects with `localPath`.
          try {
            final audioList = (r as dynamic).audio as List?;
            if (audioList == null || audioList.isEmpty) continue;
            final localPath =
            (audioList.first as dynamic).localPath as String?;
            if (localPath == null || localPath.isEmpty) continue;
            // setFilePath returns a Duration once decoded; we don't play.
            await player.setFilePath(localPath);
          } catch (e) {
            // Single failure shouldn't block the rest.
            debugPrint('[LessonPreload] Audio prime failed for "$ref": $e');
          }
        }
      } finally {
        await player.dispose();
      }
    });

    // Always run the ring through a full sweep — even a lesson with no
    // network-dependent items gets a brief beat so the intro feels
    // consistent across all lessons.
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
    if (currentContentIndex < lessonLength + 1) {
      setState(() {
        currentContentIndex++;
      });
    }
  }

  Widget buildContentPage() {
    final contentObject =
    content.firstWhere((c) => c.id == currentContentIndex);

    Map<String, dynamic> dataAttrs = contentObject.data;

    switch (contentObject.type) {
      case 'text':
        return TextPage(
            key: ValueKey(contentObject.id),
            data: dataAttrs,
            onNext: nextSlide);
      case 'character':
        return CharacterPage(
            key: ValueKey(contentObject.id),
            data: dataAttrs,
            onNext: nextSlide);
      case 'word':
        return WordPage(
            key: ValueKey(contentObject.id),
            data: dataAttrs,
            onNext: nextSlide);
      case 'phrase':
        return PhrasePage(
            key: ValueKey(contentObject.id),
            data: dataAttrs,
            onNext: nextSlide);
      case 'exercise':
        return ExercisePage(
            key: ValueKey(contentObject.id),
            data: dataAttrs,
            onNext: nextSlide);
      default:
        return const Placeholder();
    }
  }

  double get progress {
    return currentContentIndex / (lessonLength + 1);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_preloading) {
      body = _LessonLoadingView(
        progress: _preloadTotal == 0 ? 0.0 : _preloadedCount / _preloadTotal,
        status: _preloadStatus,
      );
    } else if (currentContentIndex == 0) {
      body = LessonIntroPage(
        lesson: widget.lesson,
        onStart: nextSlide,
      );
    } else if (currentContentIndex == lessonLength + 1) {
      body = LessonCompletePage(
          lessonTitle: widget.lesson.title,
          onContinue: () {
            Navigator.pop(context);
          });
    } else {
      body = buildContentPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${widget.lesson.id} - ${widget.lesson.title}'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.primaryLight,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            )),
      ),
      body: body,
    );
  }
}

class LessonIntroPage extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onStart;

  const LessonIntroPage({
    super.key,
    required this.lesson,
    required this.onStart,
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
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lesson.objective,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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

  const LessonCompletePage({
    super.key,
    required this.lessonTitle,
    required this.onContinue,
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
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Lesson Complete!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  lessonTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Great job! You're one step closer to mastering the language.",
                  textAlign: TextAlign.center,
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

class _LessonLoadingView extends StatelessWidget {
  final double progress;
  final String status;

  const _LessonLoadingView({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final ringSize = shortest * 0.65;
        final size = ringSize.clamp(200.0, 360.0);
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
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: progress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          builder: (context, value, _) {
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
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

class _ArcProgressClipper extends CustomClipper<Path> {
  final double progress;
  _ArcProgressClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.0) return path;
    if (p >= 1.0) {
      path.addRect(Offset.zero & size);
      return path;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(
        math.pow(size.width, 2) + math.pow(size.height, 2)) /
        2 +
        1;
    final rect = Rect.fromCircle(center: center, radius: radius);
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