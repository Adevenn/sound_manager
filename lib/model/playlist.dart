import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model.dart';

class Playlist {
  String name;
  File? _file;
  List<Soundtrack> sounds = [];

  Playlist.create(this.name) {
    _save();
  }

  Playlist(this.name) {
    _loadContent();
  }

  Map<String, dynamic> toJson() => {
    'sounds': sounds.map((s) => s.toJson()).toList(),
  };

  Future<Directory> get _directory async {
    final directory = await getApplicationSupportDirectory();
    return await Directory('${directory.path}/Data/Playlist').create();
  }

  void _getFile() => _file ??= File('$_directory/$name')..createSync();

  Future<void> _loadContent() async {
    try {
      _getFile();
      var content = jsonDecode(_file!.readAsStringSync()) as List;
      print(content);
      sounds.clear();
      for (var sound in content) {
        sounds.add(Soundtrack.fromJson(sound));
      }
    } catch (e) {
      print(e);
      Future.error(e);
    }
  }

  void _save() {
    _getFile();
    _file!.writeAsString(jsonEncode(toJson()));
  }

  void rename(String newName) {}

  void delete() {}
}
