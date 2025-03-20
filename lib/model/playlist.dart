import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model.dart';

class Playlist {
  String name;
  File? _file;
  List<Soundtrack> sounds = [];

  Playlist(this.name);

  Playlist.create(this.name) {
    _save();
  }

  Playlist.fromFile(this.name) {
    _loadContent();
  }

  Map<String, dynamic> toJson() => {
    'sounds': sounds.map((s) => s.toJson()).toList(),
  };

  Future<Directory> get _directory async {
    final directory = await getApplicationSupportDirectory();
    final directoryData = await Directory('${directory.path}/Data').create();
    return Directory('${directoryData.path}/Playlist')..createSync();
  }

  Future<void> _getFile() async =>
      _file ??= File('${(await _directory).path}/$name.json')..createSync();

  Future<void> _loadContent() async {
    try {
      await _getFile();
      var content = jsonDecode(_file!.readAsStringSync()) as List;
      sounds.clear();
      for (var sound in content) {
        sounds.add(Soundtrack.fromJson(sound));
      }
    } catch (e) {
      Future.error(e);
    }
  }

  void _save() async {
    await _getFile();
    _file!.writeAsString(jsonEncode(toJson()));
  }

  void rename(String newName) {}

  void delete() {}
}
