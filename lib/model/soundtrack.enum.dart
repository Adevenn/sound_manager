enum SoundtrackType {
  url,
  local;

  static SoundtrackType byName(String name) => switch (name) {
    'url' => url,
    'local' => local,
    _ => throw UnimplementedError(),
  };
}
