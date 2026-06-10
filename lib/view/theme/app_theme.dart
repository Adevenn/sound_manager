import 'package:flutter/material.dart';
import 'package:sound_manager/model/player_type.enum.dart';

/// Centralised design system for the app.
///
/// Everything visual that used to be hard-coded at call sites (raw
/// `Colors.green`, `Colors.white60`, ad-hoc font/icon sizes) is defined here so
/// the whole UI shares one coherent, heroic-fantasy dark identity built from a
/// single seed colour.
class AppTheme {
  AppTheme._();

  /// Warm gold seed — sets the overall "torch-lit, dark fantasy" tone.
  static const Color _seed = Color(0xFFC8964B);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surfaceContainer,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 16,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Per-channel visual identity (colour + icon + label) so Ambiance, Music and
/// Effects are distinguishable at a glance — the core scanning gesture for a
/// GM mid-session.
class ChannelStyle {
  final Color color;
  final IconData icon;
  final String label;
  const ChannelStyle(this.color, this.icon, this.label);
}

extension PlayerTypeStyle on PlayerType {
  ChannelStyle get style => switch (this) {
    PlayerType.ambiance => const ChannelStyle(
      Color(0xFF8B95E8), // night indigo — environment / mood
      Icons.landscape_rounded,
      'Ambiance',
    ),
    PlayerType.music => const ChannelStyle(
      Color(0xFFE0A458), // amber gold — score / theme
      Icons.music_note_rounded,
      'Music',
    ),
    PlayerType.effect => const ChannelStyle(
      Color(0xFF4FD1C5), // teal — punchy, instant triggers
      Icons.bolt_rounded,
      'Effects',
    ),
  };
}

/// Returns the most legible foreground (black/white) for text/icons drawn on
/// [background], so coloured effect chips stay readable whatever palette the
/// user picks.
Color contrastOn(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
