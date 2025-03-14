enum SoundtrackType {
  url,
  local;

  SoundtrackType byName(String name) => switch (name) {
    'url' => url,
    'local' => local,
    _ => throw UnimplementedError(),
  };
}
