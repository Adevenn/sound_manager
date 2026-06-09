import 'dart:io';

import 'package:sound_manager/model/soundtrack.enum.dart';
import 'package:path/path.dart' as p;

import 'uuid.dart';

class Soundtrack {
  String id;
  String source;
  String get name => p.basenameWithoutExtension(source);
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

  Soundtrack(
    this.source,
    this.type, {
    this.volume = 1.0,
    this.loop = false,
    this.colorIndex = 0,
    this.iconIndex = 0,
  }) : id = uuid.v4();

  Soundtrack.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      source = json['source'],
      type = SoundtrackType.byName(json['type']),
      volume = (json['volume'] as num?)?.toDouble() ?? 1.0,
      loop = json['loop'] ?? false,
      colorIndex = json['colorIndex'] ?? 0,
      iconIndex = json['iconIndex'] ?? 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'type': type.name,
    'volume': volume,
    'loop': loop,
    'colorIndex': colorIndex,
    'iconIndex': iconIndex,
  };

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
