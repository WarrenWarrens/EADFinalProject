import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/lesson_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';

// ── Scoring config ──────────────────────────────────────────────────────────
// Paste your OpenAI API key here. Whisper transcription is called directly
// from the app — no backend needed.
const String kOpenAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';

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

  // ── Per-item state ─────────────────────────────────────────────────────────
  bool _isPlayingTTS = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  double? _score;
  String? _transcript;
  String _statusMessage = 'Tap the speaker to hear the pronunciation';

  // ── Scores across whole lesson ─────────────────────────────────────────────
  final Map<String, double> _scores = {};

  // ── Audio objects ──────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  String? _recordingPath;

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
        Tween<double>(begin: 1.0, end: 1.12).animate(_pulseController);
    _initRecorder();
    _loadItems();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
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
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ── TTS via TtsService ─────────────────────────────────────────────────────

  Future<void> _playTTS(VocabItem item) async {
    if (_isRecording) return;
    setState(() {
      _isPlayingTTS = true;
      _statusMessage = 'Fetching pronunciation…';
    });

    try {
      final path = await TtsService.getAudioFile(
        naviWord: item.navi,
        english: item.english,
        ttsHint: item.ttsHint,
      );

      if (path == null) {
        setState(() => _statusMessage = 'Could not load audio — check console');
        return;
      }

      setState(() => _statusMessage = 'Listen carefully…');
      await _player.setFilePath(path);
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
    _recordingPath = '${dir.path}/attempt_$_currentIndex.aac';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _hasRecorded = false;
      _score = null;
      _statusMessage = 'Recording… tap to stop';
    });
  }

  Future<void> _stopRecording(VocabItem item) async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _statusMessage = 'Scoring…';
    });
    await _scoreWithWhisper(item);
  }

  // ── Whisper + Levenshtein scoring ──────────────────────────────────────────
  //
  // 1. POST the audio directly to OpenAI Whisper API — no backend needed.
  // 2. Pass the target Na'vi word as a prompt so Whisper has phonetic context.
  // 3. Normalize both strings (lowercase, strip Na'vi diacritics).
  // 4. Score = 1 - (levenshteinDistance / maxLength), clamped to [0, 1].

  Future<void> _scoreWithWhisper(VocabItem item) async {
    if (_recordingPath == null) return;

    if (kOpenAiApiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      if (mounted) {
        setState(() {
          _score = 0.0;
          _hasRecorded = true;
          _statusMessage = 'Add your OpenAI key to kOpenAiApiKey to enable scoring';
        });
      }
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer $kOpenAiApiKey';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _recordingPath!,
        filename: 'attempt.aac',
      ));

      request.fields['model'] = 'whisper-1';
      request.fields['prompt'] = "The speaker is saying the Na'vi word: ${item.navi} (${item.ttsHint})";
      request.fields['response_format'] = 'text';

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final transcript = (await http.Response.fromStream(streamed)).body.trim();

      print('[Score] Whisper heard: "$transcript"');
      print('[Score] Target: "${item.navi}"');

      final score = _levenshteinScore(
        _normalizeNavi(transcript),
        _normalizeNavi(item.navi),
      );

      print('[Score] Score: ${(score * 100).round()}%');

      if (mounted) {
        setState(() {
          _score = score;
          _transcript = transcript.isNotEmpty ? transcript : null;
          _hasRecorded = true;
          _statusMessage = transcript.isNotEmpty
              ? 'Scoring complete'
              : 'Could not detect speech — try again';
        });
      }
    } catch (e) {
      print('[Score] Error: $e');
      if (mounted) {
        setState(() {
          _score = 0.0;
          _hasRecorded = true;
          _statusMessage = 'Scoring failed — check your API key and connection';
        });
      }
    }
  }

  // ── Scoring helpers ────────────────────────────────────────────────────────

  String _normalizeNavi(String s) {
    return s
        .toLowerCase()
        .replaceAll('ì', 'i')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ù', 'u')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAllMapped(RegExp(r"[^a-z' ]"), (_) => '')
        .trim();
  }

  double _levenshteinScore(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    final dist = _levenshtein(a, b);
    return (1.0 - dist / maxLen).clamp(0.0, 1.0);
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce((x, y) => x < y ? x : y);
        }
      }
    }
    return dp[m][n];
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _advance() {
    if (_score != null) _scores[_items[_currentIndex].id] = _score!;
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _isPlayingTTS = false;
        _isRecording = false;
        _hasRecorded = false;
        _score = null;
        _transcript = null;
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

  // ── Score colour helper ────────────────────────────────────────────────────

  Color _scoreColor(double s) {
    if (s >= 0.75) return const Color(0xFF4CAF50); // green
    if (s >= 0.5) return const Color(0xFFFFC107);  // amber
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No items available for this lesson.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final item = _items[_currentIndex];
    final progress = (_currentIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(widget.lesson.title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _ProgressRow(
                current: _currentIndex + 1,
                total: _items.length,
                progress: progress,
              ),
              const SizedBox(height: 24),
              _WordCard(item: item),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              _PlayButton(
                isPlaying: _isPlayingTTS,
                onTap: _isPlayingTTS || _isRecording
                    ? null
                    : () => _playTTS(item),
              ),
              const Spacer(),
              if (_score != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _ScoreBadge(
                    key: ValueKey(_score),
                    score: _score!,
                    color: _scoreColor(_score!),
                    label: _scoreLabel(_score!),
                  ),
                ),
              if (_hasRecorded) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOU SAID',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(
                        _transcript ?? 'No speech detected — add OpenAI key to kOpenAiApiKey',
                        style: TextStyle(
                            fontSize: _transcript != null ? 18 : 13,
                            fontWeight: FontWeight.w600,
                            color: _transcript != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
              if (_score != null) const SizedBox(height: 20),
              _RecordButton(
                isRecording: _isRecording,
                pulseAnimation: _pulseAnimation,
                onTap: _isPlayingTTS
                    ? null
                    : _isRecording
                    ? () => _stopRecording(item)
                    : _startRecording,
              ),
              const SizedBox(height: 24),
              _NextButton(
                isLast: _currentIndex == _items.length - 1,
                enabled: _hasRecorded,
                onTap: _advance,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int current;
  final int total;
  final double progress;
  const _ProgressRow(
      {required this.current, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$current / $total',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const Text('Audio Mimicry',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
      ],
    );
  }
}

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
      child: Column(
        children: [
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
        ],
      ),
    );
  }
}

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
          color: isPlaying ? AppColors.primaryLight : AppColors.buttonSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.volume_up : Icons.play_circle_outline,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isPlaying ? 'Playing…' : 'Hear pronunciation',
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

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;
  const _RecordButton(
      {required this.isRecording,
        required this.pulseAnimation,
        this.onTap});

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
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? AppColors.error : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: (isRecording ? AppColors.error : AppColors.primary)
                    .withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

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

class _NextButton extends StatelessWidget {
  final bool isLast;
  final bool enabled;
  final VoidCallback onTap;
  const _NextButton(
      {required this.isLast, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.primary : AppColors.buttonSoft,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}