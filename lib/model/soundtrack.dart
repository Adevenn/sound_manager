import 'package:sound_manager/model/soundtrack.enum.dart';

class Soundtrack {
  String source;
  SoundtrackType type;

  Soundtrack(this.source, this.type);
  Soundtrack.fromJson(Map<String, dynamic> json)
    : source = json['source'],
      type = SoundtrackType.byName(json['type']);

  Map<String, dynamic> toJson() => {'source': source, 'type': type.name};
}
