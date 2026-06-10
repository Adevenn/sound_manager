import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:sound_manager/model/soundtrack.enum.dart';
import 'package:path/path.dart' as p;

import 'uuid.dart';

class Soundtrack {
  String id;
  String source;

  /// Optional friendly name, mainly for [SoundtrackType.url] sources whose
  /// basename is often unreadable. Falls back to the file/URL basename.
  String? title;

  String get name {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (type == SoundtrackType.url) {
      // Last path segment of the URL, without query string.
      final cleaned = source.split('?').first;
      final base = p.basenameWithoutExtension(cleaned);
      return base.isNotEmpty ? base : source;
    }
    return p.basenameWithoutExtension(source);
  }

  SoundtrackType type;

  /// Per-effect playback volume (0..1), multiplied with the channel volume.
  double volume;

  /// When true the effect button loops while held (press-and-hold), useful for
  /// continuous sounds (rain, wind...).
  bool loop;

  /// Index into [EffectStyle.colors] for the effect button background.
  int colorIndex;

  /// Index into [EffectStyle.icons] for the effect button icon.
  int iconIndex;

  /// When true, this effect is part of the random pool the generative ambiance
  /// mode draws from (e.g. distant howls, thunder).
  bool generative;

  Soundtrack(
    this.source,
    this.type, {
    this.title,
    this.volume = 1.0,
    this.loop = false,
    this.colorIndex = 0,
    this.iconIndex = 0,
    this.generative = false,
  }) : id = uuid.v4();

  Soundtrack.fromJson(Map<String, dynamic> json)
    // Files written before ids existed: generate one instead of crashing.
    : id = json['id'] ?? uuid.v4(),
      source = json['source'],
      title = json['title'],
      type = SoundtrackType.byName(json['type']),
      volume = (json['volume'] as num?)?.toDouble() ?? 1.0,
      loop = json['loop'] ?? false,
      colorIndex = json['colorIndex'] ?? 0,
      iconIndex = json['iconIndex'] ?? 0,
      generative = json['generative'] ?? false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    if (title != null) 'title': title,
    'type': type.name,
    'volume': volume,
    'loop': loop,
    'colorIndex': colorIndex,
    'iconIndex': iconIndex,
    'generative': generative,
  };

  /// The audioplayers [Source] to hand to a player: a network stream for url
  /// tracks, a local file otherwise.
  Source get audioSource =>
      type == SoundtrackType.url ? UrlSource(source) : DeviceFileSource(source);

  /// Whether the underlying audio file is still present on disk. Always true
  /// for non-local (url) sources, which can't be checked this way.
  Future<bool> exists() async {
    if (type != SoundtrackType.local) return true;
    return File(source).exists();
  }

  ///Compare 2 soundtracks. Returns true if identical.
  bool compare(Soundtrack other) =>
      id == other.id && source == other.source && type == other.type;
}
