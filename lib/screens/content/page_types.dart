import 'dart:async';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/dictionary_entry.dart';
import '../../services/audio_analysis_service.dart';
import '../../services/dictionary_service.dart';
import '../../services/tts_service.dart';
import '../../services/volume_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_language.dart';
import '../../services/audio_analysis_service_onnx.dart';
import '../../services/vocab_tracking_service.dart';

class TextPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onLast;

  const TextPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onLast, // 2. Required it in the constructor

  });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   data['text'],
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                       fontSize: 20
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: onLast,
//               child: const Text("Continue"),
//             ),
//           ),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: onNext,
//               child: const Text("Continue"),
//             ),
//           ),
//
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
// }
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
                  style: const TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          // Side-by-side buttons using a Row
          Row(
            children: [
              // Go Back Button (takes up 25% of the remaining space)
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: onLast, // Triggers the go back function
                  child: const Text("Go Back"),
                ),
              ),

              const SizedBox(width: 12), // Adds a small gap between the buttons

              // Continue Button (takes up 75% of the remaining space)
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: onNext, // Triggers the next page function
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}


class CharacterPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onLast; // 1. Added the onLast callback

  const CharacterPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onLast, // 2. Required it in the constructor
  });

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  bool _playing = false;

  Future<void> _playLetter() async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      final letter = widget.data['letter'] as String? ?? '';
      // Optional pronunciation hint from the lesson JSON (e.g. "ah" for 'ä'),
      // otherwise speak the letter itself via the on-device TTS engine.
      final hint = widget.data['ttsHint'] as String? ?? letter;
      // Stop any prior utterance first — if the engine is stuck in a
      // 'speaking' state from a previous session, a fresh speak() call can
      // be silently dropped. stop() clears that state on all platforms.
      await TtsService.stop();
      await TtsService.speak(hint);
    } catch (e) {
      debugPrint('[CharacterPage] TTS error: $e');
    }
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                GestureDetector(
                  onTap: _playLetter,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _playing ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            data['letter'],
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: _playing ? Colors.white : null,
                            ),
                          ),
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            _playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                            // Notice: AppColors.textPrimary might need to be Theme.of(context).colorScheme.onPrimary if you want it to adapt perfectly
                            color: _playing ? Colors.white : Theme.of(context).colorScheme.primary,
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
                  style: const TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          // 3. Replaced the single SizedBox with the Row layout
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast, // Triggers the go back function
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: widget.onNext, // Triggers the next slide function
                  child: const Text("Continue"),
                ),
              ),
            ],
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
  final VoidCallback onLast;

  const ExercisePage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onLast
  });

  @override
  Widget build(BuildContext context) {
    switch (data['exerciseType']) {
      case 'multiple_choice':
        return MultipleChoice(
          question: data['question'],
          options: List<Map<String, dynamic>>.from(data['options']),
          ref: data['ref'] as String?,
          onNext: onNext,
          onLast: onLast
        );
      case 'audio_mimicry':
        return AudioMimicryExercise(data: data, onNext: onNext, onLast: onLast);
      case 'matching':
        return MatchingExercise(data: data, onNext: onNext, onLast: onLast);
      case 'listen_choose':
        return ListenChooseExercise(data: data, onNext: onNext, onLast: onLast);
      case 'fill_in_blank':
        return FillInBlankExercise(data: data, onNext: onNext, onLast: onLast);
      default:
        return const Center(child: Text('Unknown exercise type'));
    }
  }
}

class MultipleChoice extends StatefulWidget {
  final String question;
  final List<Map<String, dynamic>> options;
  final VoidCallback onNext;
  final VoidCallback onLast;
  final String? ref;   // ← simple single field

  const MultipleChoice({
    super.key,
    required this.question,
    required this.options,
    required this.onNext,
    required this.onLast,
    this.ref,
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
      return index == selectedIndex ? Theme.of(context).colorScheme.primary.withOpacity(0.15): Colors.transparent;
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
      return index == selectedIndex ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.15);
    }

    if (index == selectedIndex) {
      return isCorrect ? AppColors.success : AppColors.error;
    }

    if (widget.options[index]['correct'] == true) {
      return AppColors.success;
    }

    return Theme.of(context).colorScheme.primary.withOpacity(0.15);
  }

  void _onCheck() {
    if (!hasSelected) {
      return;
    }

    if (!hasSubmitted) {
      setState(() => hasSubmitted = true);
      final wid = widget.ref;
      if (wid != null) {
        VocabTrackingService().recordNonVocalAttempt(
          wordId: wid,
          displayText: wid,
          correct: isCorrect,
          source: 'multiple_choice',
        );
      }
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
                      decoration:  BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(
                        Icons.quiz_rounded,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
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

          // const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: hasSelected ? _onCheck : null,
          //     child: Text(hasSubmitted ? 'Continue' : 'Check'),
          //   ),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: hasSelected ? _onCheck : null,
                  child: Text(hasSubmitted ? 'Continue' : 'Check'),
                ),
              ),
            ],
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
          color: _playing ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
              color: _playing ? Colors.white : Theme.of(context).colorScheme.primary,
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
  final VoidCallback onLast;

  const WordPage({super.key, required this.data, required this.onNext, required this.onLast});

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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(onPressed: widget.onNext, child: const Text('Continue')),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  child: const Text('Continue'),
                ),
              ),
            ],
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
  final VoidCallback onLast;

  const PhrasePage({super.key, required this.data, required this.onNext, required this.onLast});

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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
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
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(onPressed: widget.onNext, child: const Text('Continue')),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  child: const Text('Continue'),
                ),
              ),
            ],
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
  final VoidCallback onLast;

  const AudioMimicryExercise({super.key, required this.data, required this.onNext, required this.onLast});

  @override
  State<AudioMimicryExercise> createState() => _AudioMimicryExerciseState();
}

class _AudioMimicryExerciseState extends State<AudioMimicryExercise> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _cachedReferenceIpa;
  String? _heardIpa;          // ← ADD
  String? _referenceIpa;      // ← ADD (the expected/reference transcription we scored against)
  String? _localPath;
  String? _referenceWavPath;   // PCM16 WAV — required for analysis
  String? _naviText;
  String? _englishText;
  String? _ttsHint;
  bool _loading = true;
  bool _hasListened = false;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _recorderReady = false;
  bool _scoring = false;
  double? _score;
  String? _feedback;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Request runtime microphone permission before opening the recorder.
    // Without this, flutter_sound.startRecorder() silently fails on Android
    // 13+ because RECORD_AUDIO is a dangerous permission.
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      try {
        await _recorder.openRecorder();
        _recorderReady = true;
      } catch (e) {
        debugPrint('[Mimicry] openRecorder failed: $e');
      }
    } else {
      debugPrint('[Mimicry] Microphone permission denied');
    }

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

    // Prepare a WAV copy of the reference audio for AudioAnalysisService
    // (it reads raw PCM samples so it can't accept mp3/ogg/aac directly).
    // Done in the background — recording still works even if conversion
    // fails, just without a score.
    if (_localPath != null) {
      _referenceWavPath = await _convertToWav(_localPath!);
    }

    if (mounted) setState(() => _loading = false);
  }

  /// Convert an audio file to 16 kHz mono PCM16 WAV in the temp directory.
  /// Returns the new path, or null if conversion fails.
  Future<String?> _convertToWav(String sourcePath) async {
    try {
      if (sourcePath.toLowerCase().endsWith('.wav')) return sourcePath;
      final dir = await getTemporaryDirectory();
      final wavPath =
          '${dir.path}/mimicry_ref_${DateTime.now().millisecondsSinceEpoch}.wav';
      final session = await FFmpegKit.execute(
        '-y -i "$sourcePath" -ar 16000 -ac 1 -sample_fmt s16 "$wavPath"',
      );
      final code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code)) return wavPath;
      debugPrint('[Mimicry] WAV conversion failed for $sourcePath');
    } catch (e) {
      debugPrint('[Mimicry] WAV conversion error: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    if (_recorderReady) _recorder.closeRecorder();
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
    // If the recorder never opened (permission denied, engine error), prompt
    // the user to grant permission via system settings rather than silently
    // failing when the mic is tapped.
    if (!_recorderReady) {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        try {
          await _recorder.openRecorder();
          _recorderReady = true;
        } catch (e) {
          debugPrint('[Mimicry] openRecorder retry failed: $e');
        }
      }
      if (!_recorderReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone access is required to record. Enable it in system settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    try {
      if (_isRecording) {
        await _recorder.stopRecorder();
        setState(() { _isRecording = false; _hasRecorded = true; });
        // Kick off analysis. We don't block the UI on this — the user sees
        // "Scoring…" until it completes, then the badge swaps in.
        _scoreRecording();
      } else {
        final dir = await getTemporaryDirectory();
        _recordPath =
        '${dir.path}/mimicry_${DateTime.now().millisecondsSinceEpoch}.wav';
        // PCM16 WAV so AudioAnalysisService can read raw samples directly.
        await _recorder.startRecorder(
          toFile: _recordPath,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          numChannels: 1,
        );
        setState(() {
          _isRecording = true;
          _score = null;
          _feedback = null;
          _heardIpa = null;
          _referenceIpa = null;
        });
      }
    } catch (e) {
      debugPrint('[Mimicry] Record toggle error: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  /// On-device Wav2Vec2 CTC scoring via NaviIpaService.
  /// Priority for the expected IPA:
  ///   1. Hand-authored IPA from the lesson/dictionary (_expectedIpa)
  ///   2. Transcribe the reference WAV through the same model, use that
  ///   3. Transcribe-only (no score) as last resort
  Future<void> _scoreRecording() async {
    print('[ONNX] page_types._scoreRecording fired, refWav=$_referenceWavPath');
    if (_recordPath == null) return;

    setState(() => _scoring = true);
    try {
      await NaviIpaService().init();

      // ── Resolve target IPA ─────────────────────────────────────────────
      String expected = '';

      if (_referenceWavPath != null) {
        // Transcribe the reference TTS audio through the same model.
        // Whatever phonemes the model hears in the reference become our
        // target — this self-consistent approach cancels out model bias.
        if (_cachedReferenceIpa != null) {
          expected = _cachedReferenceIpa!;
        } else {
          try {
            expected = await NaviIpaService().transcribe(_referenceWavPath!);
            _cachedReferenceIpa = expected;
            print('[ONNX] reference transcription → "$expected" (cached)');
          } catch (e) {
            debugPrint('[ONNX] reference transcription failed: $e');
          }
        }
      }

      if (expected.isEmpty) {
        // Still nothing — transcribe the attempt so user sees *something*.
        final heard = await NaviIpaService().transcribe(_recordPath!);
        if (!mounted) return;
        setState(() {
          _score = 0.5;
          _heardIpa = heard;
          _referenceIpa = null;
          _feedback = 'No reference available — transcription only';
          _scoring = false;
        });
        return;
      }

      final result = await NaviIpaService().score(
        wavPath: _recordPath!,
        expectedIpa: expected,
      );

      if (!mounted) return;
      setState(() {
        _score = result.score;
        _heardIpa = result.heard;
        _referenceIpa = result.expected;
        _feedback = result.score >= 0.85
            ? 'Great match!'
            : result.score >= 0.65
            ? 'Close — small differences'
            : result.score >= 0.40
            ? 'Getting there — keep practising'
            : 'Try again';
        _scoring = false;
      });
      final wordId = widget.data['ref'] as String?;
      if (wordId != null && _naviText != null) {
        VocabTrackingService().recordVocalAttempt(
          wordId: wordId,
          displayText: _naviText!,
          score: result.score,
          source: 'page_types_mimicry',
        );
      }
    } catch (e) {
      debugPrint('[ONNX] page_types scoring error: $e');
      if (mounted) {
        setState(() {
          _score = 0.0;
          _feedback = 'Phoneme analysis failed — try again';
          _scoring = false;
        });
      }
    }
  }

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
                // Record button — always tappable. Previously this was
                // gated behind _hasListened, which made the button
                // appear broken if Listen failed or the user wanted to
                // try recording first. The Continue button below still
                // requires having listened, preserving the intended
                // flow without leaving a dead-looking button onscreen.
                GestureDetector(
                  onTap: _toggleRecord,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? AppColors.error
                          : Theme.of(context).colorScheme.primary,
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
                      : (_hasRecorded
                      ? 'Recorded! Tap to redo.'
                      : (_hasListened
                      ? 'Tap mic to record'
                      : 'Tap Listen first, then record')),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                // Scoring indicator + result badge — styled to match
                // the audio_mimicry_screen badge for consistency.
                if (_scoring) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 8),
                  const Text('Scoring…',
                      style: TextStyle(color: AppColors.textSecondary)),
                ] else if (_score != null) ...[
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _MimicryScoreBadge(
                      key: ValueKey(_score),
                      score: _score!,
                      color: _scoreColor(_score!),
                      label: _scoreLabel(_score!),
                    ),
                  ),
                  if (_heardIpa != null || _referenceIpa != null) ...[
                    const SizedBox(height: 16),
                    _IpaComparisonCard(
                      heard: _heardIpa ?? '',
                      reference: _referenceIpa,
                    ),
                  ],
                  if (_feedback != null && _feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _feedback!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: _hasListened ? widget.onNext : null,
          //     child: const Text('Continue'),
          //   ),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _hasListened ? widget.onNext : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Score badge for AudioMimicryExercise ─────────────────────────────────────
//
// Compact pill showing the pronunciation score result. Mirrors the styling
// of _ScoreBadge in audio_mimicry_screen.dart so the two surfaces feel
// consistent when the user switches between them.

class _MimicryScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  final String label;

  const _MimicryScoreBadge({
    super.key,
    required this.score,
    required this.color,
    required this.label,
  });

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
                  fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 12),
          Text('${(score * 100).round()}%',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── IPA comparison card ──────────────────────────────────────────────────────
//
// Stacks reference IPA (what the model heard in the TTS/native reference)
// over the player's IPA (what the model heard in their recording). Gives
// the user concrete phonetic feedback instead of just a score.

class _IpaComparisonCard extends StatelessWidget {
  final String heard;
  final String? reference;

  const _IpaComparisonCard({required this.heard, this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reference != null && reference!.isNotEmpty) ...[
            _row('Reference', reference!, Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          _row('You said', heard.isEmpty ? '(nothing detected)' : heard,
              AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _row(String label, String ipa, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3),
          ),
        ),
        Expanded(
          child: Text(
            '/$ipa/',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
// ── MatchingExercise ──────────────────────────────────────────────────────────

class MatchingExercise extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;
  final VoidCallback onLast;

  const MatchingExercise({super.key, required this.data, required this.onNext, required this.onLast});

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

    // Derange so no right-side answer ends up paired with its own left
    // on the first try — a plain shuffle() on 5 items often produces an
    // order that looks unshuffled (or only 1–2 swaps off), which gives
    // away the answers. Fall back to shuffle if derangement is impossible
    // (n < 2 or all entries identical).
    final shuffled = _derange(answers);

    if (mounted) {
      setState(() {
        _leftItems = left;
        _rightAnswers = answers;
        _rightItems = shuffled;
        _loading = false;
      });
    }
  }

  /// Return a permutation of [items] where items[i] != result[i] for every i.
  /// Uses rejection sampling — simple and more than fast enough for the
  /// short lists used in matching exercises. Falls back to a plain shuffle
  /// if no derangement exists (duplicate entries in every slot).
  static List<String> _derange(List<String> items) {
    if (items.length < 2) return List<String>.from(items);
    final rand = math.Random();
    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate = List<String>.from(items)..shuffle(rand);
      var ok = true;
      for (var i = 0; i < items.length; i++) {
        if (candidate[i] == items[i]) { ok = false; break; }
      }
      if (ok) return candidate;
    }
    // Fallback: cyclic shift by 1 guarantees derangement if all items unique.
    final fallback = [items.last, ...items.sublist(0, items.length - 1)];
    return fallback;
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

    // Record against the left-side word regardless of outcome.
    final rawWordIds = widget.data['refs'] as List<dynamic>?;
    if (rawWordIds != null && l < rawWordIds.length) {
      final wid = rawWordIds[l] as String?;
      if (wid != null) {
        VocabTrackingService().recordNonVocalAttempt(
          wordId: wid,
          displayText: _leftItems[l],
          correct: correct,
          source: 'matching',
        );
      }
    }

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
    if (_selectedLeft == i) return Theme.of(context).colorScheme.primary.withOpacity(0.15);
    return Colors.transparent;
  }

  Color _rightColor(int i) {
    if (_matchedRight.containsKey(i)) return AppColors.success.withOpacity(0.15);
    if (_wrongRight.contains(i)) return AppColors.error.withOpacity(0.15);
    if (_selectedRight == i) return Theme.of(context).colorScheme.primary.withOpacity(0.15);
    return Colors.transparent;
  }

  Color _leftBorder(int i) {
    if (_matchedLeft.containsKey(i)) return AppColors.success;
    if (_wrongLeft.contains(i)) return AppColors.error;
    if (_selectedLeft == i) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.primary.withOpacity(0.15);
  }

  Color _rightBorder(int i) {
    if (_matchedRight.containsKey(i)) return AppColors.success;
    if (_wrongRight.contains(i)) return AppColors.error;
    if (_selectedRight == i) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.primary.withOpacity(0.15);
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
                  // One Row per pair, wrapped in IntrinsicHeight so the
                  // left (Na'vi, bold 16pt) and right (English, 14pt)
                  // pills in that row share the taller pill's height.
                  // Prevents the visual mismatch where the left column
                  // ends up noticeably taller than the right.
                  Column(
                    children: List.generate(_leftItems.length, (i) {
                      final hasRight = i < _rightItems.length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _onTapLeft(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _leftColor(i),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: _leftBorder(i), width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _leftItems[i],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: hasRight
                                    ? GestureDetector(
                                  onTap: () => _onTapRight(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _rightColor(i),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: _rightBorder(i), width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _rightItems[i],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: _allMatched ? widget.onNext : null,
          //     child: const Text('Continue'),
          //   ),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _allMatched ? widget.onNext : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
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
  final VoidCallback onLast;

  const ListenChooseExercise({super.key, required this.data, required this.onNext, required this.onLast});

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
    if (!_hasSubmitted) return i == _selectedIndex ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.transparent;
    if (i == _selectedIndex) return _isCorrect ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
    if ((widget.data['options'] as List)[i]['correct'] == true) return AppColors.success.withOpacity(0.15);
    return Colors.transparent;
  }

  Color _optionBorder(int i) {
    if (!_hasSubmitted) return i == _selectedIndex ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.15);
    if (i == _selectedIndex) return _isCorrect ? AppColors.success : AppColors.error;
    if ((widget.data['options'] as List)[i]['correct'] == true) return AppColors.success;
    return Theme.of(context).colorScheme.primary.withOpacity(0.15);
  }

  void _onCheck() {
    if (_selectedIndex == null) return;
    if (!_hasSubmitted) {
      setState(() => _hasSubmitted = true);
      final wid = widget.data['ref'] as String?;
      if (wid != null && _naviWord != null) {
        VocabTrackingService().recordNonVocalAttempt(
          wordId: wid,
          displayText: _naviWord!,
          correct: _isCorrect,
          source: 'listen_choose',
        );
      }
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
                        color: _hasListened ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volume_up_rounded,
                          color: _hasListened ? Theme.of(context).colorScheme.primary : Colors.white, size: 56),
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
          // const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: (_hasListened && _selectedIndex != null) ? _onCheck : null,
          //     child: Text(_hasSubmitted ? 'Continue' : 'Check'),
          //   ),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: (_hasListened && _selectedIndex != null) ? _onCheck : null,
                  child: Text(_hasSubmitted ? 'Continue' : 'Check'),
                ),
              ),
            ],
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
  final VoidCallback onLast;

  const FillInBlankExercise({super.key, required this.data, required this.onNext, required this.onLast});

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
      final wid = widget.data['answer'] as String?;
      if (wid != null) {
        VocabTrackingService().recordNonVocalAttempt(
          wordId: wid,
          displayText: wid,
          correct: _isCorrect,
          source: 'fill_blank',
        );
      }
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15), shape: BoxShape.circle,
                      ),
                      child:  Icon(Icons.edit_rounded, size: 52, color: Theme.of(context).colorScheme.primary),
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
                      Color border = Theme.of(context).colorScheme.primary.withOpacity(0.15);
                      if (_hasSubmitted && isSelected) {
                        bg = _isCorrect ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
                        border = _isCorrect ? AppColors.success : AppColors.error;
                      } else if (!_hasSubmitted && isSelected) {
                        bg = Theme.of(context).colorScheme.primary.withOpacity(0.15);
                        border = Theme.of(context).colorScheme.primary;
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
          // const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: _chosen != null ? _onCheck : null,
          //     child: Text(_hasSubmitted ? 'Continue' : 'Check'),
          //   ),
          // ),
          // const SizedBox(height: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: widget.onLast,
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _chosen != null ? _onCheck : null,
                  child: Text(_hasSubmitted ? 'Continue' : 'Check'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}