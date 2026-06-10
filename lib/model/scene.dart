/// A saved combination of the three channels (which playlist + which volume),
/// so a GM can switch the whole soundscape in one click (e.g. "Tavern",
/// "Combat", "Dungeon").
class Scene {
  String name;

  /// channel type name (`ambiance`/`music`/`effect`) -> playlist name.
  final Map<String, String> playlists;

  /// channel type name -> volume (0..1).
  final Map<String, double> volumes;

  Scene({required this.name, required this.playlists, required this.volumes});

  Scene.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      playlists = Map<String, String>.from(json['playlists'] ?? {}),
      volumes =
          (json['volumes'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ) ??
          {};

  Map<String, dynamic> toJson() => {
    'name': name,
    'playlists': playlists,
    'volumes': volumes,
  };
}
