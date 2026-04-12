import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_scatter/flutter_scatter.dart';

import '../../models/vocab_record.dart';
import '../../services/vocab_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_language.dart';

class VocabDetailPage extends StatefulWidget {
  final AppLanguage language;
  final int initialTab; // 0 = cloud, 1 = dictionary

  const VocabDetailPage({
    super.key,
    required this.language,
    this.initialTab = 0,
  });

  @override
  State<VocabDetailPage> createState() => _VocabDetailPageState();
}

class _VocabDetailPageState extends State<VocabDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<VocabRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final records = await VocabTrackingService().getAllRecords();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  void _openWordDetail(VocabRecord r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WordDetailSheet(record: r, accent: widget.language.accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final accent = widget.language.accentColor;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: const Text('Your Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: palette.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.cloud_rounded), text: 'Word Cloud'),
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Dictionary'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _emptyState(palette)
          : TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _CloudTab(records: _records, accent: accent, onTapWord: _openWordDetail),
          _DictionaryTab(records: _records, accent: accent, onTapWord: _openWordDetail),
        ],
      ),
    );
  }

  Widget _emptyState(dynamic palette) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_outlined, size: 72, color: palette.textMuted),
          const SizedBox(height: 16),
          Text('No words practiced yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.textPrimary)),
          const SizedBox(height: 8),
          Text('Complete a lesson to start tracking.',
              style: TextStyle(color: palette.textMuted)),
        ],
      ),
    ),
  );
}

// ── Score → color (shared) ────────────────────────────────────────────────

Color scoreColor(double avg) {
  if (avg >= 0.75) {
    final t = ((avg - 0.75) / 0.25).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF8BC34A), const Color(0xFF2E7D32), t)!;
  } else if (avg >= 0.45) {
    final t = ((avg - 0.45) / 0.30).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFFF9800), const Color(0xFF8BC34A), t)!;
  }
  final t = (avg / 0.45).clamp(0.0, 1.0);
  return Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF9800), t)!;
}

// ── Cloud tab ─────────────────────────────────────────────────────────────

class _CloudTab extends StatelessWidget {
  final List<VocabRecord> records;
  final Color accent;
  final ValueChanged<VocabRecord> onTapWord;

  const _CloudTab(
      {required this.records, required this.accent, required this.onTapWord});

  @override
  Widget build(BuildContext context) {
    final maxAttempts = records.map((r) => r.totalAttempts).reduce(max);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 480,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.dark.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(200),
          clipBehavior: Clip.none,
          child: Center(
            child: Scatter(
              fillGaps: true,
              delegate: ArchimedeanSpiralScatterDelegate(ratio: 0.65),
              children: records.map((r) {
                final logA = log(r.totalAttempts.clamp(1, maxAttempts).toDouble());
                final logM = log(maxAttempts.toDouble().clamp(2, double.infinity));
                final t = (logA / logM).clamp(0.0, 1.0);
                final fontSize = 16.0 + t * 32.0;
                return GestureDetector(
                  onTap: () => onTapWord(r),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      r.displayText,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: scoreColor(r.rollingAverage),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dictionary tab ────────────────────────────────────────────────────────

class _DictionaryTab extends StatelessWidget {
  final List<VocabRecord> records;
  final Color accent;
  final ValueChanged<VocabRecord> onTapWord;
  const _DictionaryTab({required this.records, required this.accent, required this.onTapWord});

  @override
  Widget build(BuildContext context) {
    final sorted = [...records]
      ..sort((a, b) => a.displayText.toLowerCase().compareTo(b.displayText.toLowerCase()));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = sorted[i];
        final color = scoreColor(r.rollingAverage);
        return Material(
          color: AppTheme.dark.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onTapWord(r),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.displayText,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${r.totalAttempts} attempts',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                  _MiniStat(icon: Icons.mic_rounded, value: r.vocalAverage, accent: accent),
                  const SizedBox(width: 10),
                  _MiniStat(icon: Icons.edit_note_rounded, value: r.nonVocalAverage, accent: accent),
                  const SizedBox(width: 14),
                  Text('${(r.rollingAverage * 100).round()}%',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final double? value;
  final Color accent;
  const _MiniStat({required this.icon, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: v == null ? const Color(0xFF555555) : accent),
        const SizedBox(height: 2),
        Text(
          v == null ? '—' : '${(v * 100).round()}',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: v == null ? const Color(0xFF666666) : Colors.white),
        ),
      ],
    );
  }
}

// ── Word detail bottom sheet ──────────────────────────────────────────────

class _WordDetailSheet extends StatelessWidget {
  final VocabRecord record;
  final Color accent;
  const _WordDetailSheet({required this.record, required this.accent});

  @override
  Widget build(BuildContext context) {
    final vocal = record.vocalScores;
    final nonVocal = record.nonVocalScores;
    final color = scoreColor(record.rollingAverage);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(record.displayText,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('${record.totalAttempts} total attempts',
              style: const TextStyle(color: Color(0xFF999999))),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: _OverallCard(
                label: 'Overall', value: record.rollingAverage, color: color)),
            const SizedBox(width: 10),
            Expanded(child: _OverallCard(
                label: '🎤 Vocal', value: record.vocalAverage, color: accent)),
            const SizedBox(width: 10),
            Expanded(child: _OverallCard(
                label: '📝 Non-vocal', value: record.nonVocalAverage, color: accent)),
          ]),

          const SizedBox(height: 24),
          const Text('Recent attempts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          if (vocal.isNotEmpty) _ScoreRow(label: 'Vocal', scores: vocal, accent: accent),
          if (vocal.isNotEmpty && nonVocal.isNotEmpty) const SizedBox(height: 10),
          if (nonVocal.isNotEmpty) _ScoreRow(label: 'Non-vocal', scores: nonVocal, accent: accent),
          if (vocal.isEmpty && nonVocal.isEmpty)
            const Text('No attempts recorded yet.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const _OverallCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(v == null ? '—' : '${(v * 100).round()}%',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: v == null ? const Color(0xFF666666) : color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final List<double> scores;
  final Color accent;
  const _ScoreRow({required this.label, required this.scores, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Row(
              children: scores.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 4 + s * 34,
                      decoration: BoxDecoration(
                        color: scoreColor(s),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}