import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/model_download_service.dart';
import '../theme/app_theme.dart';

/// Gates app startup on model availability with explicit user consent.
///
/// Two model classes:
///   • Required (ONNX phoneme scorer + small TTS assets): the app
///     fundamentally needs these to score pronunciation. We still ask
///     before downloading because the bundle can be 100s of MB.
///   • Optional (.task LLM, ~3 GB Gemma): powers the on-device Na'vi
///     conversation partner. The app works without it — that feature
///     is just disabled. User can defer or skip entirely.
///
/// ── Service contract this page assumes ────────────────────────────────
/// `ModelDownloadService` should expose:
///   - `Future<List<dynamic>> missingRequired()`
///   - `Future<List<dynamic>> missingOptional()` // returns the .task file(s)
///   - `Stream<DownloadProgress> downloadRequired()`
///   - `Stream<DownloadProgress> downloadOptional()`
///   - `int totalRequiredBytes()` and `int totalOptionalBytes()`
/// If your service still uses the old single `missingModels()` /
/// `downloadMissing()`, split internally by file extension
/// (`.task` → optional, everything else → required) and expose the four
/// methods above. The page logic does not need to know what each file is.
class ModelBootstrapPage extends StatefulWidget {
  final VoidCallback onReady;
  const ModelBootstrapPage({super.key, required this.onReady});

  @override
  State<ModelBootstrapPage> createState() => _ModelBootstrapPageState();
}

enum _Phase {
  checking,
  askRequired,
  downloadingReq,
  askOptional,
  downloadingOpt,
  done,
  error,
}

class _ModelBootstrapPageState extends State<ModelBootstrapPage> {
  final _svc = ModelDownloadService();

  _Phase _phase = _Phase.checking;
  DownloadProgress? _current;
  String? _error;

  int _requiredBytes = 0;
  int _optionalBytes = 0;
  bool _requiredMissing = false;
  bool _optionalMissing = false;

  static const _kLlmDeclinedKey = 'llm_download_declined';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final req = await _svc.missingRequired();
      final opt = await _svc.missingOptional();
      _requiredMissing = req.isNotEmpty;
      _optionalMissing = opt.isNotEmpty;
      _requiredBytes = _svc.totalRequiredBytes();
      _optionalBytes = _svc.totalOptionalBytes();

      if (!mounted) return;

      if (_requiredMissing) {
        setState(() => _phase = _Phase.askRequired);
        return;
      }
      await _maybeAskOptional();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = _Phase.error;
        });
      }
    }
  }

  Future<void> _maybeAskOptional() async {
    // Skip if already on disk, or if user previously chose "Don't ask again".
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getBool(_kLlmDeclinedKey) ?? false;
    if (!_optionalMissing || declined) {
      _finish();
      return;
    }
    if (mounted) setState(() => _phase = _Phase.askOptional);
  }

  Future<void> _runRequired() async {
    if (mounted) setState(() => _phase = _Phase.downloadingReq);
    try {
      await for (final p in _svc.downloadRequired()) {
        if (!mounted) return;
        setState(() => _current = p);
      }
      if (!mounted) return;
      _current = null;
      await _maybeAskOptional();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = _Phase.error;
        });
      }
    }
  }

  Future<void> _runOptional() async {
    if (mounted) setState(() => _phase = _Phase.downloadingOpt);
    try {
      await for (final p in _svc.downloadOptional()) {
        if (!mounted) return;
        setState(() => _current = p);
      }
      if (!mounted) return;
      _finish();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = _Phase.error;
        });
      }
    }
  }

  Future<void> _declineOptional() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLlmDeclinedKey, true);
    _finish();
  }

  void _finish() {
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    widget.onReady();
  }

  String _formatMb(int bytes) {
    if (bytes <= 0) return '—';
    final mb = bytes / 1024 / 1024;
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: switch (_phase) {
            _Phase.checking => _buildChecking(),
            _Phase.askRequired => _buildAskRequired(),
            _Phase.downloadingReq =>
                _buildDownloading('Downloading language models'),
            _Phase.askOptional => _buildAskOptional(),
            _Phase.downloadingOpt =>
                _buildDownloading('Downloading conversation model'),
            _Phase.done => _buildChecking(),
            _Phase.error => _buildError(),
          },
        ),
      ),
    );
  }

  Widget _buildChecking() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Checking installed models…',
            style: TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );

  Widget _buildAskRequired() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_download_outlined,
            size: 72, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text(
          'Set up LinguaLore',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'LinguaLore needs to download its language models to score your '
              'pronunciation on-device. This happens once. Nothing is sent '
              'over the internet after this.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        _InfoChip(
          icon: Icons.download_rounded,
          label: 'Download size',
          value: _formatMb(_requiredBytes),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _runRequired,
          child: const Text('Download & continue'),
        ),
      ],
    );
  }

  Widget _buildAskOptional() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 72, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text(
          'Want a conversation partner?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'LinguaLore can run an on-device Na\'vi tutor (Teylan) for free '
              'practice conversations. This is optional — lessons and '
              'pronunciation work without it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        _InfoChip(
          icon: Icons.sd_storage_outlined,
          label: 'Download size',
          value: _formatMb(_optionalBytes),
          warning: _optionalBytes > 1024 * 1024 * 1024,
        ),
        const SizedBox(height: 8),
        const Text(
          'Best on Wi-Fi. You can download this later from Settings.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _runOptional,
          child: const Text('Download conversation model'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _finish,
          child: const Text('Skip for now'),
        ),
        TextButton(
          onPressed: _declineOptional,
          child: const Text("Don't ask again"),
        ),
      ],
    );
  }

  Widget _buildDownloading(String heading) {
    final p = _current;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_download_outlined,
            size: 72, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(heading,
            style:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        if (p == null) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Starting download…',
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
            '${_formatMb(p.received)} / ${_formatMb(p.totalBytes)}  ·  '
                '${(p.fraction * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildError() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline,
          color: AppColors.error, size: 56),
      const SizedBox(height: 12),
      const Text('Download failed',
          style: TextStyle(
              color: AppColors.error, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(_error ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _error = null;
            _current = null;
            _phase = _Phase.checking;
          });
          _check();
        },
        child: const Text('Retry'),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool warning;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}