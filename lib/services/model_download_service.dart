import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Definition of a downloadable model file.
class ModelSpec {
  final String filename;
  final String url;
  final int expectedBytes;
  final bool required;
  final String displayName;

  const ModelSpec({
    required this.filename,
    required this.url,
    required this.expectedBytes,
    required this.displayName,
    this.required = true,
  });
}

/// Progress snapshot broadcast via the download stream.
class DownloadProgress {
  final String filename;
  final int index;
  final int total;
  final int received;
  final int totalBytes;
  final String status; // 'downloading' | 'done' | 'error'
  final String? error;

  const DownloadProgress({
    required this.filename,
    required this.index,
    required this.total,
    required this.received,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  double get fraction =>
      totalBytes == 0 ? 0 : (received / totalBytes).clamp(0.0, 1.0);
}

/// Snapshot of one model's on-disk state, for the settings page.
class ModelStatus {
  final ModelSpec spec;
  final bool installed;
  final int actualBytes;

  const ModelStatus({
    required this.spec,
    required this.installed,
    required this.actualBytes,
  });
}

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._();

  /// All known model files. The Gemma `.task` LLM is marked optional so
  /// the bootstrap page can ask about it separately — the app works fine
  /// without it (just no Teylan conversation partner).
  static const List<ModelSpec> models = [
    ModelSpec(
      filename: 'navi_ipa.onnx',
      url:
      'https://github.com/WarrenWarrens/EADFinalProject/releases/download/models-v1/navi_ipa.onnx',
      expectedBytes: 355054890,
      displayName: "Na'vi pronunciation model",
      required: true,
    ),
    ModelSpec(
      filename: 'gemma-3n-E2B-it-int4.task',
      url:
      'https://huggingface.co/FUNFUN32/gemma-3n-E2B-it-int4.task/resolve/main/gemma-3n-E2B-it-int4.task',
      expectedBytes: 3136226711,
      displayName: 'Conversation model (Teylan)',
      required: false,
    ),
  ];

  static List<ModelSpec> get _required =>
      models.where((m) => m.required).toList();
  static List<ModelSpec> get _optional =>
      models.where((m) => !m.required).toList();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  // ── Path helpers ───────────────────────────────────────────────────────

  Future<String> _pathFor(ModelSpec m) async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw StateError('No external storage available');
    return '${dir.path}/${m.filename}';
  }

  /// Find a spec by filename. Throws if unknown.
  ModelSpec specByFilename(String filename) =>
      models.firstWhere((m) => m.filename == filename);

  // ── Size accessors ─────────────────────────────────────────────────────

  int totalRequiredBytes() =>
      _required.fold(0, (sum, m) => sum + m.expectedBytes);

  int totalOptionalBytes() =>
      _optional.fold(0, (sum, m) => sum + m.expectedBytes);

  // ── Status / missing-file checks ───────────────────────────────────────

  /// Per-model installed/size status, used by the settings page.
  Future<List<ModelStatus>> statusAll() async {
    final out = <ModelStatus>[];
    for (final m in models) {
      final f = File(await _pathFor(m));
      final exists = await f.exists();
      final size = exists ? await f.length() : 0;
      // Same 1% slop as the missing-check.
      final minOk = (m.expectedBytes * 0.99).round();
      out.add(ModelStatus(
        spec: m,
        installed: exists && size >= minOk,
        actualBytes: size,
      ));
    }
    return out;
  }

  Future<List<ModelSpec>> missingModels() async => _missingFrom(models);
  Future<List<ModelSpec>> missingRequired() async => _missingFrom(_required);
  Future<List<ModelSpec>> missingOptional() async => _missingFrom(_optional);

  Future<List<ModelSpec>> _missingFrom(List<ModelSpec> set) async {
    final missing = <ModelSpec>[];
    for (final m in set) {
      final f = File(await _pathFor(m));
      if (!await f.exists()) {
        missing.add(m);
        continue;
      }
      final size = await f.length();
      final minOk = (m.expectedBytes * 0.99).round();
      if (size < minOk) missing.add(m);
    }
    return missing;
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Delete a single model file from disk. No-op if not present.
  Future<void> deleteModel(ModelSpec m) async {
    final f = File(await _pathFor(m));
    if (await f.exists()) await f.delete();
  }

  // ── Download streams ───────────────────────────────────────────────────

  Stream<DownloadProgress> downloadMissing() => _downloadSet(models);
  Stream<DownloadProgress> downloadRequired() => _downloadSet(_required);
  Stream<DownloadProgress> downloadOptional() => _downloadSet(_optional);

  /// Download a single named model. Useful for the settings page where
  /// the user picks one specific model to (re)download.
  Stream<DownloadProgress> downloadOne(ModelSpec m) => _downloadSet([m]);

  /// Internal: download every missing item from [set], emitting progress.
  /// Uses HTTP Range headers so partial downloads resume instead of
  /// restarting from zero.
  Stream<DownloadProgress> _downloadSet(List<ModelSpec> set) async* {
    final queue = await _missingFrom(set);
    if (queue.isEmpty) return;

    for (int i = 0; i < queue.length; i++) {
      final m = queue[i];
      final dest = await _pathFor(m);
      final partial = File(dest);
      final already = await partial.exists() ? await partial.length() : 0;

      yield DownloadProgress(
        filename: m.displayName,
        index: i + 1,
        total: queue.length,
        received: already,
        totalBytes: m.expectedBytes,
        status: 'downloading',
      );

      final controller = StreamController<DownloadProgress>();
      final cancelToken = CancelToken();

      final downloadFuture = _dio.download(
        m.url,
        dest,
        cancelToken: cancelToken,
        deleteOnError: false, // keep partial file so we can resume
        options: Options(
          headers: already > 0 ? {'Range': 'bytes=$already-'} : null,
          responseType: ResponseType.stream,
          followRedirects: true,
        ),
        onReceiveProgress: (received, total) {
          final effectiveReceived = already + received;
          controller.add(DownloadProgress(
            filename: m.displayName,
            index: i + 1,
            total: queue.length,
            received: effectiveReceived,
            totalBytes: m.expectedBytes,
            status: 'downloading',
          ));
        },
      );

      final completer = Completer<void>();

      downloadFuture.then((_) {
        if (!controller.isClosed) controller.close();
        completer.complete();
      }).catchError((e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          controller.close();
        }
        completer.completeError(e, st);
      });

      try {
        await for (final p in controller.stream) {
          yield p;
        }
        await completer.future;
      } catch (e) {
        yield DownloadProgress(
          filename: m.displayName,
          index: i + 1,
          total: queue.length,
          received: 0,
          totalBytes: m.expectedBytes,
          status: 'error',
          error: e.toString(),
        );
        rethrow;
      }
    }
  }
}