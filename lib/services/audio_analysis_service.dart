// lib/services/audio_analysis_service.dart
//
// Offline audio similarity scoring using MFCC + Dynamic Time Warping.
//
// Pipeline:
//   1. Read raw PCM samples from WAV files (16-bit mono)
//   2. Trim leading/trailing silence (amplitude threshold)
//   3. Noise gate — reject attempt if median spectral flatness > 0.72
//      (catches blowing, wind, mic-rubbing — broadband noise scores near 1.0)
//   4. Estimate noise PSD from the quietest 10 % of frames (minimum statistics)
//   5. Pre-emphasise, frame, window (Hamming)
//   6. Compute power spectrum via FFT
//   7. Berouti spectral subtraction on attempt frames (α=2, β=0.01)
//   8. Apply Mel filterbank → log energies
//   9. DCT → 13 MFCCs per frame
//  10. Compare reference vs. denoised attempt with DTW
//  11. Normalise DTW distance → 0.0–1.0 similarity score
//
// No native code, no plugins, no network calls.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// ═══════════════════════════════════════════════════════════════════════════════
//  Public API
// ═══════════════════════════════════════════════════════════════════════════════

class AudioAnalysisResult {
  /// 0.0 = completely different, 1.0 = identical
  final double score;

  /// Human-readable feedback string
  final String feedback;

  /// Per-segment match ratios (for future visualisation)
  final List<double> segmentScores;

  const AudioAnalysisResult({
    required this.score,
    required this.feedback,
    this.segmentScores = const [],
  });
}

class AudioAnalysisService {
  /// Compare two audio files and return a similarity score.
  ///
  /// [referencePath] — the correct pronunciation (TTS / Reykunyu mp3/wav)
  /// [attemptPath]   — the user's recorded attempt (WAV 16-bit mono)
  ///
  /// Both files must be WAV. The caller is responsible for recording in WAV
  /// format (Codec.pcm16WAV in flutter_sound).
  ///
  /// For MP3 reference files (from TTS), convert them to WAV first using
  /// flutter_sound's conversion utilities, or re-record via just_audio playback
  /// into a WAV file.  See [convertToWav] helper below.
  static Future<AudioAnalysisResult> compare({
    required String referencePath,
    required String attemptPath,
  }) async {
    try {
      // 1. Read raw PCM samples from both files
      final refSamples = await _readWavSamples(referencePath);
      final attSamples = await _readWavSamples(attemptPath);

      if (refSamples.isEmpty || attSamples.isEmpty) {
        return const AudioAnalysisResult(
          score: 0.0,
          feedback: 'Could not read audio — try recording again',
        );
      }

      // 2. Trim silence from both ends (below -40 dB ≈ amplitude < 0.01)
      final refTrimmed = _trimSilence(refSamples);
      final attTrimmed = _trimSilence(attSamples);

      if (refTrimmed.length < 400 || attTrimmed.length < 400) {
        return const AudioAnalysisResult(
          score: 0.0,
          feedback: 'Recording too short — speak louder or longer',
        );
      }

      // 3. Noise gate — reject attempts that are broadband noise (blowing, wind,
      //    mic-rubbing, etc.).  Spectral flatness near 1.0 means energy is spread
      //    uniformly across all bins with no formant structure.
      final flatness = _medianSpectralFlatness(attTrimmed);
      if (flatness > _noiseFlatnessThreshold) {
        print('[AudioAnalysis] Noise gate: flatness=${flatness.toStringAsFixed(3)} '
            '> threshold=$_noiseFlatnessThreshold — rejected');
        return const AudioAnalysisResult(
          score: 0.0,
          feedback: 'That sounded like noise — try speaking clearly into the mic',
        );
      }

      // 4. Estimate noise floor from the quietest frames of the attempt, then
      //    apply Berouti spectral subtraction during MFCC extraction.
      final noisePsd = _estimateNoisePsd(attTrimmed);

      // 5. Extract MFCC features (reference is clean TTS — no denoising needed)
      final refMfcc = _extractMfcc(refTrimmed);
      final attMfcc = _extractMfcc(attTrimmed, noisePsd: noisePsd);

      if (refMfcc.isEmpty || attMfcc.isEmpty) {
        return const AudioAnalysisResult(
          score: 0.0,
          feedback: 'Could not analyse audio — try again',
        );
      }

      // 6. DTW comparison
      final dtwResult = _dtw(refMfcc, attMfcc);
      final rawDistance = dtwResult.normalisedDistance;

      // 7. Convert distance to similarity score (0–1)
      // Empirical mapping: distance of 0 → score 1.0, distance ≥ 25 → score 0.0
      // The sigmoid-like mapping gives more granularity in the 50-90% range.
      final score = _distanceToScore(rawDistance);

      // 8. Generate per-segment scores for the UI
      final segmentScores = _computeSegmentScores(dtwResult.path, refMfcc, attMfcc);

      // 9. Generate feedback
      final feedback = _generateFeedback(score, refTrimmed.length, attTrimmed.length);

      print('[AudioAnalysis] flatness=${flatness.toStringAsFixed(3)}, '
          'DTW distance: ${rawDistance.toStringAsFixed(2)}, '
          'score: ${(score * 100).round()}%, '
          'ref frames: ${refMfcc.length}, att frames: ${attMfcc.length}');

      return AudioAnalysisResult(
        score: score,
        feedback: feedback,
        segmentScores: segmentScores,
      );
    } catch (e) {
      print('[AudioAnalysis] Error: $e');
      return AudioAnalysisResult(
        score: 0.0,
        feedback: 'Analysis error: ${e.toString().split('\n').first}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WAV file reading
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parse a WAV file and return normalised float samples (-1.0 to 1.0).
  /// Supports 16-bit PCM mono WAV files (what flutter_sound records).
  static Future<Float64List> _readWavSamples(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      print('[AudioAnalysis] File not found: $path');
      return Float64List(0);
    }

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    // Validate RIFF header
    if (bytes.length < 44) {
      print('[AudioAnalysis] File too small for WAV: ${bytes.length} bytes');
      return Float64List(0);
    }

    // Find "RIFF" marker
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      print('[AudioAnalysis] Not a WAV file (no RIFF header): $path');
      return Float64List(0);
    }

    // Find "data" chunk — scan forward from byte 36
    int dataOffset = -1;
    int dataSize = 0;
    for (int i = 36; i < bytes.length - 8; i++) {
      if (bytes[i] == 0x64 &&     // 'd'
          bytes[i + 1] == 0x61 && // 'a'
          bytes[i + 2] == 0x74 && // 't'
          bytes[i + 3] == 0x61) { // 'a'
        dataOffset = i + 8; // skip "data" + 4-byte size
        dataSize = data.getUint32(i + 4, Endian.little);
        break;
      }
    }

    if (dataOffset < 0) {
      print('[AudioAnalysis] No data chunk found in WAV');
      return Float64List(0);
    }

    // Read audio format info
    final audioFormat = data.getUint16(20, Endian.little);
    final numChannels = data.getUint16(22, Endian.little);
    final sampleRate  = data.getUint32(24, Endian.little);
    final bitsPerSample = data.getUint16(34, Endian.little);

    print('[AudioAnalysis] WAV: ${sampleRate}Hz, ${bitsPerSample}bit, '
        '${numChannels}ch, format=$audioFormat, dataSize=$dataSize');

    if (audioFormat != 1) {
      // 1 = PCM. Other formats (e.g. compressed) not supported.
      print('[AudioAnalysis] Unsupported WAV format: $audioFormat (need PCM=1)');
      return Float64List(0);
    }

    // Parse 16-bit PCM samples
    final bytesPerSample = bitsPerSample ~/ 8;
    final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
    final samples = Float64List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final offset = dataOffset + i * bytesPerSample * numChannels;
      if (offset + bytesPerSample > bytes.length) break;

      if (bitsPerSample == 16) {
        final raw = data.getInt16(offset, Endian.little);
        samples[i] = raw / 32768.0;
      } else if (bitsPerSample == 8) {
        samples[i] = (bytes[offset] - 128) / 128.0;
      }
    }

    return samples;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Pre-processing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Trim leading/trailing silence below the given amplitude threshold.
  static Float64List _trimSilence(Float64List samples, {double threshold = 0.01}) {
    int start = 0;
    int end = samples.length - 1;

    // Find first sample above threshold
    while (start < end && samples[start].abs() < threshold) {
      start++;
    }
    // Find last sample above threshold
    while (end > start && samples[end].abs() < threshold) {
      end--;
    }

    // Add small padding (50ms at 16kHz = 800 samples) to avoid clipping
    start = max(0, start - 800);
    end = min(samples.length - 1, end + 800);

    return Float64List.sublistView(samples, start, end + 1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Noise detection & denoising
  // ═══════════════════════════════════════════════════════════════════════════

  /// Spectral flatness threshold above which an attempt is treated as noise.
  ///
  /// Speech: median flatness ≈ 0.05–0.35 (formant peaks break up the spectrum).
  /// Blowing / wind: flatness ≈ 0.65–0.95 (energy spread flat across all bins).
  /// A value of 0.72 gives a comfortable gap between speech and blowing while
  /// staying tolerant of unusual phonemes (Na'vi ejectives, Klingon uvulars).
  static const double _noiseFlatnessThreshold = 0.72;

  /// Returns the median per-frame spectral flatness (Wiener entropy) of [samples].
  ///
  /// Flatness = geometric_mean(power) / arithmetic_mean(power) per frame.
  /// Only frames with meaningful energy are included so silence padding doesn't
  /// drag the median down.
  static double _medianSpectralFlatness(Float64List samples) {
    final hamming = _hammingWindow(_frameLength);
    final flatnesses = <double>[];

    for (int start = 0; start + _frameLength <= samples.length; start += _frameStep) {
      final frame = Float64List(_fftSize);
      for (int i = 0; i < _frameLength; i++) {
        frame[i] = samples[start + i] * hamming[i];
      }

      final spectrum = _powerSpectrum(frame);

      // Skip frames below a modest energy floor (silence / very quiet regions)
      final energy = spectrum.fold(0.0, (double a, double b) => a + b);
      if (energy < 1e-6) continue;

      // Spectral flatness: geometric / arithmetic mean over positive-frequency bins
      double logSum = 0.0;
      double linSum = 0.0;
      final n = spectrum.length;
      for (int k = 0; k < n; k++) {
        final v = spectrum[k] < 1e-12 ? 1e-12 : spectrum[k];
        logSum += log(v);
        linSum += v;
      }
      final geoMean = exp(logSum / n);
      final ariMean = linSum / n;
      if (ariMean > 0) flatnesses.add(geoMean / ariMean);
    }

    if (flatnesses.isEmpty) return 0.0;
    flatnesses.sort();
    return flatnesses[flatnesses.length ~/ 2]; // median
  }

  /// Estimate the noise power spectral density from the quietest frames of
  /// [samples] using a minimum-statistics approach.
  ///
  /// Uses the quietest 10 % of frames (minimum 3) so the estimate reflects
  /// the ambient noise floor rather than the speech signal itself.
  static Float64List _estimateNoisePsd(Float64List samples) {
    final halfFft = _fftSize ~/ 2 + 1;
    final hamming = _hammingWindow(_frameLength);

    // Collect per-frame energy so we can sort and pick the quietest ones
    final frameEnergies = <({int start, double energy})>[];
    for (int start = 0; start + _frameLength <= samples.length; start += _frameStep) {
      double energy = 0.0;
      for (int i = 0; i < _frameLength; i++) {
        final s = samples[start + i];
        energy += s * s;
      }
      frameEnergies.add((start: start, energy: energy));
    }

    if (frameEnergies.isEmpty) return Float64List(halfFft);

    frameEnergies.sort((a, b) => a.energy.compareTo(b.energy));
    final noiseCount = max(3, frameEnergies.length ~/ 10);

    final noisePsd = Float64List(halfFft);
    for (int f = 0; f < noiseCount; f++) {
      final frame = Float64List(_fftSize);
      final s = frameEnergies[f].start;
      for (int i = 0; i < _frameLength; i++) {
        frame[i] = samples[s + i] * hamming[i];
      }
      final spectrum = _powerSpectrum(frame);
      for (int k = 0; k < halfFft; k++) {
        noisePsd[k] += spectrum[k];
      }
    }
    for (int k = 0; k < halfFft; k++) {
      noisePsd[k] /= noiseCount;
    }
    return noisePsd;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  MFCC extraction
  // ═══════════════════════════════════════════════════════════════════════════

  // Standard speech analysis parameters
  static const int _sampleRate = 16000;
  static const int _frameLength = 512;   // ~32ms at 16kHz
  static const int _frameStep = 256;     // 50% overlap → ~16ms hop
  static const int _fftSize = 512;
  static const int _numMelFilters = 26;
  static const int _numMfcc = 13;

  /// Extract MFCC feature vectors from raw PCM samples.
  /// Returns a list of frames, each frame is a list of [_numMfcc] coefficients.
  ///
  /// If [noisePsd] is provided, Berouti spectral subtraction is applied to each
  /// frame's power spectrum before the Mel filterbank (α=2 over-subtraction,
  /// β=0.01 spectral floor).  Pass the output of [_estimateNoisePsd].
  static List<List<double>> _extractMfcc(Float64List samples, {Float64List? noisePsd}) {
    // Resample to 16kHz if the WAV has a different rate?
    // For now we assume 16kHz (flutter_sound records at this rate by default).

    // Pre-emphasis filter: y[n] = x[n] - 0.97 * x[n-1]
    final preEmph = Float64List(samples.length);
    preEmph[0] = samples[0];
    for (int i = 1; i < samples.length; i++) {
      preEmph[i] = samples[i] - 0.97 * samples[i - 1];
    }

    // Build Mel filterbank (cached across frames)
    final melFilters = _buildMelFilterbank();

    // Frame the signal and compute MFCCs
    final frames = <List<double>>[];
    final hamming = _hammingWindow(_frameLength);

    for (int start = 0; start + _frameLength <= preEmph.length; start += _frameStep) {
      // Apply Hamming window
      final frame = Float64List(_fftSize);
      for (int i = 0; i < _frameLength; i++) {
        frame[i] = preEmph[start + i] * hamming[i];
      }
      // Zero-pad to FFT size (already done since _fftSize == _frameLength)

      // Power spectrum via FFT
      final spectrum = _powerSpectrum(frame);

      // Spectral subtraction — Berouti method:
      //   clean[k] = max(β·noise[k],  spectrum[k] − α·noise[k])
      //   α = 2.0  (over-subtraction keeps residual musical noise low)
      //   β = 0.01 (spectral floor so Mel energies never collapse to log(0))
      if (noisePsd != null) {
        const alpha = 2.0;
        const beta  = 0.01;
        for (int k = 0; k < spectrum.length; k++) {
          final floor      = beta * noisePsd[k];
          final subtracted = spectrum[k] - alpha * noisePsd[k];
          spectrum[k]      = subtracted > floor ? subtracted : floor;
        }
      }

      // Apply Mel filterbank
      final melEnergies = Float64List(_numMelFilters);
      for (int m = 0; m < _numMelFilters; m++) {
        double sum = 0.0;
        for (int k = 0; k < spectrum.length; k++) {
          sum += spectrum[k] * melFilters[m][k];
        }
        melEnergies[m] = sum < 1e-10 ? 1e-10 : sum; // floor to avoid log(0)
      }

      // Log Mel energies
      for (int m = 0; m < _numMelFilters; m++) {
        melEnergies[m] = log(melEnergies[m]);
      }

      // DCT-II → MFCCs
      final mfcc = _dctII(melEnergies, _numMfcc);
      frames.add(mfcc);
    }

    return frames;
  }

  /// Hamming window: w[n] = 0.54 - 0.46 * cos(2π n / (N-1))
  static Float64List _hammingWindow(int length) {
    final w = Float64List(length);
    for (int i = 0; i < length; i++) {
      w[i] = 0.54 - 0.46 * cos(2 * pi * i / (length - 1));
    }
    return w;
  }

  /// Compute power spectrum |FFT(x)|² / N using a radix-2 in-place FFT.
  /// Returns only the first N/2+1 bins (positive frequencies).
  static Float64List _powerSpectrum(Float64List frame) {
    final n = frame.length;
    // Real and imaginary parts
    final re = Float64List.fromList(frame);
    final im = Float64List(n);

    _fft(re, im);

    final halfN = n ~/ 2 + 1;
    final power = Float64List(halfN);
    for (int k = 0; k < halfN; k++) {
      power[k] = (re[k] * re[k] + im[k] * im[k]) / n;
    }
    return power;
  }

  /// In-place radix-2 Cooley–Tukey FFT.
  static void _fft(Float64List re, Float64List im) {
    final n = re.length;
    if (n <= 1) return;

    // Bit-reversal permutation
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tmpRe = re[i]; re[i] = re[j]; re[j] = tmpRe;
        final tmpIm = im[i]; im[i] = im[j]; im[j] = tmpIm;
      }
      int m = n >> 1;
      while (m >= 1 && j >= m) {
        j -= m;
        m >>= 1;
      }
      j += m;
    }

    // FFT butterfly
    for (int size = 2; size <= n; size <<= 1) {
      final halfSize = size >> 1;
      final angle = -2.0 * pi / size;
      final wRe = cos(angle);
      final wIm = sin(angle);

      for (int i = 0; i < n; i += size) {
        double curRe = 1.0, curIm = 0.0;
        for (int k = 0; k < halfSize; k++) {
          final evenIdx = i + k;
          final oddIdx = i + k + halfSize;

          final tRe = curRe * re[oddIdx] - curIm * im[oddIdx];
          final tIm = curRe * im[oddIdx] + curIm * re[oddIdx];

          re[oddIdx] = re[evenIdx] - tRe;
          im[oddIdx] = im[evenIdx] - tIm;
          re[evenIdx] += tRe;
          im[evenIdx] += tIm;

          final newCurRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = newCurRe;
        }
      }
    }
  }

  /// Build a triangular Mel filterbank.
  static List<Float64List> _buildMelFilterbank() {
    final halfFft = _fftSize ~/ 2 + 1;
    final lowMel = _hzToMel(0);
    final highMel = _hzToMel(_sampleRate / 2.0);

    // Evenly spaced points in Mel scale
    final melPoints = Float64List(_numMelFilters + 2);
    for (int i = 0; i < _numMelFilters + 2; i++) {
      melPoints[i] = lowMel + i * (highMel - lowMel) / (_numMelFilters + 1);
    }

    // Convert back to Hz and then to FFT bin indices
    final binPoints = List<int>.generate(_numMelFilters + 2, (i) {
      final hz = _melToHz(melPoints[i]);
      return ((hz / (_sampleRate / 2.0)) * (halfFft - 1)).round().clamp(0, halfFft - 1);
    });

    // Build triangular filters
    final filters = <Float64List>[];
    for (int m = 0; m < _numMelFilters; m++) {
      final filter = Float64List(halfFft);
      final left = binPoints[m];
      final center = binPoints[m + 1];
      final right = binPoints[m + 2];

      for (int k = left; k < center; k++) {
        if (center != left) {
          filter[k] = (k - left) / (center - left);
        }
      }
      for (int k = center; k <= right; k++) {
        if (right != center) {
          filter[k] = (right - k) / (right - center);
        }
      }
      filters.add(filter);
    }
    return filters;
  }

  static double _hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
  static double _melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

  /// Type-II DCT: extract first [numCoeffs] coefficients from [input].
  static List<double> _dctII(Float64List input, int numCoeffs) {
    final n = input.length;
    final result = List<double>.filled(numCoeffs, 0.0);
    for (int k = 0; k < numCoeffs; k++) {
      double sum = 0.0;
      for (int i = 0; i < n; i++) {
        sum += input[i] * cos(pi * k * (2 * i + 1) / (2 * n));
      }
      result[k] = sum;
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Dynamic Time Warping
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compare two MFCC sequences using DTW with Euclidean distance.
  /// Returns normalised distance (lower = more similar) and the warp path.
  static _DtwResult _dtw(List<List<double>> seq1, List<List<double>> seq2) {
    final m = seq1.length;
    final n = seq2.length;

    // Cost matrix
    final cost = List.generate(m, (_) => Float64List(n));

    // Distance function: Euclidean distance between MFCC vectors
    double dist(int i, int j) {
      double sum = 0.0;
      for (int k = 0; k < _numMfcc; k++) {
        final d = seq1[i][k] - seq2[j][k];
        sum += d * d;
      }
      return sqrt(sum);
    }

    // Fill cost matrix
    cost[0][0] = dist(0, 0);
    for (int i = 1; i < m; i++) {
      cost[i][0] = cost[i - 1][0] + dist(i, 0);
    }
    for (int j = 1; j < n; j++) {
      cost[0][j] = cost[0][j - 1] + dist(0, j);
    }
    for (int i = 1; i < m; i++) {
      for (int j = 1; j < n; j++) {
        cost[i][j] = dist(i, j) + [
          cost[i - 1][j],
          cost[i][j - 1],
          cost[i - 1][j - 1],
        ].reduce(min);
      }
    }

    // Traceback to find the optimal warp path
    final path = <(int, int)>[];
    int i = m - 1, j = n - 1;
    path.add((i, j));
    while (i > 0 || j > 0) {
      if (i == 0) {
        j--;
      } else if (j == 0) {
        i--;
      } else {
        final candidates = [
          cost[i - 1][j - 1],
          cost[i - 1][j],
          cost[i][j - 1],
        ];
        final minVal = candidates.reduce(min);
        if (minVal == cost[i - 1][j - 1]) {
          i--; j--;
        } else if (minVal == cost[i - 1][j]) {
          i--;
        } else {
          j--;
        }
      }
      path.add((i, j));
    }

    final totalCost = cost[m - 1][n - 1];
    final normDist = totalCost / path.length;

    return _DtwResult(
      normalisedDistance: normDist,
      path: path.reversed.toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Score mapping & feedback
  // ═══════════════════════════════════════════════════════════════════════════

  /// Map DTW normalised distance to a 0–1 similarity score.
  ///
  /// Tuned empirically:
  ///   distance ≤ 4  → score ≈ 1.0 (excellent match)
  ///   distance ≈ 10 → score ≈ 0.7 (good)
  ///   distance ≈ 18 → score ≈ 0.4 (needs work)
  ///   distance ≥ 30 → score ≈ 0.0 (completely off)
  static double _distanceToScore(double distance) {
    // Recalibrated for real-world MFCC distances.
    // Typical same-word distances: 60–120
    // Typical different-word distances: 150–300+
    const k = 0.04;         // gentler slope
    const midpoint = 130.0; // distance where score = 0.5
    final raw = 1.0 / (1.0 + exp(k * (distance - midpoint)));
    return raw.clamp(0.0, 1.0);
  }

  /// Compute per-segment similarity scores along the warp path.
  /// Divides the path into ~5 segments and averages the frame-level
  /// distances within each segment.
  static List<double> _computeSegmentScores(
      List<(int, int)> path,
      List<List<double>> ref,
      List<List<double>> att,
      ) {
    if (path.isEmpty) return [];

    const numSegments = 5;
    final segLen = max(1, path.length ~/ numSegments);
    final scores = <double>[];

    for (int s = 0; s < numSegments; s++) {
      final start = s * segLen;
      final end = (s == numSegments - 1) ? path.length : (s + 1) * segLen;
      if (start >= path.length) break;

      double totalDist = 0.0;
      int count = 0;
      for (int p = start; p < end && p < path.length; p++) {
        final (i, j) = path[p];
        if (i < ref.length && j < att.length) {
          double d = 0.0;
          for (int k = 0; k < _numMfcc; k++) {
            final diff = ref[i][k] - att[j][k];
            d += diff * diff;
          }
          totalDist += sqrt(d);
          count++;
        }
      }

      final avgDist = count > 0 ? totalDist / count : 30.0;
      scores.add(_distanceToScore(avgDist));
    }

    return scores;
  }

  /// Generate feedback string based on score and audio lengths.
  static String _generateFeedback(double score, int refLen, int attLen) {
    // Check duration match (within 50% of reference length)
    final durationRatio = attLen / max(1, refLen);

    if (score >= 0.85) {
      return 'Great match!';
    } else if (score >= 0.70) {
      if (durationRatio < 0.5) {
        return 'Good — try speaking a bit slower';
      } else if (durationRatio > 2.0) {
        return 'Good — try speaking a bit faster';
      }
      return 'Good — minor differences in tone';
    } else if (score >= 0.50) {
      if (durationRatio < 0.4) {
        return 'Too fast — slow down and enunciate';
      } else if (durationRatio > 2.5) {
        return 'Too slow — try matching the rhythm';
      }
      return 'Keep practising — focus on vowel sounds';
    } else {
      if (attLen < 800) {
        return 'Recording too quiet — speak up!';
      }
      return 'Try again — listen to the reference first';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Internal types
// ═══════════════════════════════════════════════════════════════════════════════

class _DtwResult {
  final double normalisedDistance;
  final List<(int, int)> path;

  const _DtwResult({
    required this.normalisedDistance,
    required this.path,
  });
}