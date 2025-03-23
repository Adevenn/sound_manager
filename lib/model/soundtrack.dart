import 'package:sound_manager/model/soundtrack.enum.dart';

import 'uuid.dart';

class Soundtrack {
  String id;
  String source;
  SoundtrackType type;

  Soundtrack(this.source, this.type) : id = uuid.v4();
  Soundtrack.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      source = json['source'],
      type = SoundtrackType.byName(json['type']);

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'type': type.name,
  };
}
