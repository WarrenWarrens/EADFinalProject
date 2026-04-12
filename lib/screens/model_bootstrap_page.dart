import 'package:flutter/material.dart';
import '../services/model_download_service.dart';
import '../theme/app_theme.dart';

/// Gates app startup on model availability. If all models are present,
/// calls [onReady] immediately. Otherwise shows a blocking download UI.
class ModelBootstrapPage extends StatefulWidget {
  final VoidCallback onReady;
  const ModelBootstrapPage({super.key, required this.onReady});

  @override
  State<ModelBootstrapPage> createState() => _ModelBootstrapPageState();
}

class _ModelBootstrapPageState extends State<ModelBootstrapPage> {
  DownloadProgress? _current;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final svc = ModelDownloadService();
    final missing = await svc.missingModels();
    if (missing.isEmpty) {
      if (mounted) widget.onReady();
      return;
    }

    try {
      await for (final p in svc.downloadMissing()) {
        if (!mounted) return;
        setState(() => _current = p);
      }
      if (!mounted) return;
      setState(() => _done = true);
      widget.onReady();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _formatMb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(0)} MB';

  @override
  Widget build(BuildContext context) {
    final p = _current;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_download_outlined,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Setting up LinguaLore',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Downloading language models. This happens once.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text('Download failed', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () { setState(() { _error = null; _current = null; }); _run(); },
                  child: const Text('Retry'),
                ),
              ] else if (p == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Checking for models…',
                    style: TextStyle(color: AppColors.textSecondary)),
              ] else ...[
                Text('${p.filename}  (${p.index}/${p.total})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.buttonSoft,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatMb(p.received)} / ${_formatMb(p.totalBytes)}  ·  ${(p.fraction * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}