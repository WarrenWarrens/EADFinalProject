import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../models/lesson_model.dart';
import '../../services/volume_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/tts_service.dart';
import '../../services/audio_analysis_service.dart';
import '../../services/vocab_tracking_service.dart';
import '../../theme/app_theme.dart';

// Maximum recording duration before auto-stop.
const int kMaxRecordingSeconds = 20;

class AudioMimicryScreen extends StatefulWidget {
  final Lesson lesson;
  const AudioMimicryScreen({super.key, required this.lesson});

  @override
  State<AudioMimicryScreen> createState() => _AudioMimicryScreenState();
}

class _AudioMimicryScreenState extends State<AudioMimicryScreen>
    with SingleTickerProviderStateMixin {

  // ── Items ──────────────────────────────────────────────────────────────────
  List<VocabItem> _items = [];
  int _currentIndex = 0;
  bool _loadingProfile = true;
  bool _showingIntro = true;

  // ── Per-item state ─────────────────────────────────────────────────────────
  bool _isPlayingTTS = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  double? _score;
  String? _feedback;
  String _statusMessage = 'Tap the speaker to hear the pronunciation';

  // ── Segment scores for visual feedback ─────────────────────────────────────
  List<double> _segmentScores = [];

  // ── Scores across whole lesson ─────────────────────────────────────────────
  final Map<String, double> _scores = {};
  final VocabTrackingService _tracker = VocabTrackingService();

  // ── Audio ──────────────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  String? _recordingPath;
  String? _ttsPath;   // path of the last TTS file played — used for comparison

  // ── Reference WAV path ─────────────────────────────────────────────────────
  String? _referenceWavPath;

  // ── Pre-loaded audio cache ─────────────────────────────────────────────────
  // vocabId → playback mp3/audio path
  final Map<String, String> _audioCache = {};
  // vocabId → reference WAV path (for scoring comparison)
  final Map<String, String> _wavCache = {};
  int _preloadedCount = 0;
  bool _preloadDone = false;
  String _preloadStatus = 'Preparing audio…';

  // ── Waveform ───────────────────────────────────────────────────────────────
  final List<double> _waveformSamples = [];
  StreamSubscription<RecordingDisposition>? _recorderSub;

  // ── Recording countdown ────────────────────────────────────────────────────
  Timer? _recordingTimer;
  int _recordingSecondsLeft = kMaxRecordingSeconds;

  // ── Pulse animation ────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.08).animate(_pulseController);
    _initRecorder();
    _loadItems();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 60));
    if (mounted) setState(() => _recorderReady = true);
  }

  Future<void> _loadItems() async {
    final storage = LocalStorageService();
    final profile = await storage.loadProfile();
    if (mounted) {
      setState(() {
        _items = widget.lesson.itemsForGoal(profile?.learningGoal);
        _loadingProfile = false;
      });
      // Start pre-loading all audio in background
      _preloadAllAudio();
    }
  }

  // ── Pre-load all audio ─────────────────────────────────────────────────────
  //
  // Fetches audio for every vocab item at lesson start.
  // Single words: standard TTS fetch.
  // Multi-word phrases: fetch each word separately, concatenate with FFmpeg.
  // Stores both playback path and converted WAV for comparison.

  Future<void> _preloadAllAudio() async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!mounted) return;

      setState(() {
        _preloadStatus = 'Loading "${item.navi}" (${i + 1}/${_items.length})…';
      });

      try {
        final naviWords = item.navi.trim().split(RegExp(r'\s+'));

        String? audioPath;

        if (naviWords.length == 1) {
          // ── Single word — use standard fetch ──────────────────────────
          audioPath = await TtsService.getAudioFile(
            naviWord: item.navi,
            english: item.english,
            ttsHint: item.ttsHint,
          );
        } else {
          // ── Multi-word phrase — fetch each word, then concatenate ─────
          audioPath = await _fetchAndConcatenateWords(item, naviWords);
        }

        if (audioPath != null && mounted) {
          _audioCache[item.id] = audioPath;

          // Convert to WAV for comparison
          final wavPath = await _convertToWav(audioPath, i);
          if (wavPath != null) {
            _wavCache[item.id] = wavPath;
          }
        }
      } catch (e) {
        print('[Preload] Error for "${item.navi}": $e');
      }

      if (mounted) {
        setState(() => _preloadedCount = i + 1);
      }
    }

    if (mounted) {
      setState(() {
        _preloadDone = true;
        _preloadStatus = 'All audio ready!';
      });
      print('[Preload] Done — cached ${_audioCache.length}/${_items.length} items');
    }
  }

  // ── Fetch each word in a phrase and concatenate ────────────────────────────
  //
  // Splits the Na'vi phrase and ttsHint by whitespace so each word gets its
  // own API call. The resulting audio clips are concatenated into a single
  // file using FFmpeg's concat filter.

  Future<String?> _fetchAndConcatenateWords(
      VocabItem item, List<String> naviWords) async {
    final hintWords = item.ttsHint.trim().split(RegExp(r'\s+'));
    final wordPaths = <String>[];

    for (var w = 0; w < naviWords.length; w++) {
      final word = naviWords[w];
      // Use matching ttsHint word if available, otherwise the Na'vi word itself
      final hint = w < hintWords.length ? hintWords[w] : word;

      final path = await TtsService.getSingleWordAudio(
        naviWord: word,
        ttsHint: hint,
      );

      if (path != null) {
        wordPaths.add(path);
      } else {
        print('[Preload] Could not get audio for word "$word" in "${item.navi}"');
      }
    }

    if (wordPaths.isEmpty) return null;
    if (wordPaths.length == 1) return wordPaths.first;

    // ── Concatenate with FFmpeg ────────────────────────────────────────────
    return _concatenateAudioFiles(wordPaths, item.id);
  }

  Future<String?> _concatenateAudioFiles(
      List<String> paths, String itemId) async {
    try {
      final dir = await getTemporaryDirectory();

      // Write an FFmpeg concat list file
      final listPath = '${dir.path}/concat_${itemId}.txt';
      final listContent =
          paths.map((p) => "file '$p'").join('\n');
      await File(listPath).writeAsString(listContent);

      final outputPath = '${dir.path}/phrase_${itemId}.mp3';

      final session = await FFmpegKit.execute(
        '-y -f concat -safe 0 -i "$listPath" -c copy "$outputPath"',
      );

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        print('[Preload] Concatenated ${paths.length} clips → $outputPath');
        return outputPath;
      } else {
        // If -c copy fails (different codecs), re-encode
        final session2 = await FFmpegKit.execute(
          '-y -f concat -safe 0 -i "$listPath" -ar 22050 -ac 1 "$outputPath"',
        );
        final rc2 = await session2.getReturnCode();
        if (ReturnCode.isSuccess(rc2)) {
          print('[Preload] Concatenated (re-encoded) ${paths.length} clips → $outputPath');
          return outputPath;
        }
        final logs = await session2.getLogsAsString();
        print('[Preload] FFmpeg concat failed: $logs');
        return paths.first; // fallback to first word
      }
    } catch (e) {
      print('[Preload] Concat error: $e');
      return paths.first;
    }
  }

  // ── WAV conversion (shared helper) ─────────────────────────────────────────

  Future<String?> _convertToWav(String sourcePath, int index) async {
    try {
      if (sourcePath.toLowerCase().endsWith('.wav')) return sourcePath;

      final dir = await getTemporaryDirectory();
      final wavPath = '${dir.path}/ref_${index}.wav';

      final session = await FFmpegKit.execute(
        '-y -i "$sourcePath" -ar 16000 -ac 1 -sample_fmt s16 "$wavPath"',
      );

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) return wavPath;

      print('[Preload] WAV conversion failed for index $index');
      return sourcePath;
    } catch (e) {
      print('[Preload] WAV conversion error: $e');
      return sourcePath;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.dispose();
    _recorder.closeRecorder();
    _recorderSub?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _playTTS(VocabItem item) async {
    if (_isRecording) return;

    // Check cache first
    final cachedPath = _audioCache[item.id];
    if (cachedPath == null) {
      setState(() => _statusMessage = 'Audio not loaded yet — please wait');
      return;
    }

    setState(() {
      _isPlayingTTS = true;
      _statusMessage = 'Listen carefully…';
    });

    try {
      _ttsPath = cachedPath;
      _referenceWavPath = _wavCache[item.id];

      await _player.setFilePath(cachedPath);
      await _player.setVolume(VolumeService().voiceVolume);
      await _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed);

    } catch (e) {
      setState(() => _statusMessage = 'Playback error: $e');
    } finally {
      if (mounted) setState(() => _isPlayingTTS = false);
    }
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_recorderReady) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone not ready')));
      return;
    }

    final dir = await getTemporaryDirectory();
    // Record as 16-bit PCM WAV for direct analysis (no codec conversion needed)
    _recordingPath = '${dir.path}/attempt_$_currentIndex.wav';

    _waveformSamples.clear();

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.pcm16WAV,       // ← WAV instead of AAC
      sampleRate: 16000,            // 16kHz mono — matches our MFCC pipeline
      numChannels: 1,
    );

    _recorderSub = _recorder.onProgress!.listen((e) {
      if (e.decibels != null && mounted) {
        final normalised = ((e.decibels! + 60.0) / 60.0).clamp(0.0, 1.0);
        setState(() => _waveformSamples.add(normalised));
      }
    });

    _recordingSecondsLeft = kMaxRecordingSeconds;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _recordingSecondsLeft--);
      if (_recordingSecondsLeft <= 0) {
        t.cancel();
        _stopRecording(_items[_currentIndex]);
      }
    });

    setState(() {
      _isRecording = true;
      _hasRecorded = false;
      _score = null;
      _feedback = null;
      _segmentScores = [];
      _statusMessage = 'Recording\u2026 tap to stop';
    });
  }

  Future<void> _stopRecording(VocabItem item) async {
    _recordingTimer?.cancel();
    _recorderSub?.cancel();
    _recorderSub = null;

    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _statusMessage = 'Analysing\u2026';
    });
    await _scoreLocally(item);
  }

  // ── Local MFCC + DTW scoring ──────────────────────────────────────────────
  //
  // Compares the user's WAV recording against the reference TTS WAV using
  // MFCC feature extraction and Dynamic Time Warping. Fully offline.

  Future<void> _scoreLocally(VocabItem item) async {
    if (_recordingPath == null) return;

    // Check that we have a reference to compare against
    if (_referenceWavPath == null || !await File(_referenceWavPath!).exists()) {
      if (mounted) {
        setState(() {
          _score = null;
          _hasRecorded = true;
          _feedback = null;
          _statusMessage = 'Play the reference audio first, then record';
        });
      }
      return;
    }

    try {
      final result = await AudioAnalysisService.compare(
        referencePath: _referenceWavPath!,
        attemptPath: _recordingPath!,
      );

      if (mounted) {
        setState(() {
          _score = result.score;
          _feedback = result.feedback;
          _segmentScores = result.segmentScores;
          _hasRecorded = true;
          _statusMessage = result.feedback;
        });
      }
    } catch (e) {
      print('[Score] Local analysis error: $e');
      if (mounted) {
        setState(() {
          _score = 0.0;
          _hasRecorded = true;
          _statusMessage = 'Analysis failed \u2014 try recording again';
        });
      }
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _advance() {
    final item = _items[_currentIndex];
    if (_score != null) {
      _scores[item.id] = _score!;
      _tracker.recordAttempt(
        wordId: item.id,
        displayText: item.navi,
        score: _score!,
        source: 'audio_mimicry',
      );
    }
    if (_currentIndex < _items.length - 1) {
      final nextIndex = _currentIndex + 1;
      final nextItem = _items[nextIndex];
      setState(() {
        _currentIndex = nextIndex;
        _isPlayingTTS = false;
        _isRecording = false;
        _hasRecorded = false;
        _score = null;
        _feedback = null;
        // Load references from cache for the next item
        _ttsPath = _audioCache[nextItem.id];
        _referenceWavPath = _wavCache[nextItem.id];
        _segmentScores = [];
        _waveformSamples.clear();
        _recordingSecondsLeft = kMaxRecordingSeconds;
        _statusMessage = 'Tap the speaker to hear the pronunciation';
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final total = _scores.values.fold(0.0, (a, b) => a + b);
    final avg = _scores.isEmpty ? 0.0 : total / _scores.length;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lesson complete!',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(avg * 100).round()}%',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Average score across ${_items.length} words',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _scoreColor(double s) {
    if (s >= 0.75) return AppColors.success;
    if (s >= 0.50) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel(double s) {
    if (s >= 0.85) return 'Excellent!';
    if (s >= 0.70) return 'Good';
    if (s >= 0.50) return 'Keep practising';
    return 'Try again';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No items available for this lesson.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // ── Intro screen ─────────────────────────────────────────────────────────
    if (_showingIntro) {
      final preloadProgress = _items.isNotEmpty
          ? _preloadedCount / _items.length
          : 0.0;

      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  widget.lesson.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.lesson.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_items.length} words',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Preload progress ─────────────────────────────────
                if (!_preloadDone) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: preloadProgress,
                            minHeight: 6,
                            backgroundColor: AppColors.buttonSoft,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _preloadStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Audio ready!',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _preloadDone
                        ? () {
                            if (_items.isNotEmpty) {
                              final first = _items.first;
                              _ttsPath = _audioCache[first.id];
                              _referenceWavPath = _wavCache[first.id];
                            }
                            setState(() => _showingIntro = false);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _preloadDone
                          ? AppColors.primary
                          : AppColors.inputBorder,
                      foregroundColor: _preloadDone
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    child: Text(_preloadDone
                        ? 'Start Lesson'
                        : 'Loading audio… (${_preloadedCount}/${_items.length})'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    // ── Main lesson UI ───────────────────────────────────────────────────────
    final item = _items[_currentIndex];
    final progress = (_currentIndex + 1) / _items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: _ProgressRow(
              current: _currentIndex + 1,
              total: _items.length,
              progress: progress,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RecordButton(
                isRecording: _isRecording,
                pulseAnimation: _pulseAnimation,
                secondsLeft: _isRecording ? _recordingSecondsLeft : null,
                onTap: _isPlayingTTS
                    ? null
                    : _isRecording
                    ? () => _stopRecording(item)
                    : _startRecording,
              ),
              const SizedBox(height: 16),
              _NextButton(
                isLast: _currentIndex == _items.length - 1,
                enabled: _hasRecorded,
                onTap: _advance,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _WordCard(item: item),
              const SizedBox(height: 20),

              // Status / feedback message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _feedback != null
                    ? Container(
                  key: ValueKey(_feedback),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedback!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary),
                  ),
                )
                    : Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              _PlayButton(
                isPlaying: _isPlayingTTS,
                onTap: _isPlayingTTS || _isRecording
                    ? null
                    : () => _playTTS(item),
              ),
              const SizedBox(height: 28),

              // Waveform
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: _waveformSamples.isNotEmpty
                    ? Column(children: [
                  _WaveformDisplay(
                    samples: List.unmodifiable(_waveformSamples),
                    isRecording: _isRecording,
                    scoreColor:
                    _score != null ? _scoreColor(_score!) : null,
                  ),
                  const SizedBox(height: 20),
                ])
                    : const SizedBox.shrink(),
              ),

              // Score badge
              if (_score != null) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _ScoreBadge(
                    key: ValueKey(_score),
                    score: _score!,
                    color: _scoreColor(_score!),
                    label: _scoreLabel(_score!),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Segment score bars (replaces the old phoneme compare card)
              if (_hasRecorded && _segmentScores.isNotEmpty) ...[
                _SegmentScoreCard(
                  segments: _segmentScores,
                  targetNavi: item.navi,
                  targetIpa: item.ipa,
                ),
                const SizedBox(height: 16),
              ],

              // Prompt to play reference first if they haven't
              if (_hasRecorded && _referenceWavPath == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Tip: Play the reference pronunciation first, then record '
                        'your attempt for accurate scoring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

// ── Progress row ──────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int current, total;
  final double progress;
  const _ProgressRow(
      {required this.current,
        required this.total,
        required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$current / $total',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const Text('Audio Mimicry',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.buttonSoft,
          color: AppColors.primary,
        ),
      ),
    ]);
  }
}

// ── Word card ─────────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final VocabItem item;
  const _WordCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Text(item.navi,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(item.ipa,
            style: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        const Divider(color: AppColors.inputBorder),
        const SizedBox(height: 12),
        Text(item.english,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400)),
      ]),
    );
  }
}

// ── Play button ───────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onTap;
  const _PlayButton({required this.isPlaying, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.primaryLight
              : AppColors.buttonSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying
                  ? Icons.volume_up
                  : Icons.play_circle_outline,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isPlaying ? 'Playing\u2026' : 'Hear pronunciation',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waveform display ──────────────────────────────────────────────────────────

class _WaveformDisplay extends StatelessWidget {
  final List<double> samples;
  final bool isRecording;
  final Color? scoreColor;

  const _WaveformDisplay({
    required this.samples,
    required this.isRecording,
    this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final barColour = isRecording
        ? AppColors.primary
        : (scoreColor ?? AppColors.textSecondary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecording
              ? AppColors.primary.withOpacity(0.45)
              : AppColors.inputBorder,
          width: isRecording ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CustomPaint(
          painter: _WaveformPainter(samples: samples, color: barColour),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;

  const _WaveformPainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.82)
      ..style = PaintingStyle.fill;

    final barWidth = (size.width / samples.length).clamp(1.5, 8.0);
    final gap = barWidth * 0.28;
    final effectiveBar = barWidth - gap;
    final centerY = size.height / 2;
    final maxAmp = size.height * 0.46;

    for (var i = 0; i < samples.length; i++) {
      final x = i * barWidth;
      final amp = (samples[i] * maxAmp).clamp(2.5, maxAmp);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + effectiveBar / 2, centerY),
            width: effectiveBar,
            height: amp * 2,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.samples.length != samples.length || old.color != color;
}

// ── Score badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  final String label;
  const _ScoreBadge(
      {super.key,
        required this.score,
        required this.color,
        required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(width: 12),
          Text('${(score * 100).round()}%',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Segment score card ────────────────────────────────────────────────────────
//
// Replaces the old phoneme compare card. Shows a horizontal bar chart with
// ~5 segments representing different parts of the word, each coloured by
// how closely that segment matched the reference.

class _SegmentScoreCard extends StatelessWidget {
  final List<double> segments;
  final String targetNavi;
  final String targetIpa;

  const _SegmentScoreCard({
    required this.segments,
    required this.targetNavi,
    required this.targetIpa,
  });

  Color _barColor(double s) {
    if (s >= 0.75) return AppColors.success;
    if (s >= 0.50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Pronunciation Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            targetIpa,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),

          // Segment bars
          Row(
            children: List.generate(segments.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < segments.length - 1 ? 4.0 : 0.0,
                  ),
                  child: Column(
                    children: [
                      // Score percentage
                      Text(
                        '${(segments[i] * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _barColor(segments[i]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Bar
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _barColor(segments[i]).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: segments[i].clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _barColor(segments[i]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // Legend
          const Row(children: [
            _LegendDot(color: AppColors.success, label: 'Good match'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.warning, label: 'Close'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.error, label: 'Needs work'),
          ]),
        ],
      ),
    );
  }
}

// ── Legend dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Record button ─────────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final Animation<double> pulseAnimation;
  final int? secondsLeft;
  final VoidCallback? onTap;

  const _RecordButton({
    required this.isRecording,
    required this.pulseAnimation,
    required this.secondsLeft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: isRecording ? pulseAnimation.value : 1.0,
          child: child,
        ),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording && secondsLeft != null)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: secondsLeft! / kMaxRecordingSeconds,
                    strokeWidth: 3.5,
                    backgroundColor:
                    AppColors.error.withOpacity(0.15),
                    color: secondsLeft! <= 5
                        ? AppColors.warning
                        : AppColors.error,
                  ),
                ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? AppColors.error
                      : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording
                          ? AppColors.error
                          : AppColors.primary)
                          .withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: isRecording && secondsLeft != null
                    ? Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stop,
                        color: Colors.white, size: 28),
                    const SizedBox(height: 2),
                    Text(
                      '${secondsLeft}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
                    : Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Next / results button ─────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast, enabled;
  final VoidCallback onTap;
  const _NextButton(
      {required this.isLast,
        required this.enabled,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          enabled ? AppColors.primary : AppColors.buttonSoft,
          foregroundColor:
          enabled ? Colors.white : AppColors.textSecondary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
          elevation: 0,
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          isLast ? 'See Results' : 'Next',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}