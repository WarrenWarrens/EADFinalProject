import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Definition of a downloadable model file.
class ModelSpec {
  final String filename;      // local filename on device
  final String url;           // full download URL
  final int expectedBytes;    // used to detect partial files + show progress
  final bool required;        // if true, app cannot start without it
  final String displayName;   // shown to user in the splash

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
  final int index;           // 1-based position in the queue
  final int total;           // total files in the queue
  final int received;        // bytes received for current file
  final int totalBytes;      // expected bytes for current file
  final String status;       // 'checking' | 'downloading' | 'verifying' | 'done' | 'error'
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

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._();

  static const List<ModelSpec> models = [
    ModelSpec(
      filename: 'navi_ipa.onnx',
      url: 'https://github.com/WarrenWarrens/EADFinalProject/releases/download/models-v1/navi_ipa.onnx',
      expectedBytes: 355054890,
      displayName: "Na'vi pronunciation model",
    ),
    ModelSpec(
      filename: 'gemma-3n-E2B-it-int4.task',
      url: 'https://huggingface.co/FUNFUN32/gemma-3n-E2B-it-int4.task/resolve/main/gemma-3n-E2B-it-int4.task',
      expectedBytes: 3136226711,  // ← see note below
      displayName: 'Conversation model (Teylan)',
    ),
  ];

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  /// Check which models are missing without downloading anything.
  /// Considers a file "missing" if it doesn't exist OR is smaller than
  /// expected (handles interrupted previous downloads).
  Future<List<ModelSpec>> missingModels() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw StateError('No external storage available');

    final missing = <ModelSpec>[];
    for (final m in models) {
      final f = File('${dir.path}/${m.filename}');
      if (!await f.exists()) {
        missing.add(m);
        continue;
      }
      final size = await f.length();
      // Allow a 1% slop on expected size to tolerate inexact hand-entered values.
      final minOk = (m.expectedBytes * 0.99).round();
      if (size < minOk) missing.add(m);
    }
    return missing;
  }

  /// Download all missing models. Emits progress events; completes when done.
  /// Uses HTTP Range headers so partial downloads resume instead of restart.
  Stream<DownloadProgress> downloadMissing() async* {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw StateError('No external storage available');
    }

    final queue = await missingModels();
    if (queue.isEmpty) return;

    for (int i = 0; i < queue.length; i++) {
      final m = queue[i];
      final dest = '${dir.path}/${m.filename}';
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

      // Run the download in the background, forwarding progress into our stream.
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
          // `received` from dio is bytes of this response; if we resumed via
          // Range header, add the bytes we already had on disk.
          final effectiveReceived = already + received;
          final effectiveTotal = m.expectedBytes;
          controller.add(DownloadProgress(
            filename: m.displayName,
            index: i + 1,
            total: queue.length,
            received: effectiveReceived,
            totalBytes: effectiveTotal,
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