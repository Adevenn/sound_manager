import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model/campaign_manager.dart';

/// Centralizes the on-disk locations the app persists data to.
///
/// Layout (campaign-scoped):
/// ```
/// <appSupport>/Data/
///   Campaigns/
///     <campaign>/
///       Playlist/<name>.json
///       scenes.json
/// ```
/// [data] and [playlists] resolve against the **active** campaign
/// ([CampaignManager.current]), so every repository is automatically isolated
/// per campaign without having to thread the campaign name through everywhere.
class AppDirectories {
  AppDirectories._();

  /// `<appSupport>/Data` — the root that holds the campaigns folder (and, for
  /// pre-campaign installs, the legacy `Playlist/` + `scenes.json`).
  static Future<Directory> dataRoot() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'Data')).create(recursive: true);
  }

  /// `<Data>/Campaigns` — parent of every campaign folder.
  static Future<Directory> campaignsRoot() async {
    final root = await dataRoot();
    return Directory(p.join(root.path, 'Campaigns')).create(recursive: true);
  }

  /// Folder for a specific campaign (not necessarily the active one). Not
  /// created here so callers can test for existence; create it explicitly.
  static Future<Directory> campaign(String name) async {
    final root = await campaignsRoot();
    return Directory(p.join(root.path, CampaignManager.sanitize(name)));
  }

  /// Active campaign's folder — the root for everything the app stores for the
  /// current game.
  static Future<Directory> data() async {
    final dir = await campaign(CampaignManager.instance.current.value);
    return dir.create(recursive: true);
  }

  /// `<activeCampaign>/Playlist` — one `<name>.json` file per playlist.
  static Future<Directory> playlists() async {
    final data = await AppDirectories.data();
    return Directory(p.join(data.path, 'Playlist')).create(recursive: true);
  }
}
