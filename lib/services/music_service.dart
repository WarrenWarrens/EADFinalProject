import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'volume_service.dart';

/// Background music tracks available in the app.
enum MusicTrack {
  /// Plays during landing page and onboarding/setup screens.
  landing,

  /// Plays from the home screen onwards.
  home,
}

/// Singleton service that manages background music across the app.
///
/// Features:
///   • Continuous looping
///   • Crossfade between tracks (landing ↔ home)
///   • Fade to whisper when entering a lesson
///   • Fade back to full volume when leaving a lesson
///
/// Usage:
///   final music = MusicService();
///   music.play(MusicTrack.landing);
///   music.crossfadeTo(MusicTrack.home);
///   music.fadeToWhisper();
///   music.fadeBack();
class MusicService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  // ── Players ────────────────────────────────────────────────────────────────
  // Two players enable smooth crossfading — one fades out while the other
  // fades in. [_activePlayer] is whichever is currently audible.
  AudioPlayer? _playerA;
  AudioPlayer? _playerB;
  AudioPlayer? _activePlayer;

  // ── State ──────────────────────────────────────────────────────────────────
  MusicTrack? _currentTrack;
  bool _isWhisper = false;
  Timer? _fadeTimer;

  // ── Config ─────────────────────────────────────────────────────────────────
  /// User-controlled ceiling. Falls back to 0.5 before VolumeService is loaded.
  double get _fullVolume => VolumeService().musicVolume;
  /// Whisper is ~13 % of the user ceiling (preserves original 0.08/0.6 ratio).
  double get _whisperVolume => (_fullVolume * 0.13).clamp(0.0, 1.0);

  static const Duration crossfadeDuration = Duration(milliseconds: 2000);
  static const Duration whisperFadeDuration = Duration(milliseconds: 1500);

  // ── Asset paths ────────────────────────────────────────────────────────────
  // Place your mp3 files in assets/music/ and declare them in pubspec.yaml.
  static const Map<MusicTrack, String> _assetPaths = {
    MusicTrack.landing: 'assets/music/landing.mp3',
    MusicTrack.home: 'assets/music/home.mp3',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Start playing a track. If the same track is already playing, this is a
  /// no-op. If a different track is playing, use [crossfadeTo] instead.
  Future<void> play(MusicTrack track) async {
    if (_currentTrack == track && _activePlayer != null) return;

    // If something is already playing, crossfade to the new track.
    if (_activePlayer != null && _currentTrack != null) {
      await crossfadeTo(track);
      return;
    }

    // Cold start — nothing playing yet.
    _playerA ??= AudioPlayer();
    _activePlayer = _playerA;
    _currentTrack = track;

    try {
      await _activePlayer!.setAsset(_assetPaths[track]!);
      await _activePlayer!.setLoopMode(LoopMode.one);
      await _activePlayer!.setVolume(_isWhisper ? _whisperVolume : _fullVolume);
      await _activePlayer!.play();
      print('[Music] Playing ${track.name}');
    } catch (e) {
      print('[Music] Error playing ${track.name}: $e');
    }
  }

  /// Crossfade from the current track to a new one over [crossfadeDuration].
  /// If nothing is playing yet, falls back to a regular [play].
  Future<void> crossfadeTo(MusicTrack track) async {
    if (_currentTrack == track) return;

    // Cold start — nothing playing, just start directly.
    if (_activePlayer == null || !isPlaying) {
      await play(track);
      return;
    }

    final oldPlayer = _activePlayer;
    final targetVolume = _isWhisper ? _whisperVolume : _fullVolume;

    // Set up the new player on the inactive slot.
    _playerB ??= AudioPlayer();
    final newPlayer = (oldPlayer == _playerA) ? _playerB! : (_playerA ??= AudioPlayer());

    try {
      await newPlayer.setAsset(_assetPaths[track]!);
      await newPlayer.setLoopMode(LoopMode.one);
      await newPlayer.setVolume(0.0);
      await newPlayer.play();
    } catch (e) {
      print('[Music] Error loading ${track.name}: $e');
      return;
    }

    _activePlayer = newPlayer;
    _currentTrack = track;

    // Animate: old fades out, new fades in.
    _cancelFade();
    const steps = 40;
    final stepDuration = Duration(
        milliseconds: crossfadeDuration.inMilliseconds ~/ steps);
    final oldStartVol = oldPlayer?.volume ?? 0.0;
    var step = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      step++;
      final t = step / steps; // 0.0 → 1.0

      // Old player fades out
      oldPlayer?.setVolume(oldStartVol * (1.0 - t));
      // New player fades in
      newPlayer.setVolume(targetVolume * t);

      if (step >= steps) {
        timer.cancel();
        _fadeTimer = null;
        oldPlayer?.stop();
        print('[Music] Crossfade complete → ${track.name}');
      }
    });
  }

  /// Fade the active track down to whisper volume.
  /// Call when entering a lesson.
  Future<void> fadeToWhisper() async {
    if (_activePlayer == null || _isWhisper) return;
    _isWhisper = true;
    await _fadeTo(_whisperVolume, whisperFadeDuration);
    print('[Music] Faded to whisper');
  }

  /// Fade the active track back to full volume.
  /// Call when leaving a lesson.
  Future<void> fadeBack() async {
    if (_activePlayer == null || !_isWhisper) return;
    _isWhisper = false;
    await _fadeTo(_fullVolume, whisperFadeDuration);
    print('[Music] Faded back to full');
  }

  /// Pause playback entirely (e.g. app backgrounded).
  Future<void> pause() async {
    await _activePlayer?.pause();
  }

  /// Resume after pause.
  Future<void> resume() async {
    await _activePlayer?.play();
  }

  /// Stop everything and release resources.
  Future<void> dispose() async {
    _cancelFade();
    await _playerA?.dispose();
    await _playerB?.dispose();
    _playerA = null;
    _playerB = null;
    _activePlayer = null;
    _currentTrack = null;
  }

  /// Update music volume and apply immediately to the active player.
  Future<void> setMusicVolume(double v) async {
    await VolumeService().setMusicVolume(v);
    if (_activePlayer == null) return;
    await _activePlayer!.setVolume(_isWhisper ? _whisperVolume : _fullVolume);
  }

  /// Whether music is currently playing.
  bool get isPlaying => _activePlayer?.playing ?? false;

  /// The current track (or null if nothing is playing).
  MusicTrack? get currentTrack => _currentTrack;

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _fadeTo(double target, Duration duration) async {
    _cancelFade();
    final player = _activePlayer;
    if (player == null) return;

    const steps = 30;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final startVol = player.volume;
    var step = 0;

    final completer = Completer<void>();

    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      step++;
      final t = step / steps;
      final vol = startVol + (target - startVol) * t;
      player.setVolume(vol.clamp(0.0, 1.0));

      if (step >= steps) {
        timer.cancel();
        _fadeTimer = null;
        player.setVolume(target);
        completer.complete();
      }
    });

    return completer.future;
  }

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }
}