enum PlayerType {
  ambiance,
  music,
  effect;

  static PlayerType byName(String name) {
    return switch (name.toLowerCase()) {
      'ambiance' => ambiance,
      'music' => music,
      'effect' => effect,
      _ => throw Exception,
    };
  }
}
