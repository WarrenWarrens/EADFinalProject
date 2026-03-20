import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_scatter/flutter_scatter.dart';
import '../../models/vocab_record.dart';
import '../../services/vocab_tracking_service.dart';
import '../../theme/app_theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _tracker = VocabTrackingService();
  List<VocabRecord> _records = [];
  ({int totalWords, int totalAttempts, double overallAvg})? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _tracker.getAllRecords();
    final summary = await _tracker.getSummary();
    if (mounted) {
      setState(() {
        _records = records;
        _summary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Your Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_outlined,
                size: 80, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No words tracked yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete some lessons and your\nword cloud will appear here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ───────────────────────────────────────────────
          if (_summary != null) _SummaryRow(summary: _summary!),
          const SizedBox(height: 24),

          // ── Legend ──────────────────────────────────────────────────────
          const _CloudLegend(),
          const SizedBox(height: 16),

          // ── Word cloud ─────────────────────────────────────────────────
          WordCloud(records: _records),
          const SizedBox(height: 28),

          // ── Word list breakdown ────────────────────────────────────────
          const Text(
            'Word Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._records.map((r) => _WordRow(record: r)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Summary row
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryRow extends StatelessWidget {
  final ({int totalWords, int totalAttempts, double overallAvg}) summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Words',
            value: '${summary.totalWords}',
            icon: Icons.abc_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Attempts',
            value: '${summary.totalAttempts}',
            icon: Icons.replay_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Avg Score',
            value: '${(summary.overallAvg * 100).round()}%',
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Cloud legend
// ═══════════════════════════════════════════════════════════════════════════════

class _CloudLegend extends StatelessWidget {
  const _CloudLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Text(
            'Colour:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          _dot(const Color(0xFF4CAF50)),
          const SizedBox(width: 4),
          const Text('Strong',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          _dot(const Color(0xFFFF9800)),
          const SizedBox(width: 4),
          const Text('OK',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          _dot(const Color(0xFFE53935)),
          const SizedBox(width: 4),
          const Text('Weak',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          const Text('Size = frequency',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Word cloud
// ═══════════════════════════════════════════════════════════════════════════════

class WordCloud extends StatelessWidget {
  final List<VocabRecord> records;
  const WordCloud({super.key, required this.records});

  /// Map rolling average (0.0–1.0) to a colour from deep red → amber → green.
  static Color scoreColor(double avg) {
    if (avg >= 0.75) {
      final t = ((avg - 0.75) / 0.25).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF8BC34A), const Color(0xFF2E7D32), t)!;
    } else if (avg >= 0.45) {
      final t = ((avg - 0.45) / 0.30).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFFFF9800), const Color(0xFF8BC34A), t)!;
    } else {
      final t = (avg / 0.45).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF9800), t)!;
    }
  }

  /// Logarithmic font size scaling.
  /// Prevents one very high-frequency word from dwarfing everything else.
  /// Min 14, max 48.
  static double fontSize(int attempts, int maxAttempts) {
    if (maxAttempts <= 1) return 22.0;
    final logAttempts = log(attempts.clamp(1, maxAttempts).toDouble());
    final logMax = log(maxAttempts.toDouble());
    final t = (logAttempts / logMax).clamp(0.0, 1.0);
    return 14.0 + t * 34.0;
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final maxAttempts =
    records.map((r) => r.totalAttempts).reduce((a, b) => a > b ? a : b);

    final children = records.map((r) {
      final size = fontSize(r.totalAttempts, maxAttempts);
      final color = scoreColor(r.rollingAverage);
      return Tooltip(
        message:
        '${r.displayText}\n${r.totalAttempts} attempts · '
            '${(r.rollingAverage * 100).round()}% recent avg',
        child: Text(
          r.displayText,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }).toList();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Scatter(
          fillGaps: true,
          delegate: ArchimedeanSpiralScatterDelegate(
            ratio: 0.6,
          ),
          children: children,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Word breakdown list
// ═══════════════════════════════════════════════════════════════════════════════

class _WordRow extends StatelessWidget {
  final VocabRecord record;
  const _WordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final avg = record.rollingAverage;
    final color = WordCloud.scoreColor(avg);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            // Colour indicator dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            // Word
            Expanded(
              child: Text(
                record.displayText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Attempts
            Text(
              '${record.totalAttempts}×',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            // Score bar
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: avg,
                  minHeight: 6,
                  backgroundColor: AppColors.inputBorder,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Percentage
            SizedBox(
              width: 36,
              child: Text(
                '${(avg * 100).round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}