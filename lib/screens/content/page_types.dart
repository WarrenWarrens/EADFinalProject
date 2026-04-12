import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import '../../services/tts_service.dart';
import '../../services/volume_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_language.dart';

class TextPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const TextPage({
    super.key,
    required this.data,
    required this.onNext,
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
                Text(
                  data['text'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text("Continue"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class CharacterPage extends StatelessWidget{
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const CharacterPage({
    super.key,
    required this.data,
    required this.onNext,
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

                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Audio feature will be implemented later!"),
                          showCloseIcon: true,
                        )
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            data['letter'],
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  data['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text("Continue"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

}

class ExercisePage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const ExercisePage({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    switch (data['exerciseType']) {
      case 'multiple_choice':
        return MultipleChoice(
          question: data['question'],
          options: List<Map<String, dynamic>>.from(data['options']),
          onNext: onNext,
        );
      case 'audio_mimicry':
        return AudioMimicryExercise(data: data, onNext: onNext);
      case 'matching':
        return MatchingExercise(data: data, onNext: onNext);
      case 'listen_choose':
        return ListenChooseExercise(data: data, onNext: onNext);
      case 'fill_in_blank':
        return FillInBlankExercise(data: data, onNext: onNext);
      default:
        return const Center(child: Text('Unknown exercise type'));
    }
  }
}

class MultipleChoice extends StatefulWidget {
  final String question;
  final List<Map<String, dynamic>> options;
  final VoidCallback onNext;

  const MultipleChoice({
    super.key,
    required this.question,
    required this.options,
    required this.onNext,
  });

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  int? selectedIndex;
  bool hasSubmitted = false;

  bool get hasSelected{
    return selectedIndex != null;
  }

  bool get isCorrect{
    return hasSubmitted && widget.options[selectedIndex!]['correct'] == true;
  }

  Color _optionColor(int index) {

    if (!hasSubmitted) {
      return index == selectedIndex ? AppColors.primaryLight : Colors.transparent;
    }

    if (index == selectedIndex) {
      return isCorrect ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
    }

    if (widget.options[index]['correct'] == true) {
      return AppColors.success.withOpacity(0.15);
    }

    return Colors.transparent;
  }

  Color _optionBorderColor(int index) {
    if (!hasSubmitted) {
      return index == selectedIndex ? AppColors.primary : AppColors.primaryLight;
    }

    if (index == selectedIndex) {
      return isCorrect ? AppColors.success : AppColors.error;
    }

    if (widget.options[index]['correct'] == true) {
      return AppColors.success;
    }

    return AppColors.primaryLight;
  }

  void _onCheck() {
    if (!hasSelected) {
      return;
    }

    if (!hasSubmitted) {
      setState(() {
        hasSubmitted = true;
      });
    }
    else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.question,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(widget.options.length, (index) {
                    final option = widget.options[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: hasSubmitted
                            ? null
                            : () => setState(() => selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: _optionColor(index),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _optionBorderColor(index),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            option['text'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (hasSubmitted) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Correct!' : 'Incorrect, try next time!',
                          style: TextStyle(
                            color: isCorrect ? AppColors.success : AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasSelected ? _onCheck : null,
              child: Text(hasSubmitted ? 'Continue' : 'Check'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Shared audio chip ─────────────────────────────────────────────────────────

class _LessonAudioChip extends StatefulWidget {
  final String? localPath;   // pre-cached file path (Na'vi audio)
  final String? ttsText;     // fallback TTS text
  final String label;

  const _LessonAudioChip({
    required this.label,
    this.localPath,
    this.ttsText,
  });

  @override
  State<_LessonAudioChip> createState() => _LessonAudioChipState();
}

class _LessonAudioChipState extends State<_LessonAudioChip> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      if (widget.localPath != null) {
        await _player.setVolume(VolumeService().voiceVolume);
        await _player.setFilePath(widget.localPath!);
        await _player.play();
        await _player.playerStateStream.firstWhere(
              (s) => s.processingState == ProcessingState.completed,
        );
      } else if (widget.ttsText != null) {
        await TtsService.speak(widget.ttsText!);
      }
    } catch (_) {}
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _play,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _playing ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
              color: _playing ? Colors.white : AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _playing ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WordPage ──────────────────────────────────────────────────────────────────

class WordPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const WordPage({super.key, required this.data, required this.onNext});

  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage> {
  DictionaryResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final ref = widget.data['ref'] as String? ?? '';
    final result = await DictionaryService().lookupWord(ref, AppLanguage.navi);
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final overrideEnglish = widget.data['overrideEnglish'] as String?;
    final description = widget.data['description'] as String?;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Word display box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _result?.word ?? widget.data['ref'] ?? '',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                            if (_result?.syllables != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _result!.syllables!,
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Translation
                      Text(
                        overrideEnglish ?? _result?.translation ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      if (_result?.wordType != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _result!.wordType!,
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Audio chip(s)
                      if (_result != null && _result!.audio.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _result!.audio.map((a) => _LessonAudioChip(
                            label: a.speaker,
                            localPath: a.localPath,
                          )).toList(),
                        )
                      else
                        _LessonAudioChip(
                          label: 'Listen',
                          ttsText: _result?.word ?? widget.data['ref'],
                        ),
                      if (description != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ],
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.onNext, child: const Text('Continue')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── PhrasePage ────────────────────────────────────────────────────────────────

class PhrasePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const PhrasePage({super.key, required this.data, required this.onNext});

  @override
  State<PhrasePage> createState() => _PhrasePageState();
}

class _PhrasePageState extends State<PhrasePage> {
  // resolved breakdown entries: {navi, english, localPath?}
  List<Map<String, dynamic>> _breakdown = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final rawBreakdown = widget.data['breakdown'] as List<dynamic>? ?? [];
    final resolved = <Map<String, dynamic>>[];
    for (final item in rawBreakdown) {
      final m = Map<String, dynamic>.from(item as Map);
      if (m.containsKey('ref')) {
        final r = await DictionaryService().lookupWord(m['ref'] as String, AppLanguage.navi);
        resolved.add({
          'navi': r?.word ?? m['ref'],
          'english': r?.translation ?? '',
          'localPath': r != null && r.audio.isNotEmpty ? r.audio.first.localPath : null,
        });
      } else {
        resolved.add({'navi': m['navi'] ?? '', 'english': m['english'] ?? ''});
      }
    }
    if (mounted) setState(() { _breakdown = resolved; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final navi = widget.data['navi'] as String? ?? '';
    final english = widget.data['english'] as String? ?? '';
    final ttsHint = widget.data['ttsHint'] as String? ?? navi;
    final description = widget.data['description'] as String?;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Phrase box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(navi, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(english, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LessonAudioChip(label: 'Listen', ttsText: ttsHint),
                        if (_breakdown.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Word breakdown',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _breakdown.map((w) {
                              final lp = w['localPath'] as String?;
                              return _LessonAudioChip(
                                label: '${w['navi']} — ${w['english']}',
                                localPath: lp,
                                ttsText: lp == null ? w['navi'] as String? : null,
                              );
                            }).toList(),
                          ),
                        ],
                        if (description != null) ...[
                          const SizedBox(height: 20),
                          Text(description, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5)),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.onNext, child: const Text('Continue')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── AudioMimicryExercise ──────────────────────────────────────────────────────

class AudioMimicryExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const AudioMimicryExercise({super.key, required this.data, required this.onNext});

  @override
  State<AudioMimicryExercise> createState() => _AudioMimicryExerciseState();
}

class _AudioMimicryExerciseState extends State<AudioMimicryExercise> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  String? _localPath;
  String? _naviText;
  String? _englishText;
  String? _ttsHint;
  bool _loading = true;
  bool _hasListened = false;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _recorder.openRecorder();
    final ref = widget.data['ref'] as String?;
    if (ref != null) {
      final result = await DictionaryService().lookupWord(ref, AppLanguage.navi);
      _naviText = result?.word ?? ref;
      _englishText = result?.translation ?? '';
      _localPath = result != null && result.audio.isNotEmpty ? result.audio.first.localPath : null;
    } else {
      _naviText = widget.data['navi'] as String?;
      _englishText = widget.data['english'] as String?;
      _ttsHint = widget.data['ttsHint'] as String?;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _playReference() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      if (_localPath != null) {
        await _player.setVolume(VolumeService().voiceVolume);
        await _player.setFilePath(_localPath!);
        await _player.play();
        await _player.playerStateStream.firstWhere(
              (s) => s.processingState == ProcessingState.completed,
        );
      } else {
        await TtsService.speak(_ttsHint ?? _naviText ?? '');
      }
    } catch (_) {}
    if (mounted) setState(() { _isPlaying = false; _hasListened = true; });
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      setState(() { _isRecording = false; _hasRecorded = true; });
    } else {
      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/mimicry_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: _recordPath, codec: Codec.aacADTS);
      setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.data['instruction'] as String? ??
        'Listen to the word, then record yourself saying it.';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(instruction, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 32),
                      if (_naviText != null)
                        Text(_naviText!, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                      if (_englishText != null && _englishText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_englishText!, style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 32),
                      // Play button
                      ElevatedButton.icon(
                        onPressed: _isPlaying ? null : _playReference,
                        icon: Icon(_isPlaying ? Icons.volume_up_rounded : Icons.play_circle_rounded),
                        label: Text(_isPlaying ? 'Playing…' : 'Listen'),
                      ),
                      const SizedBox(height: 20),
                      // Record button
                      GestureDetector(
                        onTap: _hasListened ? _toggleRecord : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording
                                ? AppColors.error
                                : (_hasListened ? AppColors.primary : AppColors.primaryLight),
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white, size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording
                            ? 'Recording… tap to stop'
                            : (_hasRecorded ? 'Recorded! Tap to redo.' : (_hasListened ? 'Tap mic to record' : 'Listen first')),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasListened ? widget.onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── MatchingExercise ──────────────────────────────────────────────────────────

class MatchingExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const MatchingExercise({super.key, required this.data, required this.onNext});

  @override
  State<MatchingExercise> createState() => _MatchingExerciseState();
}

class _MatchingExerciseState extends State<MatchingExercise> {
  List<String> _leftItems = [];
  List<String> _rightItems = [];   // shuffled translations
  List<String> _rightAnswers = []; // correct translations (aligned with _leftItems)

  int? _selectedLeft;
  int? _selectedRight;
  final Map<int, bool> _matchedLeft = {};
  final Map<int, bool> _matchedRight = {};
  final Set<int> _wrongLeft = {};
  final Set<int> _wrongRight = {};

  bool _loading = true;
  bool _allMatched = false;

  @override
  void initState() {
    super.initState();
    _buildPairs();
  }

  Future<void> _buildPairs() async {
    final pairs = widget.data['pairs'] as List<dynamic>?;
    final refs = widget.data['refs'] as List<dynamic>?;

    final left = <String>[];
    final answers = <String>[];

    if (pairs != null) {
      for (final p in pairs) {
        final m = p as Map;
        left.add(m['left'] as String);
        answers.add(m['right'] as String);
      }
    } else if (refs != null) {
      for (final ref in refs) {
        final r = await DictionaryService().lookupWord(ref as String, AppLanguage.navi);
        left.add(r?.word ?? ref);
        answers.add(r?.translation ?? ref);
      }
    }

    final shuffled = List<String>.from(answers)..shuffle();

    if (mounted) {
      setState(() {
        _leftItems = left;
        _rightAnswers = answers;
        _rightItems = shuffled;
        _loading = false;
      });
    }
  }

  void _onTapLeft(int i) {
    if (_matchedLeft.containsKey(i)) return;
    setState(() {
      _wrongLeft.clear(); _wrongRight.clear();
      _selectedLeft = i;
    });
    _tryMatch();
  }

  void _onTapRight(int i) {
    if (_matchedRight.containsKey(i)) return;
    setState(() {
      _wrongLeft.clear(); _wrongRight.clear();
      _selectedRight = i;
    });
    _tryMatch();
  }

  void _tryMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;
    final l = _selectedLeft!;
    final r = _selectedRight!;
    final correct = _rightAnswers[l] == _rightItems[r];
    if (correct) {
      setState(() {
        _matchedLeft[l] = true;
        _matchedRight[r] = true;
        _selectedLeft = null;
        _selectedRight = null;
        _allMatched = _matchedLeft.length == _leftItems.length;
      });
    } else {
      setState(() {
        _wrongLeft.add(l); _wrongRight.add(r);
        _selectedLeft = null; _selectedRight = null;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _wrongLeft.clear(); _wrongRight.clear(); });
      });
    }
  }

  Color _leftColor(int i) {
    if (_matchedLeft.containsKey(i)) return AppColors.success.withOpacity(0.15);
    if (_wrongLeft.contains(i)) return AppColors.error.withOpacity(0.15);
    if (_selectedLeft == i) return AppColors.primaryLight;
    return Colors.transparent;
  }

  Color _rightColor(int i) {
    if (_matchedRight.containsKey(i)) return AppColors.success.withOpacity(0.15);
    if (_wrongRight.contains(i)) return AppColors.error.withOpacity(0.15);
    if (_selectedRight == i) return AppColors.primaryLight;
    return Colors.transparent;
  }

  Color _leftBorder(int i) {
    if (_matchedLeft.containsKey(i)) return AppColors.success;
    if (_wrongLeft.contains(i)) return AppColors.error;
    if (_selectedLeft == i) return AppColors.primary;
    return AppColors.primaryLight;
  }

  Color _rightBorder(int i) {
    if (_matchedRight.containsKey(i)) return AppColors.success;
    if (_wrongRight.contains(i)) return AppColors.error;
    if (_selectedRight == i) return AppColors.primary;
    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.data['instruction'] as String? ?? 'Match each word with its meaning.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(instruction, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column
                            Expanded(
                              child: Column(
                                children: List.generate(_leftItems.length, (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onTapLeft(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _leftColor(i),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _leftBorder(i), width: 2),
                                      ),
                                      child: Text(_leftItems[i], textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right column
                            Expanded(
                              child: Column(
                                children: List.generate(_rightItems.length, (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onTapRight(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _rightColor(i),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _rightBorder(i), width: 2),
                                      ),
                                      child: Text(_rightItems[i], textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                )),
                              ),
                            ),
                          ],
                        ),
                        if (_allMatched) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: AppColors.success),
                              SizedBox(width: 8),
                              Text('All matched!', style: TextStyle(color: AppColors.success,
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allMatched ? widget.onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── ListenChooseExercise ──────────────────────────────────────────────────────

class ListenChooseExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const ListenChooseExercise({super.key, required this.data, required this.onNext});

  @override
  State<ListenChooseExercise> createState() => _ListenChooseExerciseState();
}

class _ListenChooseExerciseState extends State<ListenChooseExercise> {
  String? _localPath;
  String? _naviWord;
  bool _loading = true;
  bool _hasListened = false;
  int? _selectedIndex;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ref = widget.data['ref'] as String?;
    if (ref != null) {
      final r = await DictionaryService().lookupWord(ref, AppLanguage.navi);
      _naviWord = r?.word ?? ref;
      _localPath = r != null && r.audio.isNotEmpty ? r.audio.first.localPath : null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _playAudio() async {
    if (_naviWord == null) return;
    try {
      if (_localPath != null) {
        final player = AudioPlayer();
        await player.setVolume(VolumeService().voiceVolume);
        await player.setFilePath(_localPath!);
        await player.play();
        await player.playerStateStream.firstWhere(
              (s) => s.processingState == ProcessingState.completed,
        );
        await player.dispose();
      } else {
        await TtsService.speak(_naviWord!);
      }
    } catch (_) {}
    if (mounted) setState(() => _hasListened = true);
  }

  bool get _isCorrect =>
      _hasSubmitted && (widget.data['options'] as List)[_selectedIndex!]['correct'] == true;

  Color _optionColor(int i) {
    if (!_hasSubmitted) return i == _selectedIndex ? AppColors.primaryLight : Colors.transparent;
    if (i == _selectedIndex) return _isCorrect ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
    if ((widget.data['options'] as List)[i]['correct'] == true) return AppColors.success.withOpacity(0.15);
    return Colors.transparent;
  }

  Color _optionBorder(int i) {
    if (!_hasSubmitted) return i == _selectedIndex ? AppColors.primary : AppColors.primaryLight;
    if (i == _selectedIndex) return _isCorrect ? AppColors.success : AppColors.error;
    if ((widget.data['options'] as List)[i]['correct'] == true) return AppColors.success;
    return AppColors.primaryLight;
  }

  void _onCheck() {
    if (_selectedIndex == null) return;
    if (!_hasSubmitted) {
      setState(() => _hasSubmitted = true);
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.data['instruction'] as String? ?? 'Listen and choose what it means.';
    final options = (widget.data['options'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Listen button (big)
                        GestureDetector(
                          onTap: _playAudio,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              color: _hasListened ? AppColors.primaryLight : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.volume_up_rounded,
                                color: _hasListened ? AppColors.primary : Colors.white, size: 56),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(instruction, textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 32),
                        ...List.generate(options.length, (i) {
                          final opt = options[i] as Map;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: (_hasSubmitted || !_hasListened)
                                  ? null
                                  : () => setState(() => _selectedIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: _optionColor(i),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _optionBorder(i), width: 2),
                                ),
                                child: Text(opt['text'] as String, textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        }),
                        if (_hasSubmitted) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: _isCorrect ? AppColors.success : AppColors.error),
                              const SizedBox(width: 8),
                              Text(_isCorrect ? 'Correct!' : 'Incorrect, try next time!',
                                  style: TextStyle(
                                      color: _isCorrect ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_hasListened && _selectedIndex != null) ? _onCheck : null,
              child: Text(_hasSubmitted ? 'Continue' : 'Check'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── FillInBlankExercise ───────────────────────────────────────────────────────

class FillInBlankExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const FillInBlankExercise({super.key, required this.data, required this.onNext});

  @override
  State<FillInBlankExercise> createState() => _FillInBlankExerciseState();
}

class _FillInBlankExerciseState extends State<FillInBlankExercise> {
  String? _chosen;
  bool _hasSubmitted = false;

  bool get _isCorrect =>
      _hasSubmitted && _chosen == widget.data['answer'];

  void _onCheck() {
    if (_chosen == null) return;
    if (!_hasSubmitted) {
      setState(() => _hasSubmitted = true);
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.data['instruction'] as String? ?? 'Fill in the blank.';
    final sentence = widget.data['sentence'] as String? ?? '';
    final answer = widget.data['answer'] as String? ?? '';
    final hint = widget.data['hint'] as String?;
    final options = (widget.data['options'] as List<dynamic>? ?? []).cast<String>();

    // Replace _____ with chosen word or placeholder
    final displaySentence = _chosen != null
        ? sentence.replaceAll('_____', _chosen!)
        : sentence;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight, shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, size: 52, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(instruction, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  // Sentence display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(displaySentence, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.6)),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 8),
                    Text('Hint: $hint', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 28),
                  // Option chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: options.map((opt) {
                      final isSelected = opt == _chosen;
                      Color bg = Colors.transparent;
                      Color border = AppColors.primaryLight;
                      if (_hasSubmitted && isSelected) {
                        bg = _isCorrect ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
                        border = _isCorrect ? AppColors.success : AppColors.error;
                      } else if (!_hasSubmitted && isSelected) {
                        bg = AppColors.primaryLight;
                        border = AppColors.primary;
                      } else if (_hasSubmitted && opt == answer) {
                        bg = AppColors.success.withOpacity(0.15);
                        border = AppColors.success;
                      }
                      return GestureDetector(
                        onTap: _hasSubmitted ? null : () => setState(() => _chosen = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border, width: 2),
                          ),
                          child: Text(opt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_hasSubmitted) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _isCorrect ? AppColors.success : AppColors.error),
                        const SizedBox(width: 8),
                        Text(_isCorrect ? 'Correct!' : 'Incorrect, try next time!',
                            style: TextStyle(
                                color: _isCorrect ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _chosen != null ? _onCheck : null,
              child: Text(_hasSubmitted ? 'Continue' : 'Check'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
