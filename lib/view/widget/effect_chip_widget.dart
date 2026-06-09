import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/theme/app_theme.dart';

/// A single soundboard button.
///
/// Visual feedback layers, so a GM can read the board at a glance under
/// pressure:
/// - **hover** (mouse): the chip lightens and lifts slightly.
/// - **tap** (one-shot effect): quick press-down shrink, then plays.
/// - **long-press** (one-shot effect): morphs to an accent "tune" state to
///   signal it is opening the configuration, instead of firing the sound.
/// - **hold** (loop effect): glows with the channel accent while it sounds.
class EffectChip extends StatefulWidget {
  final Soundtrack track;

  /// One-shot trigger (non-loop effects).
  final VoidCallback onTrigger;

  /// Open the per-effect configuration (long-press / right-click).
  final VoidCallback onConfig;

  /// Loop effects: start/stop sounding while the pointer is held.
  final Future<void> Function() onHoldStart;
  final Future<void> Function() onHoldEnd;

  const EffectChip({
    super.key,
    required this.track,
    required this.onTrigger,
    required this.onConfig,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  State<EffectChip> createState() => _EffectChipState();
}

class _EffectChipState extends State<EffectChip> {
  bool _hovering = false;
  bool _pressed = false; // tap-down feedback (one-shot)
  bool _held = false; // loop effect currently sounding
  bool _arming = false; // long-press in progress → opening config

  Soundtrack get track => widget.track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = PlayerType.effect.style.color;
    final custom = EffectStyle.colorAt(track.colorIndex);
    final baseBg = custom ?? scheme.surfaceContainerHighest;
    final fg = custom != null ? contrastOn(custom) : scheme.onSurface;
    final icon = EffectStyle.iconAt(track.iconIndex);

    final active = _held || _arming; // accent-highlighted states
    final lit = _hovering || _pressed;

    final bg =
        lit ? Color.alphaBlend(fg.withValues(alpha: 0.12), baseBg) : baseBg;
    final borderColor =
        active
            ? accent
            : _hovering
            ? fg.withValues(alpha: 0.45)
            : scheme.outlineVariant;
    final scale =
        _pressed
            ? 0.95
            : _arming
            ? 1.06
            : _hovering
            ? 1.03
            : 1.0;

    final chip = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: active ? 2 : 1),
          boxShadow:
              _hovering || active
                  ? [
                    BoxShadow(
                      color: (active ? accent : Colors.black).withValues(
                        alpha: active ? 0.35 : 0.30,
                      ),
                      blurRadius: active ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _arming ? Icons.tune_rounded : icon,
              size: 18,
              color: _arming ? accent : fg,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                track.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg),
              ),
            ),
            if (track.loop) ...[
              const SizedBox(width: 4),
              Icon(
                _held ? Icons.graphic_eq_rounded : Icons.touch_app_rounded,
                size: 14,
                color: _held ? accent : fg,
              ),
            ],
          ],
        ),
      ),
    );

    final gesture =
        track.loop
            ? GestureDetector(
              onTapDown: (_) {
                setState(() => _held = true);
                widget.onHoldStart();
              },
              onTapUp: (_) {
                setState(() => _held = false);
                widget.onHoldEnd();
              },
              onTapCancel: () {
                setState(() => _held = false);
                widget.onHoldEnd();
              },
              onSecondaryTap: widget.onConfig,
              onLongPress: () {}, // swallow so a hold doesn't open config
              child: chip,
            )
            : GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onTrigger,
              onSecondaryTap: widget.onConfig,
              onLongPressStart:
                  (_) => setState(() {
                    _arming = true;
                    _pressed = false;
                  }),
              // Reset here rather than only in onLongPressEnd: opening the
              // config dialog interrupts the gesture, so onLongPressEnd may
              // never fire and the "arming" highlight would stay stuck.
              onLongPress: () {
                setState(() {
                  _arming = false;
                  _hovering = false;
                });
                widget.onConfig();
              },
              onLongPressEnd: (_) => setState(() => _arming = false),
              child: chip,
            );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:
          (_) => setState(() {
            _hovering = false;
            _pressed = false;
          }),
      child: gesture,
    );
  }
}
