import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
// Paste your Gemini API key here. Get one free at aistudio.google.com.
// Transcription is called directly from the app — no backend needed.
const String kGeminiApiKey = 'AIzaSyCb7E17Cl0Rg34iSZUMp8VCN_KgHQHOzT8';

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

  // ── Per-item state ─────────────────────────────────────────────────────────
  bool _isPlayingTTS = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  double? _score;
  String? _transcript;
  String? _feedback;
  String _statusMessage = 'Tap the speaker to hear the pronunciation';

  // ── Scores across whole lesson ─────────────────────────────────────────────
  final Map<String, double> _scores = {};

  // ── Audio ──────────────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  String? _recordingPath;
  String? _ttsPath;   // path of the last TTS file played — sent to Gemini for comparison

  // ── Waveform ───────────────────────────────────────────────────────────────
  // Amplitude samples (0.0–1.0) collected live during recording.
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
    // Emit amplitude updates every 60 ms for a smooth waveform.
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
    setState(() {
      _isPlayingTTS = true;
      _statusMessage = 'Fetching pronunciation\u2026';
    });

    try {
      final path = await TtsService.getAudioFile(
        naviWord: item.navi,
        english: item.english,
        ttsHint: item.ttsHint,
      );

      if (path == null) {
        setState(() => _statusMessage = 'Could not load audio \u2014 check console');
        return;
      }

      _ttsPath = path;  // keep for Gemini comparison

      setState(() => _statusMessage = 'Listen carefully\u2026');
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

    _waveformSamples.clear();

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );

    // Collect amplitude samples from the recorder's progress stream.
    // dBFS range is roughly –60..0; we map it to 0..1 for the painter.
    _recorderSub = _recorder.onProgress!.listen((e) {
      if (e.decibels != null && mounted) {
        final normalised = ((e.decibels! + 60.0) / 60.0).clamp(0.0, 1.0);
        setState(() => _waveformSamples.add(normalised));
      }
    });

    // 20-second hard limit with a countdown shown on the record button.
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
      _transcript = null;
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
      _statusMessage = 'Scoring\u2026';
    });
    await _scoreWithGemini(item);
  }

  // ── Gemini dual-audio phonetic comparison ─────────────────────────────────
  //
  // Sends two audio clips to Gemini in a single request:
  //   Clip 1 — the reference TTS (correct pronunciation)
  //   Clip 2 — the user's recorded attempt
  //
  // Gemini is asked to compare them purely on phonetic/acoustic similarity
  // and return a structured JSON response.  The score (0.0–1.0) comes
  // entirely from Gemini's acoustic judgment — no Levenshtein involved.
  // The "heard" field is used only to drive the pill display in the UI.
  //
  // If no TTS has been played yet (ttsPath is null), falls back to
  // transcription-only mode with a prompt explaining the target word.

  Future<void> _scoreWithGemini(VocabItem item) async {
    if (_recordingPath == null) return;

    if (kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      if (mounted) {
        setState(() {
          _score = 0.0;
          _hasRecorded = true;
          _transcript = null;
          _statusMessage = 'Add your Gemini key to kGeminiApiKey to enable scoring';
        });
      }
      return;
    }

    try {
      final userBytes = await File(_recordingPath!).readAsBytes();
      final userB64   = base64Encode(userBytes);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
            'gemini-2.5-flash-lite:generateContent?key=$kGeminiApiKey',
      );

      List<Map<String, dynamic>> parts;

      if (_ttsPath != null) {
        // ── Two-audio mode: compare user against reference ─────────────────
        final ttsBytes = await File(_ttsPath!).readAsBytes();
        final ttsB64   = base64Encode(ttsBytes);
        final ttsMime  = _ttsPath!.endsWith('.mp3') ? 'audio/mp3' : 'audio/aac';

        parts = [
          {
            'inline_data': {'mime_type': ttsMime, 'data': ttsB64},
          },
          {
            'inline_data': {'mime_type': 'audio/aac', 'data': userB64},
          },
          {
            'text': '''You are a strict phonetics evaluator for a language-learning app.

You have been given two audio clips:
  Clip 1: the correct reference pronunciation of a Na'vi word.
  Clip 2: a learner's attempt to say the same word.

Your task:
1. Listen carefully to BOTH clips.
2. Compare them on phonetic accuracy only — vowel sounds, consonant sounds, stress placement, and syllable rhythm. Ignore recording quality, background noise, volume differences, and accent unrelated to Na'vi phonology.
3. Assign a similarity score from 0.0 (completely different sounds) to 1.0 (phonetically identical).
4. Write one short sentence (max 10 words) describing the most significant phonetic difference, or "Great match" if the score is above 0.85.
5. Write what you heard in Clip 2 using plain Latin characters.

Respond with ONLY a raw JSON object — no markdown, no code fences, no explanation:
{"score": <float>, "heard": "<what you heard in clip 2>", "feedback": "<one sentence>"}''',
          },
        ];
      } else {
        // ── Single-audio fallback: transcribe and score against target ──────
        parts = [
          {
            'inline_data': {'mime_type': 'audio/aac', 'data': userB64},
          },
          {
            'text': '''You are a strict phonetics evaluator for a language-learning app.

The learner is attempting to say the Na'vi word "${item.navi}" (IPA: ${item.ipa}, pronounced roughly: ${item.ttsHint}).

Listen to the audio and:
1. Transcribe exactly what you hear using plain Latin characters.
2. Score how phonetically close it is to the target pronunciation: 0.0 = completely wrong, 1.0 = perfect.
3. Write one short sentence (max 10 words) on the biggest phonetic difference, or "Great match" if above 0.85.

Respond with ONLY a raw JSON object — no markdown, no code fences, no explanation:
{"score": <float>, "heard": "<transcription>", "feedback": "<one sentence>"}''',
          },
        ];
      }

      final body = jsonEncode({
        'contents': [
          {'parts': parts},
        ],
      });

      final response = await http
          .post(url,
          headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 40));

      // ── Handle API errors ────────────────────────────────────────────────
      if (response.statusCode != 200) {
        String userMessage;
        switch (response.statusCode) {
          case 429:
            userMessage = 'Gemini quota exceeded — check aistudio.google.com';
          case 400:
            userMessage = 'Gemini bad request — check audio format or API key';
          case 403:
            userMessage = 'Invalid Gemini API key — check kGeminiApiKey';
          default:
            userMessage = 'Gemini API error ${response.statusCode} — check console';
        }
        print('[Score] Gemini HTTP ${response.statusCode}: ${response.body}');
        if (mounted) {
          setState(() {
            _score = null;
            _transcript = null;
            _hasRecorded = true;
            _statusMessage = userMessage;
          });
        }
        return;
      }

      // ── Parse JSON response ──────────────────────────────────────────────
      final responseJson = jsonDecode(response.body);
      final rawText = (responseJson['candidates']?[0]?['content']?['parts']
      ?[0]?['text'] as String? ??
          '')
          .trim()
      // Strip markdown code fences if Gemini ignores our instruction
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      print('[Score] Gemini raw: $rawText');

      double score = 0.0;
      String heard = '';
      String feedback = '';

      try {
        final parsed = jsonDecode(rawText) as Map<String, dynamic>;
        score    = (parsed['score'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
        heard    = (parsed['heard']    as String? ?? '').trim();
        feedback = (parsed['feedback'] as String? ?? '').trim();
      } catch (_) {
        print('[Score] Failed to parse Gemini JSON: $rawText');
        feedback = 'Could not parse response — try again';
      }

      print('[Score] Score: ${(score * 100).round()}%  heard: "$heard"  feedback: "$feedback"');

      if (mounted) {
        setState(() {
          _score       = score;
          _transcript  = heard.isNotEmpty ? heard : null;
          _feedback    = feedback.isNotEmpty ? feedback : null;
          _hasRecorded = true;
          _statusMessage = feedback.isNotEmpty ? feedback : 'Scoring complete';
        });
      }
    } catch (e) {
      print('[Score] Error: $e');
      if (mounted) {
        setState(() {
          _score         = 0.0;
          _hasRecorded   = true;
          _statusMessage = 'Scoring failed \u2014 check your API key and connection';
        });
      }
    }
  }

  // ── Phonetic normalisation ─────────────────────────────────────────────────
  //
  // Both the Na'vi target word and the Whisper transcript pass through this
  // function before scoring or diffing.  The goal is to collapse systematic
  // differences that don't reflect real mispronunciation:
  //
  //  • Diacritics:   ì→i  ä→a  é→e  ù→u  (Na'vi vowels with length/tone marks)
  //  • Ejectives:    tx→t  px→p  kx→k     (Na'vi ejective digraphs)
  //  • Digraphs:     ts→s  ng→n           (rarely survive Whisper transcription)
  //  • English subs: ee→i  ah→a  sh→s     (common Whisper English approximations)
  //  • Curly quotes: '→'

  String _normalisePhonetic(String s) {
    return s
        .toLowerCase()
    // Na'vi diacritics
        .replaceAll('ì', 'i')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ù', 'u')
        .replaceAll('ö', 'o')
    // Curly apostrophes
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
    // Na'vi ejective digraphs → base consonant
        .replaceAll('tx', 't')
        .replaceAll('px', 'p')
        .replaceAll('kx', 'k')
    // Na'vi / Whisper digraphs
        .replaceAll('ts', 's')
        .replaceAll('ng', 'n')
    // Common Whisper English phonetic approximations of Na'vi sounds
        .replaceAll('tch', 't')
        .replaceAll('ch',  's')
        .replaceAll('sh',  's')
        .replaceAll('ee',  'i')
        .replaceAll('ah',  'a')
        .replaceAll('oh',  'o')
        .replaceAll('ck',  'k')
    // Strip anything that isn't a basic latin letter or space
        .replaceAllMapped(RegExp(r"[^a-z ]"), (_) => '')
    // Collapse runs of spaces
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  // ── Levenshtein score + distance ───────────────────────────────────────────

  double _levenshteinScore(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    return (1.0 - _levenshtein(a, b) / maxLen).clamp(0.0, 1.0);
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
            .reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[m][n];
  }

  // ── Aligned diff ───────────────────────────────────────────────────────────
  //
  // Returns a list of (char, isMatch) for every character in [target].
  // We traceback through the Levenshtein DP matrix and annotate each TARGET
  // character as matched (green) or wrong/missing (red).
  // Extra characters in [heard] that have no equivalent in [target] are
  // silently skipped — they'd only clutter the display.

  List<(String, bool)> _alignedDiff(String target, String heard) {
    if (target.isEmpty) return [];
    if (heard.isEmpty) {
      return [for (final c in target.characters) (c, false)];
    }

    final m = target.length, n = heard.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = target[i - 1] == heard[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
            .reduce((x, y) => x < y ? x : y);
      }
    }

    final result = <(String, bool)>[];
    var i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && target[i - 1] == heard[j - 1]) {
        // Match
        result.add((target[i - 1], true));
        i--; j--;
      } else if (i > 0 && j > 0 &&
          dp[i - 1][j - 1] <= dp[i - 1][j] &&
          dp[i - 1][j - 1] <= dp[i][j - 1]) {
        // Substitution — target char heard incorrectly
        result.add((target[i - 1], false));
        i--; j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] <= dp[i - 1][j])) {
        // Insertion in heard — extra char, skip
        j--;
      } else {
        // Deletion — target char not heard at all
        result.add((target[i - 1], false));
        i--;
      }
    }
    return result.reversed.toList();
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
        _feedback = null;
        _ttsPath = null;
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
    if (s >= 0.75) return const Color(0xFF4CAF50);
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

    final item = _items[_currentIndex];
    final progress = (_currentIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── Fixed header: title + progress bar ──────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(widget.lesson.title,
            style: const TextStyle(
                color: AppColors.textPrimary,
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
      // ── Fixed bottom: mic + next ─────────────────────────────────────────────
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
      // ── Scrollable middle ────────────────────────────────────────────────────
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

              // Waveform — expands in when samples start arriving.
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

              // Phoneme compare card
              if (_hasRecorded) ...[
                _PhonemeCompareCard(
                  targetNavi: item.navi,
                  targetIpa: item.ipa,
                  transcript: _transcript,
                  score: _score,
                  normalisePhonetic: _normalisePhonetic,
                  alignedDiff: _alignedDiff,
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
//
// Renders a live bar-chart waveform during recording using amplitude samples
// collected from FlutterSoundRecorder.onProgress.  After recording ends, the
// bars are frozen and re-tinted to match the score colour (green / amber / red).

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

    // Scale bar width to the number of samples; keep it within a sensible range.
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

// ── Phoneme compare card ──────────────────────────────────────────────────────
//
// Displays two rows:
//
//  TARGET  — the Na'vi word with its IPA below
//  YOU SAID — the Whisper transcript, plus a char-level pill row that colours
//             each TARGET phoneme green (heard correctly) or red (wrong/missing).
//
// The diff is computed on the phonetically-normalised forms so that, e.g.,
// the ejective 'tx' in "Kaltxì" and Whisper's "t" are considered equivalent.
// The original (unnormalised) target characters are displayed in the pills
// so the user sees their actual Na'vi letters, not the simplified form.

class _PhonemeCompareCard extends StatelessWidget {
  final String targetNavi;
  final String targetIpa;
  final String? transcript;
  final double? score;
  final String Function(String) normalisePhonetic;
  final List<(String, bool)> Function(String, String) alignedDiff;

  const _PhonemeCompareCard({
    required this.targetNavi,
    required this.targetIpa,
    required this.transcript,
    required this.score,
    required this.normalisePhonetic,
    required this.alignedDiff,
  });

  /// Build the per-character display list from the original [navi] string,
  /// inheriting the match status from the normalised diff.  Because
  /// normalisation collapses multi-char sequences (e.g. "tx" → "t"), the
  /// normalised diff has fewer chars than the original.  We walk both strings
  /// in parallel: whenever we consume a normalised-target char, we emit the
  /// corresponding original char(s) with that match status.
  List<(String, bool)> _buildDisplayDiff(
      String navi,
      List<(String, bool)> normDiff,
      ) {
    final normTarget = normalisePhonetic(navi);
    final display = <(String, bool)>[];
    var normIdx = 0;
    var diffIdx = 0;

    for (var i = 0; i < navi.length; i++) {
      final origChar = navi[i];

      if (normIdx < normTarget.length &&
          normTarget[normIdx] == normalisePhonetic(origChar)) {
        final isMatch = diffIdx < normDiff.length
            ? normDiff[diffIdx].$2
            : false;
        display.add((origChar, isMatch));
        normIdx++;
        diffIdx++;
      } else {
        final isMatch =
        display.isNotEmpty ? display.last.$2 : false;
        display.add((origChar, isMatch));
      }
    }

    return display;
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = transcript != null && transcript!.isNotEmpty;
    // Only run the char-level diff when the score is high enough for individual
    // matches to be meaningful. Below ~40% the heard string is so different
    // that the Levenshtein traceback finds stray letter matches scattered
    // through unrelated words and incorrectly marks them green.
    final scoreIsUseful = (score ?? 0.0) >= 0.4;
    final normTarget = normalisePhonetic(targetNavi);
    final normHeard  = hasTranscript ? normalisePhonetic(transcript!) : '';
    final normDiff   = (hasTranscript && scoreIsUseful)
        ? alignedDiff(normTarget, normHeard)
        : null;
    // If score is too low, show all pills red.
    final displayDiff = hasTranscript
        ? (normDiff != null
        ? _buildDisplayDiff(targetNavi, normDiff)
        : [for (final c in targetNavi.characters) (c, false)])
        : null;

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
          // IPA reference
          Text(
            targetIpa,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          // ── You said ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RowLabel('YOU\nSAID'),
              const SizedBox(width: 12),
              Expanded(
                child: hasTranscript && displayDiff != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colour-coded phoneme pills
                    _PhonemeRow(diff: displayDiff),
                    const SizedBox(height: 6),
                    // Raw Whisper text for reference
                    Text(
                      transcript!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                )
                    : Text(
                  kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE'
                      ? 'Add Gemini key to enable transcription'
                      : 'No speech detected \u2014 try again',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),

          if (hasTranscript && displayDiff != null) ...[
            const SizedBox(height: 10),
            const _DiffLegend(),
          ],
        ],
      ),
    );
  }
}

// ── Phoneme pill row ──────────────────────────────────────────────────────────

class _PhonemeRow extends StatelessWidget {
  final List<(String, bool)> diff;
  const _PhonemeRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 4,
      children: diff.map((entry) {
        final (char, isMatch) = entry;
        if (char == ' ') return const SizedBox(width: 8);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: isMatch
                ? const Color(0xFF4CAF50).withOpacity(0.12)
                : AppColors.error.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isMatch
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : AppColors.error.withOpacity(0.45),
            ),
          ),
          child: Text(
            char,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isMatch
                  ? const Color(0xFF4CAF50)
                  : AppColors.error,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Diff legend ───────────────────────────────────────────────────────────────

class _DiffLegend extends StatelessWidget {
  const _DiffLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      _LegendDot(color: Color(0xFF4CAF50), label: 'Correct sound'),
      SizedBox(width: 16),
      _LegendDot(color: AppColors.error, label: 'Needs work'),
    ]);
  }
}

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

// ── Row label ─────────────────────────────────────────────────────────────────

class _RowLabel extends StatelessWidget {
  final String text;
  const _RowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.9),
        ),
      ),
    );
  }
}

// ── Record button ─────────────────────────────────────────────────────────────
//
// While recording:
//  • A CircularProgressIndicator ring counts down the 20-second limit.
//  • The remaining seconds are displayed inside the button.
//  • The ring turns amber when ≤ 5 seconds remain.

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
              // Countdown ring
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

              // Core button circle
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