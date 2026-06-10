import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sound_manager/model/app_directories.dart';
import 'package:sound_manager/model/prefs.dart';

/// A "campaign" is an isolated profile: its own playlists, scenes, soundboard
/// and per-channel settings, all rooted under
/// `<appSupport>/Data/Campaigns/<name>/`. Switching campaigns swaps the whole
/// soundscape so a GM can keep several games' libraries cleanly apart.
///
/// The currently-selected campaign drives [AppDirectories], so every repository
/// automatically reads/writes inside the active campaign's folder.
class CampaignManager {
  CampaignManager._();
  static final CampaignManager instance = CampaignManager._();

  /// Name of the campaign that always exists and can never be deleted.
  static const String defaultCampaign = 'Default';

  static const String _kCurrent = 'current_campaign';

  /// Name of the active campaign. Read synchronously by [AppDirectories].
  final ValueNotifier<String> current = ValueNotifier(defaultCampaign);

  void load() {
    current.value = Prefs.instance.getString(_kCurrent) ?? defaultCampaign;
  }

  /// Strips characters forbidden in folder names so any typed campaign name is
  /// usable on disk.
  static String sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  /// Creates the campaign's folder if needed (the async part of a switch,
  /// safe to run while the UI still shows the previous campaign).
  Future<void> ensureExists(String name) async {
    final clean = sanitize(name);
    if (clean.isEmpty) return;
    await (await AppDirectories.campaign(clean)).create(recursive: true);
  }

  /// Synchronous part of a switch: updates [current] (notifying listeners) and
  /// kicks off the pref write. Callers that rebuild UI state keyed on the
  /// campaign must do so in the **same synchronous span** as this call, so no
  /// frame can ever build against stale/disposed state.
  void setCurrentSync(String name) {
    final clean = sanitize(name);
    if (clean.isEmpty) return;
    current.value = clean;
    Prefs.instance.setString(_kCurrent, clean);
  }

  /// Switches the active campaign (creating its folder if needed). Callers must
  /// rebuild/reload channel state afterwards.
  Future<void> setCurrent(String name) async {
    await ensureExists(name);
    setCurrentSync(name);
  }

  /// Every campaign on disk, sorted, always including [defaultCampaign].
  Future<List<String>> list() async {
    final root = await AppDirectories.campaignsRoot();
    final names = <String>{defaultCampaign};
    await for (final e in root.list()) {
      if (e is Directory) names.add(p.basename(e.path));
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  Future<void> create(String name) async {
    final clean = sanitize(name);
    if (clean.isEmpty) return;
    await (await AppDirectories.campaign(clean)).create(recursive: true);
  }

  /// Deletes a campaign and all of its data. The [defaultCampaign] is
  /// protected. If the active campaign is deleted, falls back to Default.
  Future<void> delete(String name) async {
    if (name == defaultCampaign) return;
    final dir = await AppDirectories.campaign(name);
    if (await dir.exists()) await dir.delete(recursive: true);
    if (current.value == name) await setCurrent(defaultCampaign);
  }

  Future<void> rename(String oldName, String newName) async {
    if (oldName == defaultCampaign) return; // keep Default stable
    final clean = sanitize(newName);
    if (clean.isEmpty || clean == oldName) return;
    final from = await AppDirectories.campaign(oldName);
    final to = await AppDirectories.campaign(clean);
    if (await from.exists() && !await to.exists()) {
      await from.rename(to.path);
      await _migratePrefKeys(oldName, clean);
    }
    if (current.value == oldName) await setCurrent(clean);
  }

  /// Moves the campaign-scoped preference keys (`camp_<old>_*`) to the new
  /// campaign prefix so per-channel volumes/playlists survive a rename.
  Future<void> _migratePrefKeys(String oldName, String newName) async {
    final p = Prefs.instance;
    final oldPrefix = 'camp_${oldName}_';
    final newPrefix = 'camp_${newName}_';
    for (final key
        in p.getKeys().where((k) => k.startsWith(oldPrefix)).toList()) {
      final newKey = key.replaceFirst(oldPrefix, newPrefix);
      final v = p.get(key);
      if (v is String) {
        await p.setString(newKey, v);
      } else if (v is double) {
        await p.setDouble(newKey, v);
      } else if (v is int) {
        await p.setInt(newKey, v);
      } else if (v is bool) {
        await p.setBool(newKey, v);
      }
      await p.remove(key);
    }
  }

  /// One-time migration of pre-campaign data (`<Data>/Playlist`, `scenes.json`
  /// sitting directly under Data) into `Campaigns/Default`. Safe to call on
  /// every launch: it does nothing once the move has happened.
  Future<void> migrateLegacyData() async {
    try {
      final dataRoot = await AppDirectories.dataRoot();
      final legacyPlaylists = Directory(p.join(dataRoot.path, 'Playlist'));
      final legacyScenes = File(p.join(dataRoot.path, 'scenes.json'));
      final hasLegacy =
          await legacyPlaylists.exists() || await legacyScenes.exists();
      if (!hasLegacy) return;

      final defaultDir = await AppDirectories.campaign(defaultCampaign);
      await defaultDir.create(recursive: true);

      final targetPlaylists = Directory(p.join(defaultDir.path, 'Playlist'));
      if (await legacyPlaylists.exists() && !await targetPlaylists.exists()) {
        await legacyPlaylists.rename(targetPlaylists.path);
      }
      final targetScenes = File(p.join(defaultDir.path, 'scenes.json'));
      if (await legacyScenes.exists() && !await targetScenes.exists()) {
        await legacyScenes.rename(targetScenes.path);
      }
    } catch (e) {
      debugPrint('Campaign migration skipped: $e');
    }
  }
}
