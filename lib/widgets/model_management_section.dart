import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/model_download_service.dart';
import '../../theme/app_theme.dart';

/// Drop-in widget for the Settings tab — lists every known model
/// (ONNX phoneme scorer, .task LLM) and lets the user download or
/// delete each one individually.
///
/// Place it inside `_SettingsTab.build` like any other section, e.g.:
///
/// ```dart
///   _SettingsSectionHeader(label: 'Models'),
///   ModelManagementSection(accentColor: accent),
///   const SizedBox(height: 16),
/// ```
///
/// Self-contained — owns its own state, polls the service for status,
/// shows live progress while downloading, and confirms deletes.
class ModelManagementSection extends StatefulWidget {
  final Color accentColor;
  const ModelManagementSection({super.key, required this.accentColor});

  @override
  State<ModelManagementSection> createState() => _ModelManagementSectionState();
}

class _ModelManagementSectionState extends State<ModelManagementSection> {
  final _svc = ModelDownloadService();

  List<ModelStatus> _statuses = [];
  bool _loading = true;

  /// Per-model active download progress, keyed by filename.
  final Map<String, DownloadProgress> _progress = {};

  /// Per-model active subscriptions so we can cancel on dispose.
  final Map<String, StreamSubscription<DownloadProgress>> _subs = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final s = await _svc.statusAll();
      if (mounted) setState(() { _statuses = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startDownload(ModelSpec m) {
    if (_subs.containsKey(m.filename)) return; // already running
    final stream = _svc.downloadOne(m);
    final sub = stream.listen(
          (p) {
        if (!mounted) return;
        setState(() => _progress[m.filename] = p);
      },
      onDone: () async {
        _subs.remove(m.filename);
        if (mounted) setState(() => _progress.remove(m.filename));
        await _refresh();
      },
      onError: (e) async {
        _subs.remove(m.filename);
        if (mounted) {
          setState(() => _progress.remove(m.filename));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e')),
          );
        }
        await _refresh();
      },
    );
    _subs[m.filename] = sub;
  }

  Future<void> _confirmDelete(ModelSpec m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dark.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${m.displayName}?',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text(
          m.required
              ? "This model is required. Lessons that need it won't work "
              "until it's downloaded again."
              : "You can re-download it later from this screen.",
          style: const TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteModel(m);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
    await _refresh();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    final mb = bytes / 1024 / 1024;
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _statuses.length; i++) ...[
          _ModelTile(
            status: _statuses[i],
            progress: _progress[_statuses[i].spec.filename],
            accentColor: widget.accentColor,
            formatBytes: _formatBytes,
            onDownload: () => _startDownload(_statuses[i].spec),
            onDelete: () => _confirmDelete(_statuses[i].spec),
          ),
          if (i < _statuses.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ModelTile extends StatelessWidget {
  final ModelStatus status;
  final DownloadProgress? progress;
  final Color accentColor;
  final String Function(int) formatBytes;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ModelTile({
    required this.status,
    required this.progress,
    required this.accentColor,
    required this.formatBytes,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = status.spec;
    final downloading = progress != null;
    final installed = status.installed;

    final subtitle = downloading
        ? '${formatBytes(progress!.received)} / '
        '${formatBytes(progress!.totalBytes)}  ·  '
        '${(progress!.fraction * 100).toStringAsFixed(0)}%'
        : installed
        ? 'Installed  ·  ${formatBytes(status.actualBytes)}'
        : 'Not installed  ·  ${formatBytes(m.expectedBytes)} download';

    final statusColor = installed
        ? AppColors.success
        : (m.required ? AppColors.warning : const Color(0xFF888888));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  m.required
                      ? Icons.record_voice_over_rounded
                      : Icons.chat_bubble_outline_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m.required ? 'required' : 'optional',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              if (!downloading)
                if (installed)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                    tooltip: 'Delete',
                  )
                else
                  IconButton(
                    onPressed: onDownload,
                    icon: Icon(Icons.cloud_download_outlined,
                        color: accentColor, size: 20),
                    tooltip: 'Download',
                  )
              else
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress!.fraction,
                minHeight: 4,
                backgroundColor: const Color(0xFFEEEEEE),
                color: accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}