import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import '../../services/tts_service.dart';
import '../../services/volume_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_language.dart';
import '../../widgets/app_nav_bar.dart';
import 'profile_screen.dart';

class StudyPage extends StatefulWidget {
  final AppLanguage selectedLanguage;
  const StudyPage({super.key, this.selectedLanguage = AppLanguage.navi});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late AppLanguage _language;

  final _service = DictionaryService();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _player = AudioPlayer();

  List<DictionaryEntry> _history = [];
  DictionaryEntry? _currentEntry;
  bool _loading = false;
  String? _errorMessage;
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _language = widget.selectedLanguage;
    _searchController.addListener(() => setState(() {}));
    _loadHistory();

    // Clear the playing indicator when a track finishes naturally.
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _playingPath = null);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final h = await _service.getHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _currentEntry = null;
    });
    try {
      final entry = await _service.search(q, _language);
      if (mounted) {
        setState(() {
          _currentEntry = entry;
          _loading = false;
        });
        if (entry.results.isNotEmpty) _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Search failed — check your connection';
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentEntry = null;
      _errorMessage = null;
    });
  }

  void _onLanguageChange(AppLanguage lang) {
    if (lang == _language) return;
    setState(() {
      _language = lang;
      _currentEntry = null;
      _errorMessage = null;
    });
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  Future<void> _togglePlay(String path) async {
    if (_playingPath == path) {
      await _player.stop();
      if (mounted) setState(() => _playingPath = null);
      return;
    }
    if (!File(path).existsSync()) return;
    if (mounted) setState(() => _playingPath = path);
    try {
      await _player.setFilePath(path);
      await _player.setVolume(VolumeService().voiceVolume);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingPath = null);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            initialLanguage: _language,
            onLanguageChange: (lang) => setState(() => _language = lang),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 1,
        selectedLanguage: _language,
        onTap: _onNavTap,
        onLanguageSelect: _onLanguageChange,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Text(
            'Dictionary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _LanguageToggle(
            selected: _language,
            onChanged: _onLanguageChange,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: _language == AppLanguage.navi
                      ? "Na'vi word or English…"
                      : 'Klingon word…',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: _clearSearch,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }
    if (_currentEntry != null) {
      return _buildResults(_currentEntry!);
    }
    return _buildHistory();
  }

  Widget _buildResults(DictionaryEntry entry) {
    if (entry.results.isEmpty) {
      return _buildNoResults(entry.query);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: entry.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ResultCard(
        result: entry.results[i],
        language: entry.language,
        playingPath: _playingPath,
        onPlay: _togglePlay,
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: AppColors.textSecondary.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try the Na'vi spelling or its English translation",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded,
                  size: 56,
                  color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'Look up a word',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                "Na'vi or English accepted",
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
          child: Row(
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await _service.clearHistory();
                  _loadHistory();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Clear all',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: _history.length,
            itemBuilder: (_, i) {
              final entry = _history[i];
              return Dismissible(
                key: ValueKey(
                    '${entry.language.name}_${entry.query}_${entry.searchedAt.millisecondsSinceEpoch}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
                onDismissed: (_) async {
                  await _service.deleteEntry(i);
                  _loadHistory();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HistoryTile(
                    entry: entry,
                    onTap: () {
                      _searchController.text = entry.query;
                      _search(entry.query);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Language toggle (Na'vi | Klingon pill switcher)
// ═══════════════════════════════════════════════════════════════════════════════

class _LanguageToggle extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const langs = [AppLanguage.navi, AppLanguage.klingon];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: langs.map((lang) {
          final isSelected = selected == lang;
          final accent = lang.accentColor;
          return GestureDetector(
            onTap: () => onChanged(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                lang.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? accent : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Result card
// ═══════════════════════════════════════════════════════════════════════════════

class _ResultCard extends StatefulWidget {
  final DictionaryResult result;
  final AppLanguage language;
  final String? playingPath;
  final void Function(String) onPlay;

  const _ResultCard({
    required this.result,
    required this.language,
    required this.playingPath,
    required this.onPlay,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  // Cached path for on-demand TTS — fetched once, reused on subsequent taps.
  String? _ttsPath;
  bool _ttsLoading = false;

  // Device TTS (flutter_tts) state — used when no file-based audio exists.
  bool _deviceTtsPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen for device TTS completion so we can reset the button state.
    TtsService.initListeners(
      onStart: () {
        if (mounted) setState(() => _deviceTtsPlaying = true);
      },
      onComplete: () {
        if (mounted) setState(() => _deviceTtsPlaying = false);
      },
    );
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  Future<void> _onTtsTap() async {
    // If device TTS is currently speaking, stop it.
    if (_deviceTtsPlaying) {
      await TtsService.stop();
      if (mounted) setState(() => _deviceTtsPlaying = false);
      return;
    }

    // If a file-based path is already cached, play it via AudioPlayer.
    if (_ttsPath != null) {
      widget.onPlay(_ttsPath!);
      return;
    }

    setState(() => _ttsLoading = true);

    // Try Reykunyu file-based audio first (works for Na'vi).
    final path = await TtsService.getSingleWordAudio(
      naviWord: widget.result.word,
      ttsHint: widget.result.syllables ?? widget.result.word,
    );

    if (!mounted) return;

    if (path != null) {
      // Got a file — cache and play via AudioPlayer.
      setState(() {
        _ttsPath = path;
        _ttsLoading = false;
      });
      widget.onPlay(path);
    } else {
      // No file available (e.g. Klingon) — use on-device TTS directly.
      setState(() => _ttsLoading = false);
      await TtsService.speak(widget.result.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.language.accentColor;
    final result = widget.result;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word + part-of-speech badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  result.word,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              if (result.wordType.isNotEmpty) ...[
                const SizedBox(width: 8),
                _WordTypeBadge(type: result.wordType, color: accent),
              ],
            ],
          ),

          // Syllabified pronunciation + IPA
          if ((result.syllables != null && result.syllables!.isNotEmpty) ||
              (result.ipa != null && result.ipa!.isNotEmpty)) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                  height: 1.5,
                ),
                children: [
                  if (result.syllables != null && result.syllables!.isNotEmpty)
                    TextSpan(text: result.syllables!),
                  if (result.syllables != null &&
                      result.syllables!.isNotEmpty &&
                      result.ipa != null &&
                      result.ipa!.isNotEmpty)
                    const TextSpan(text: '  '),
                  if (result.ipa != null && result.ipa!.isNotEmpty)
                    TextSpan(
                      text: result.ipa!,
                      style: const TextStyle(
                        fontStyle: FontStyle.normal,
                        letterSpacing: 0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // English translation
          Text(
            result.translation,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Audio row — always present.
          // Community recordings (one button per speaker) when available;
          // otherwise a single on-demand TTS button.
          if (result.audio.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.audio
                  .map((a) => _AudioButton(
                speaker: a.speaker,
                isPlaying: widget.playingPath == a.localPath,
                onTap: () => widget.onPlay(a.localPath),
                color: accent,
              ))
                  .toList(),
            )
          else
            _TtsButton(
              isPlaying: _deviceTtsPlaying ||
                  (_ttsPath != null && widget.playingPath == _ttsPath),
              isLoading: _ttsLoading,
              onTap: _onTtsTap,
              color: accent,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Word type badge
// ═══════════════════════════════════════════════════════════════════════════════

class _WordTypeBadge extends StatelessWidget {
  final String type;
  final Color color;

  const _WordTypeBadge({required this.type, required this.color});

  static const _labels = <String, String>{
    // Nouns & pronouns
    'n': 'noun',
    'pn': 'pron.',
    'num': 'num.',
    // Verbs — Reykunyu uses colon-separated format
    'v:tr': 'v.tr.',
    'v:in': 'v.in.',
    'v:m': 'v.m.',
    'v:si': 'v.si.',
    'v:cp': 'v.cp.',
    // Older / alternate keys kept for compatibility
    'vtr': 'v.tr.',
    'vin': 'v.in.',
    'vim': 'v.m.',
    // Modifiers
    'adj': 'adj.',
    'adv': 'adv.',
    'adp': 'adp.',
    // Grammar
    'conj': 'conj.',
    'part': 'part.',
    'inter': 'interj.',
    'prep': 'prep.',
    // Affixes
    'aff:pre': 'prefix',
    'aff:in': 'infix',
    'aff:suf': 'suffix',
    'aff:len': 'lenition',
    // Other
    'ph': 'phrase',
    'nv': 'n.v.',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[type] ?? type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Audio play button
// ═══════════════════════════════════════════════════════════════════════════════

class _AudioButton extends StatelessWidget {
  final String speaker;
  final bool isPlaying;
  final VoidCallback onTap;
  final Color color;

  const _AudioButton({
    required this.speaker,
    required this.isPlaying,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPlaying ? color.withOpacity(0.18) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPlaying ? color : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying
                  ? Icons.stop_rounded
                  : Icons.volume_up_rounded,
              size: 14,
              color: isPlaying ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              speaker,
              style: TextStyle(
                fontSize: 12,
                color: isPlaying ? color : AppColors.textSecondary,
                fontWeight:
                isPlaying ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TTS fallback button (shown when no community recordings exist)
// ═══════════════════════════════════════════════════════════════════════════════

class _TtsButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final Color color;

  const _TtsButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPlaying ? color.withOpacity(0.18) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPlaying ? color : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            else
              Icon(
                isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 14,
                color: isPlaying ? color : AppColors.textSecondary,
              ),
            const SizedBox(width: 6),
            Text(
              isLoading ? 'Loading…' : 'Hear pronunciation',
              style: TextStyle(
                fontSize: 12,
                color: isLoading
                    ? AppColors.textSecondary
                    : isPlaying
                    ? color
                    : AppColors.textSecondary,
                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  History tile
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoryTile extends StatelessWidget {
  final DictionaryEntry entry;
  final VoidCallback onTap;

  const _HistoryTile({required this.entry, required this.onTap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final accent = entry.language.accentColor;
    final count = entry.results.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            // Language initial badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                entry.language.label[0], // 'N' or 'K'
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.query,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count result${count == 1 ? '' : 's'} · ${_timeAgo(entry.searchedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}