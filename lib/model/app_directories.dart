import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Centralizes the on-disk locations the app persists data to, all rooted under
/// `<appSupport>/Data`. Keeping the path logic in one place avoids duplicating
/// it across the playlist and scene repositories.
class AppDirectories {
  AppDirectories._();

  /// `<appSupport>/Data` — the root for everything this app stores.
  static Future<Directory> data() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/Data').create(recursive: true);
  }

  /// `<appSupport>/Data/Playlist` — one `<name>.json` file per playlist.
  static Future<Directory> playlists() async {
    final data = await AppDirectories.data();
    return Directory('${data.path}/Playlist').create(recursive: true);
  }
}
