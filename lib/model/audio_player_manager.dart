import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sound_manager/model.dart';

/// Drives one logical audio channel (ambiance / music / effect).
///
/// It owns **two** [AudioPlayer]s so a track change can truly cross-fade: the
/// incoming track fades in on the idle player while the outgoing one fades out,
/// then the players swap roles. UI notifiers (position/duration/state) always
/// reflect whichever player is currently active.
class AudioPlayerManager {
  final PlayerType _type;
  PlayerType get type => _type;

  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  bool _usingA = true;
  AudioPlayer get _active => _usingA ? _playerA : _playerB;
  AudioPlayer get _inactive => _usingA ? _playerB : _playerA;

  // Volume currently applied to each player (audioplayers does not expose it),
  // so fades can ramp from the real value.
  double _volA = 1.0;
  double _volB = 1.0;

  final ValueNotifier<double> _volume = ValueNotifier(1.0);
  ValueNotifier<double> get volume => _volume;
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> get duration => _duration;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> get position => _position;
  final ValueNotifier<bool> isMuted = ValueNotifier(false);

  /// Fade on/off is a global setting; exposed here for the per-channel button.
  ValueNotifier<bool> get fadeEnabled => AudioSettings.instance.fadeEnabled;

  Timer? _fadeTimer;
  Timer? _crossfadeTimer;

  // Futures of the in-flight ramps. They must be completed when a ramp is
  // cancelled (not just the timer killed) so that callers awaiting [_fade] /
  // [_crossfade] are released instead of hanging forever.
  Completer<void>? _fadeCompleter;
  Completer<void>? _crossfadeCompleter;

  // The player being faded out during a cross-fade. Tracked so an interrupting
  // action can stop it (otherwise an interrupted cross-fade leaves the outgoing
  // track audible in the background).
  AudioPlayer? _crossfadeOutgoing;

  // Reusable pool for soundboard effects (overlap without spawning a fresh
  // native player every trigger — also limits the audioplayers off-thread
  // event warnings on desktop).
  final List<AudioPlayer> _effectPool = [];
  final Set<AudioPlayer> _busyEffects = {};
  // Players currently sustaining a press-and-hold loop. They must never be
  // recycled out from under the user while the button is still held.
  final Set<AudioPlayer> _heldLoops = {};
  static const int _maxEffectPlayers = 8;

  late final ValueNotifier<PlayerState> _state;
  ValueNotifier<PlayerState> get state => _state;
  bool get isCompleted => _state.value == PlayerState.completed;
  bool get isPause => _state.value == PlayerState.paused;
  bool get isPlaying => _state.value == PlayerState.playing;
  bool get isStop => _state.value == PlayerState.stopped;
  late final ValueNotifier<String?> _path;
  ValueNotifier<String?> get path => _path;

  /// Active stream subscriptions, cancelled in [dispose].
  final List<StreamSubscription> _subs = [];

  /// Ensures [loadSettings] only runs once even if called from several builds.
  Future<void>? _settingsFuture;

  /// Bumped whenever the playlist instance is replaced, so widgets can rebuild
  /// (e.g. when a scene swaps the channel's playlist).
  final ValueNotifier<int> playlistRevision = ValueNotifier(0);

  /// Ids of tracks in the current playlist whose audio file is missing on disk.
  /// Recomputed whenever the playlist changes; the UI greys those tracks out.
  final ValueNotifier<Set<String>> missingTrackIds = ValueNotifier({});

  late Playlist _playlist;
  Playlist get playlist => _playlist;
  set playlist(Playlist value) {
    _playlist.trackIndex.removeListener(_persistTrackIndex);
    _playlist = value;
    _playlist.trackIndex.addListener(_persistTrackIndex);
    // NB: which playlist is "current" is persisted explicitly when the user
    // loads/saves a *named* playlist (see PlaylistScreen) or applies a scene
    // (see [applyPlaylist]) — never here. Persisting the default unsaved
    // 'Custom' name from the setter would make every channel point at the same
    // file and cross-contaminate them on the next launch.
    playlistRevision.value++;
    _validateTracks();
  }

  /// Persists the current track position so playback resumes on the same track
  /// after a restart. Driven by the playlist's [trackIndex] notifier.
  void _persistTrackIndex() =>
      UserSettings.setTrackIndex(type, _playlist.trackIndex.value);

  /// Asynchronously checks every local track's file and publishes the ids of
  /// the missing ones to [missingTrackIds].
  Future<void> _validateTracks() async {
    final playlist = _playlist;
    final missing = <String>{};
    for (final track in playlist.tracks) {
      if (!await track.exists()) missing.add(track.id);
    }
    // Guard against a playlist swap that happened while we were awaiting.
    if (identical(playlist, _playlist)) missingTrackIds.value = missing;
  }

  String get playlistName => playlist.name;
  List<Soundtrack> get tracks => playlist.tracks;
  int get playlistLength => playlist.length;

  /// Name given to a fresh, unsaved working playlist. It is **unique per
  /// channel** (e.g. "Custom Ambiance") so that two channels' unsaved playlists
  /// never write to the same `<name>.json` and clobber each other (e.g. when a
  /// scene is saved or an effect is configured).
  String get _defaultPlaylistName => 'Custom ${_type.name.capitalize()}';
  Playlist _emptyPlaylist() => Playlist.empty(_defaultPlaylistName);

  AudioPlayerManager(this._type, [String? path]) {
    _path = ValueNotifier(path);
    _state = ValueNotifier(PlayerState.stopped);
    _playlist = _emptyPlaylist();
    _playlist.trackIndex.addListener(_persistTrackIndex);
    AudioSettings.instance.masterVolume.addListener(_onMasterChanged);
    _setStreams();
  }

  /// Idempotent: the heavy work runs only once, even if several widget
  /// rebuilds call this from a [FutureBuilder].
  Future<void> loadSettings() => _settingsFuture ??= _loadSettings();

  Future<void> _loadSettings() async {
    _volume.value = UserSettings.getPlayerVolume(type);
    final currentPlaylist = UserSettings.getCurrentPlaylist(type);
    try {
      playlist =
          currentPlaylist != ''
              ? await PlaylistRepository.load(currentPlaylist)
              : _emptyPlaylist();
    } catch (_) {
      // A previously-saved playlist may have been deleted/renamed: fall back to
      // an empty one instead of failing to start.
      playlist = _emptyPlaylist();
    }
    // Resume on the track that was selected when the app last closed. The pref
    // is updated live on every track change, so it wins over the index baked
    // into the playlist file (which only updates on an explicit save). Index 0
    // is a valid resume position, hence `>= 0`, not `> 0`.
    final savedIndex = UserSettings.getTrackIndex(type);
    if (savedIndex >= 0 && savedIndex < playlist.length) {
      playlist.changeTrack(savedIndex);
    }
    _loadTrack();
  }

  void _loadTrack() {
    if (playlist.actualSoundtrack != null) {
      _path.value = playlist.actualSoundtrack!.source;
    }
  }

  /// Called when the current track finishes on its own.
  void _handleTrackComplete() {
    if (playlist.loopMode.value == LoopMode.one) {
      _loadTrack();
      play();
      return;
    }
    if (playlist.nextTrack()) {
      _loadTrack();
      play();
    } else {
      stop();
    }
  }

  void previousTrack() {
    playlist.previousTrack();
    _loadTrack();
    play();
  }

  void nextTrack() {
    if (playlist.nextTrack()) {
      _loadTrack();
      play();
    }
  }

  void changeTrack(Soundtrack? track) {
    if (track == null) {
      path.value = null;
      return;
    }
    final index = playlist.tracks.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      playlist.changeTrack(index);
      _loadTrack();
      play();
    }
  }

  /// Replaces this channel's playlist with the saved one named [name] (used by
  /// scenes). Pass an empty/null name to clear the channel.
  Future<void> applyPlaylist(String? name, {bool autoplay = true}) async {
    await stop(fade: false);
    if (name == null || name.isEmpty) {
      playlist = _emptyPlaylist();
      _path.value = null;
      await UserSettings.setCurrentPlaylist(type, '');
      return;
    }
    try {
      playlist = await PlaylistRepository.load(name);
      await UserSettings.setCurrentPlaylist(type, name);
    } catch (_) {
      playlist = _emptyPlaylist();
      await UserSettings.setCurrentPlaylist(type, '');
    }
    _path.value = null;
    _loadTrack();
    if (autoplay && playlist.isNotEmpty) await play();
  }

  /// Subscribes to both players' streams once. Each notifier only follows the
  /// currently active player so the idle/cross-fading one is ignored.
  void _setStreams() {
    for (final player in [_playerA, _playerB]) {
      _subs.addAll([
        player.onDurationChanged.listen((d) {
          if (identical(player, _active)) _duration.value = d;
        }),
        player.onPositionChanged.listen((p) {
          if (identical(player, _active)) _position.value = p;
        }),
        player.onPlayerComplete.listen((_) {
          if (!identical(player, _active)) return;
          _position.value = Duration.zero;
          _state.value = PlayerState.completed;
          _handleTrackComplete();
        }),
        player.onPlayerStateChanged.listen((s) {
          if (identical(player, _active)) _state.value = s;
        }),
      ]);
    }
  }

  void seek(double position) =>
      _active.seek(Duration(milliseconds: position.round()));

  /// Volume the active player should reach when fully faded in (0 while muted),
  /// already scaled by the global master volume.
  double get _targetVolume {
    if (isMuted.value) return 0.0;
    return (_volume.value * AudioSettings.instance.masterVolume.value)
        .clamp(0.0, 1.0);
  }

  double _volOf(AudioPlayer p) => identical(p, _playerA) ? _volA : _volB;

  void _applyVolume(AudioPlayer p, double v) {
    if (identical(p, _playerA)) {
      _volA = v;
    } else {
      _volB = v;
    }
    p.setVolume(v);
  }

  /// Stops any running ramp. Crucially this also (a) stops the cross-fade's
  /// outgoing player so it doesn't keep sounding, and (b) completes the ramp
  /// futures so awaiters are released instead of deadlocking.
  void _cancelFades() {
    _fadeTimer?.cancel();
    _crossfadeTimer?.cancel();
    final outgoing = _crossfadeOutgoing;
    _crossfadeOutgoing = null;
    if (outgoing != null) outgoing.stop();
    if (!(_fadeCompleter?.isCompleted ?? true)) _fadeCompleter!.complete();
    if (!(_crossfadeCompleter?.isCompleted ?? true)) {
      _crossfadeCompleter!.complete();
    }
  }

  /// True while a fade or cross-fade ramp is in progress.
  bool get _isFading =>
      (_fadeTimer?.isActive ?? false) || (_crossfadeTimer?.isActive ?? false);

  /// Ramps a single player's volume to [target] over [duration].
  Future<void> _fade(AudioPlayer p, double target, Duration duration) async {
    _cancelFades(); // never let two ramps run at once
    const steps = 20;
    final stepMs = (duration.inMilliseconds / steps).round().clamp(1, 1000);
    final start = _volOf(p);
    final delta = (target - start) / steps;
    final completer = Completer<void>();
    _fadeCompleter = completer;
    var step = 0;
    _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      step++;
      _applyVolume(p, (start + delta * step).clamp(0.0, 1.0));
      if (step >= steps) {
        timer.cancel();
        _applyVolume(p, target);
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  /// Ramps [out] down to 0 and [inc] up to [inTarget] at the same time, then
  /// stops [out]. If interrupted (see [_cancelFades]) the outgoing player is
  /// stopped there instead, so it never lingers.
  Future<void> _crossfade(
    AudioPlayer out,
    AudioPlayer inc,
    double inTarget,
    Duration duration,
  ) async {
    _cancelFades(); // never let two ramps run at once
    const steps = 30;
    final stepMs = (duration.inMilliseconds / steps).round().clamp(1, 1000);
    final outStart = _volOf(out);
    final incStart = _volOf(inc);
    final outDelta = (0.0 - outStart) / steps;
    final incDelta = (inTarget - incStart) / steps;
    final completer = Completer<void>();
    _crossfadeCompleter = completer;
    _crossfadeOutgoing = out;
    var step = 0;
    _crossfadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      step++;
      _applyVolume(out, (outStart + outDelta * step).clamp(0.0, 1.0));
      _applyVolume(inc, (incStart + incDelta * step).clamp(0.0, 1.0));
      if (step >= steps) {
        timer.cancel();
        _applyVolume(out, 0.0);
        _applyVolume(inc, inTarget);
        // Normal completion owns stopping the outgoing player; clear the handle
        // first so a later cancel doesn't stop it twice.
        _crossfadeOutgoing = null;
        out.stop();
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  void setVolume(double newValue) {
    _cancelFades(); // user takes over: stop any running fade
    _volume.value = newValue;
    if (!isMuted.value) _applyVolume(_active, _targetVolume);
  }

  void setVolumeSettings(double value) {
    UserSettings.setPlayerVolume(type, value);
  }

  void switchIsMuted() {
    isMuted.value = !isMuted.value;
    _cancelFades();
    _applyVolume(_active, _targetVolume);
  }

  void toggleFade() =>
      AudioSettings.instance.setFadeEnabled(!fadeEnabled.value);

  /// Re-applies the volume live when the master volume changes mid-playback.
  /// Skipped while a fade is running so it does not fight the ramp (the fade
  /// finishes at its captured target).
  void _onMasterChanged() {
    if (isPlaying && !_isFading) _applyVolume(_active, _targetVolume);
  }

  AudioPlayer _acquireEffectPlayer() {
    // Reuse a free player if any.
    for (final p in _effectPool) {
      if (!_busyEffects.contains(p)) return p;
    }
    // Room left: spawn a new one.
    if (_effectPool.length < _maxEffectPlayers) {
      final p = AudioPlayer();
      p.onPlayerComplete.listen((_) => _busyEffects.remove(p));
      _effectPool.add(p);
      return p;
    }
    // Pool full and all busy: recycle the oldest player that isn't sustaining a
    // held loop (so press-and-hold effects are never cut off). Only when every
    // player is a held loop do we fall back to the very oldest.
    final p = _effectPool.firstWhere(
      (p) => !_heldLoops.contains(p),
      orElse: () => _effectPool.first,
    );
    _effectPool.remove(p);
    p.stop();
    _busyEffects.remove(p);
    _heldLoops.remove(p);
    _effectPool.add(p);
    return p;
  }

  /// Plays an effect (one-shot) on a free pooled player, at the effect's own
  /// volume scaled by the channel + master volume.
  Future<void> playEffect(Soundtrack track) async {
    final player = _acquireEffectPlayer();
    _busyEffects.add(player);
    await player.setReleaseMode(ReleaseMode.release);
    await player.setVolume((_targetVolume * track.volume).clamp(0.0, 1.0));
    await player.play(DeviceFileSource(track.source));
  }

  /// Starts an effect looping (for press-and-hold). Returns the player so the
  /// caller can stop it on release with [stopLoopEffect].
  Future<AudioPlayer> startLoopEffect(Soundtrack track) async {
    final player = _acquireEffectPlayer();
    _busyEffects.add(player);
    _heldLoops.add(player);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume((_targetVolume * track.volume).clamp(0.0, 1.0));
    await player.play(DeviceFileSource(track.source));
    return player;
  }

  Future<void> stopLoopEffect(AudioPlayer player) async {
    _heldLoops.remove(player);
    await player.stop();
    await player.setReleaseMode(ReleaseMode.release);
    _busyEffects.remove(player);
  }

  /// Immediately stops every running effect (for the global stop).
  Future<void> stopEffects() async {
    for (final p in _effectPool) {
      await p.stop();
    }
    _busyEffects.clear();
    _heldLoops.clear();
  }

  void _changeState(PlayerState newState) => _state.value = newState;

  void dispose() {
    _cancelFades();
    _playlist.trackIndex.removeListener(_persistTrackIndex);
    AudioSettings.instance.masterVolume.removeListener(_onMasterChanged);
    for (final sub in _subs) {
      sub.cancel();
    }
    for (final p in _effectPool) {
      p.dispose();
    }
    _effectPool.clear();
    _busyEffects.clear();
    _heldLoops.clear();
    _playerA.dispose();
    _playerB.dispose();
    // Release the channel's own notifiers (the playlist owns its own).
    _volume.dispose();
    _duration.dispose();
    _position.dispose();
    isMuted.dispose();
    _state.dispose();
    _path.dispose();
    playlistRevision.dispose();
    missingTrackIds.dispose();
  }

  Future<void> pause({bool fade = true}) async {
    final wasPlaying = isPlaying;
    // Capture the player now: a cross-fade swap during the await would otherwise
    // make us pause the wrong one.
    final player = _active;
    // Flip the state first so the play/pause icon updates instantly, before
    // the fade-out runs.
    _changeState(PlayerState.paused);
    if (fade && fadeEnabled.value && wasPlaying) {
      await _fade(player, 0.0, AudioSettings.instance.shortFade);
    }
    await player.pause();
  }

  /// Resumes the current track without reloading the source (so it does not
  /// restart from the beginning after a pause).
  Future<void> resume({bool fade = true}) async {
    if (_path.value == null) return;
    final useFade = fade && fadeEnabled.value;
    final player = _active;
    // Always set the starting volume explicitly: after a faded pause the player
    // volume sits at 0, so without this a fade-disabled resume would be silent.
    _applyVolume(player, useFade ? 0.0 : _targetVolume);
    _changeState(PlayerState.playing);
    await player.resume();
    if (useFade) {
      await _fade(player, _targetVolume, AudioSettings.instance.shortFade);
    }
  }

  /// Starts (or restarts) playback of the current track. When already playing
  /// and cross-fade is enabled, the new track overlaps the old one. Pass
  /// [short] for the snappy pause/play fade instead of the longer track-change
  /// fade.
  Future<void> play({bool fade = true, bool short = false}) async {
    // The playlist may have just been filled without a track being loaded yet
    // (e.g. drag-and-drop in the editor): make sure a source is selected so the
    // main play button works without first clicking a track in the list.
    if (_path.value == null) _loadTrack();
    if (_path.value == null) return;
    final settings = AudioSettings.instance;
    final useFade = fade && settings.fadeEnabled.value;
    final duration = short ? settings.shortFade : settings.longFade;
    final wasPlaying = isPlaying;
    try {
      if (useFade && settings.crossfadeEnabled.value && wasPlaying) {
        // True cross-fade: start the new track on the idle player, swap roles,
        // then ramp the two volumes in opposite directions.
        final outgoing = _active;
        final incoming = _inactive;
        _cancelFades();
        _applyVolume(incoming, 0.0);
        _usingA = !_usingA; // incoming becomes active (drives the UI)
        _position.value = Duration.zero;
        _changeState(PlayerState.playing);
        await incoming.play(DeviceFileSource(_path.value!));
        // _crossfade stops `outgoing` itself, on either completion or cancel.
        await _crossfade(outgoing, incoming, _targetVolume, duration);
      } else {
        _cancelFades();
        // Stop first so re-selecting the playing track restarts it from 0.
        await _active.stop();
        _applyVolume(_active, useFade ? 0.0 : _targetVolume);
        _changeState(PlayerState.playing);
        await _active.play(DeviceFileSource(_path.value!));
        _position.value = Duration.zero;
        if (useFade) await _fade(_active, _targetVolume, duration);
      }
    } catch (e) {
      // Most callers (next/previous/auto-advance) do not await play(), so a
      // throw here would become an unhandled async error. Recover gracefully:
      // reset to a stopped state and log instead of crashing.
      debugPrint('AudioPlayerManager.play failed for "${_path.value}": $e');
      _cancelFades();
      _changeState(PlayerState.stopped);
      _position.value = Duration.zero;
    }
  }

  Future<void> stop({bool fade = true}) async {
    final wasPlaying = isPlaying;
    final active = _active;
    final inactive = _inactive;
    _changeState(PlayerState.stopped);
    if (fade && fadeEnabled.value && wasPlaying) {
      await _fade(active, 0.0, AudioSettings.instance.shortFade);
    }
    _cancelFades();
    await active.stop();
    await inactive.stop(); // silence any lingering cross-fade player
    _applyVolume(active, _targetVolume); // ready for the next play
    _position.value = Duration.zero;
  }
}
