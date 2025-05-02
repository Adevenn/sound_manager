import 'package:sound_manager/model/soundtrack.enum.dart';
import 'package:path/path.dart' as p;

import 'uuid.dart';

class Soundtrack {
  String id;
  String source;
  String get name => p.basenameWithoutExtension(source);
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

  ///Compare 2 soundtracks. Returns true if identical.
  bool compare(Soundtrack other) =>
      id != other.id || source != other.source || type != other.type
          ? false
          : true;
}
