import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' show sqrt;

/// On-device Na'vi phoneme recognizer backed by a fine-tuned Wav2Vec2 CTC
/// model exported to ONNX. Takes a 16-kHz mono PCM16 WAV file recorded by
/// `audio_mimicry_screen.dart` and returns the predicted IPA string plus an
/// edit-distance similarity score against a target IPA.
class NaviIpaService {
  static final NaviIpaService _instance = NaviIpaService._();
  factory NaviIpaService() => _instance;
  NaviIpaService._();

  OrtSession? _session;
  List<String>? _idToToken;   // index → IPA character
  int _padId = 0;             // blank / pad token id (CTC blank)

  bool get isReady => _session != null;

  /// Call once at app startup or first use. Loads vocab from assets and
  /// the ONNX model from the device documents directory.
  Future<void> init() async {
    if (_session != null) return;

    // ── Init ORT runtime ─────────────────────────────────────────────────
    OrtEnv.instance.init();

    // ── Load vocab (id → IPA char) ───────────────────────────────────────
    final vocabRaw = await rootBundle.loadString(
      'assets/models/navi_ipa/vocab.json',
    );
    final Map<String, dynamic> vocab = jsonDecode(vocabRaw);
    final size = vocab.values.map((v) => v as int).reduce((a, b) => a > b ? a : b) + 1;
    _idToToken = List.filled(size, '');
    vocab.forEach((tok, id) => _idToToken![id as int] = tok);
    _padId = vocab['<pad>'] ?? vocab['[PAD]'] ?? 0;

    // ── Load model from device storage ───────────────────────────────────
    final dir = await getExternalStorageDirectory();
    final modelPath = '${dir!.path}/navi_ipa.onnx';
    if (!await File(modelPath).exists()) {
      throw StateError('ONNX model not found at $modelPath');
    }
    final bytes = await File(modelPath).readAsBytes();
    final options = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, options);
  }

  /// Transcribe a 16-kHz mono PCM16 WAV to IPA.
  Future<String> transcribe(String wavPath) async {
    if (_session == null) throw StateError('NaviIpaService.init() not called.');

    final pcm = _readPcm16Wav(wavPath);
    print('[IPA] samples=${pcm.length}, '
        'dur=${(pcm.length / 16000).toStringAsFixed(2)}s, '
        'min=${pcm.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)}, '
        'max=${pcm.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}, '
        'nonzero=${pcm.where((v) => v.abs() > 0.01).length}');

    final audioLen = pcm.length;

    // Normalize to zero mean / unit variance — the processor does this.
    final samples = _normalize(pcm);

    // Shape [1, audio_length]
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      samples,
      [1, audioLen],
    );
    final inputs = {'input_values': inputTensor};

    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);
    final logits = outputs![0]!.value as List; // [1][seq][vocab]

    inputTensor.release();
    runOptions.release();
    for (final o in outputs) { o?.release(); }

    return _ctcDecode(logits[0] as List);
  }

  /// Compare a user attempt against a target IPA. Returns a score in [0,1]
  /// where 1.0 is a perfect match.
  Future<({String heard, String expected, double score})> score({
    required String wavPath,
    required String expectedIpa,
  }) async {
    final heard = await transcribe(wavPath);
    final dist = _editDistance(heard, expectedIpa);
    final maxLen = heard.length > expectedIpa.length ? heard.length : expectedIpa.length;
    final s = maxLen == 0 ? 0.0 : 1.0 - (dist / maxLen);
    return (heard: heard, expected: expectedIpa, score: s.clamp(0.0, 1.0));
  }

  // ── WAV → Float32 PCM ──────────────────────────────────────────────────
  Float32List _readPcm16Wav(String path) {
    final bytes = File(path).readAsBytesSync();
    // Standard RIFF PCM16 header is 44 bytes. Some tools emit 46+ with LIST
    // chunks — search for "data" chunk if needed.
    int dataOffset = 44;
    final s = String.fromCharCodes(bytes.sublist(36, 40));
    if (s != 'data') {
      // Walk chunks until we find "data"
      int i = 12;
      while (i < bytes.length - 8) {
        final id = String.fromCharCodes(bytes.sublist(i, i + 4));
        final size = ByteData.sublistView(bytes, i + 4, i + 8).getUint32(0, Endian.little);
        if (id == 'data') { dataOffset = i + 8; break; }
        i += 8 + size;
      }
    }
    final bd = ByteData.sublistView(bytes, dataOffset);
    final n = (bytes.length - dataOffset) ~/ 2;
    final out = Float32List(n);
    for (int i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  Float32List _normalize(Float32List x) {
    if (x.isEmpty) return x;
    double mean = 0;
    for (final v in x) mean += v;
    mean /= x.length;

    double variance = 0;
    for (final v in x) {
      final d = v - mean;
      variance += d * d;
    }
    variance /= x.length;

    final std = sqrt(variance + 1e-7);   // ← was sqrt(variance)
    final invStd = 1.0 / std;            // ← always divide, no conditional

    final out = Float32List(x.length);
    for (int i = 0; i < x.length; i++) {
      out[i] = (x[i] - mean) * invStd;
    }
    return out;
  }

  // ── CTC greedy decode with blank collapse ──────────────────────────────
  String _ctcDecode(List seq) {
    final buf = StringBuffer();
    int prev = -1;
    for (final frame in seq) {
      // Find argmax
      double best = double.negativeInfinity;
      int id = 0;
      for (int j = 0; j < frame.length; j++) {
        final v = (frame[j] as num).toDouble();
        if (v > best) { best = v; id = j; }
      }
      // CTC collapse: skip pad (blank) and consecutive duplicates
      if (id == _padId || id == prev) { prev = id; continue; }
      prev = id;

      final tok = _idToToken![id];
      if (tok == '[PAD]' || tok == '[UNK]') continue;
      if (tok == '|') { buf.write(' '); continue; }   // word separator → space
      buf.write(tok);
    }
    return buf.toString().trim();
  }

  // ── Levenshtein edit distance ──────────────────────────────────────────
  int _editDistance(String a, String b) {
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    final dp = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    for (int i = 0; i <= la; i++) dp[i][0] = i;
    for (int j = 0; j <= lb; j++) dp[0][j] = j;
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        final cost = a[i-1] == b[j-1] ? 0 : 1;
        dp[i][j] = [
          dp[i-1][j] + 1,
          dp[i][j-1] + 1,
          dp[i-1][j-1] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
    }
    return dp[la][lb];
  }

  Future<void> dispose() async {
    _session?.release();
    _session = null;
    OrtEnv.instance.release();
  }
}