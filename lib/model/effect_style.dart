import 'package:flutter/material.dart';

/// Fixed palettes for per-effect customisation. Values are stored on
/// [Soundtrack] as indices into these lists so that:
/// - JSON stays small and stable,
/// - icons remain compile-time constants (so `tree-shake-icons` keeps working).
class EffectStyle {
  EffectStyle._();

  /// Background colours offered for an effect button (index 0 = default theme).
  static const List<Color?> colors = [
    null, // default (theme) colour
    Color(0xFFE53935), // red
    Color(0xFFFB8C00), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFF8E24AA), // purple
    Color(0xFF6D4C41), // brown
  ];

  /// Icons offered for an effect button (index 0 = generic).
  static const List<IconData> icons = [
    Icons.play_arrow_rounded,
    Icons.bolt_rounded, // thunder
    Icons.water_drop_rounded, // rain / water
    Icons.local_fire_department_rounded, // fire
    Icons.directions_walk_rounded, // footsteps
    Icons.notifications_rounded, // bell
    Icons.air_rounded, // wind
    Icons.shield_rounded, // combat
    Icons.pets_rounded, // creatures
    Icons.celebration_rounded, // crowd / tavern
  ];

  static Color? colorAt(int index) =>
      (index >= 0 && index < colors.length) ? colors[index] : null;

  static IconData iconAt(int index) =>
      (index >= 0 && index < icons.length) ? icons[index] : icons[0];
}
