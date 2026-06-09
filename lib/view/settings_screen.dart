import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sound_manager/model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AudioSettings.instance;
  final shortcuts = ShortcutSettings.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Master volume'),
          ValueListenableBuilder<double>(
            valueListenable: settings.masterVolume,
            builder:
                (context, value, child) => Row(
                  children: [
                    const Icon(Icons.volume_up_rounded),
                    Expanded(
                      child: Slider(
                        value: value,
                        // Live, in-memory update while dragging (re-applies to
                        // the players); persist to disk only on release.
                        onChanged: (v) => settings.masterVolume.value = v,
                        onChangeEnd: settings.setMasterVolume,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${(value * 100).round()}%'),
                    ),
                  ],
                ),
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: settings.fadeEnabled,
            builder:
                (context, value, child) => SwitchListTile(
                  title: const Text('Fades (fade in/out)'),
                  subtitle: const Text(
                    'Smooth transitions on play/pause',
                  ),
                  value: value,
                  onChanged: settings.setFadeEnabled,
                ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.crossfadeEnabled,
            builder:
                (context, value, child) => SwitchListTile(
                  title: const Text('Cross-fade'),
                  subtitle: const Text(
                    'Overlaps both tracks on a track change',
                  ),
                  value: value,
                  onChanged: settings.setCrossfadeEnabled,
                ),
          ),
          const Divider(),
          _sectionTitle('Fade durations'),
          ValueListenableBuilder<int>(
            valueListenable: settings.shortFadeMs,
            builder:
                (context, value, child) => _durationRow(
                  label: 'Pause / play',
                  ms: value,
                  min: 0,
                  max: 3000,
                  onChanged: (v) => settings.shortFadeMs.value = v,
                  onChangeEnd: (v) => settings.setShortFadeMs(v),
                ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: settings.longFadeMs,
            builder:
                (context, value, child) => _durationRow(
                  label: 'Track change',
                  ms: value,
                  min: 0,
                  max: 8000,
                  onChanged: (v) => settings.longFadeMs.value = v,
                  onChangeEnd: (v) => settings.setLongFadeMs(v),
                ),
          ),
          const Divider(),
          _shortcutsSection(),
        ],
      ),
    );
  }

  // -- Shortcuts ------------------------------------------------------------

  Widget _shortcutsSection() {
    return ValueListenableBuilder<int>(
      valueListenable: shortcuts.revision,
      builder:
          (context, _, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _sectionTitle('Keyboard shortcuts')),
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset'),
                    onPressed: shortcuts.resetDefaults,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Click a key to reassign it.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _shortcutRow(
                icon: Icons.play_circle_outline_rounded,
                label: 'Play / Pause all',
                current: shortcuts.playPauseAll,
                onRebind: () async {
                  final key = await _captureKey();
                  if (key != null) shortcuts.setPlayPauseAll(key);
                },
              ),
              const Divider(),
              for (int i = 0; i < ShortcutSettings.effectSlots; i++)
                _shortcutRow(
                  icon: Icons.bolt_rounded,
                  label: 'Effect ${i + 1}',
                  current: shortcuts.effectKeys[i],
                  onRebind: () async {
                    final key = await _captureKey();
                    if (key != null) shortcuts.setEffectKey(i, key);
                  },
                  onClear: () => shortcuts.setEffectKey(i, null),
                ),
            ],
          ),
    );
  }

  Widget _shortcutRow({
    required IconData icon,
    required String label,
    required LogicalKeyboardKey? current,
    required Future<void> Function() onRebind,
    VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: onRebind,
            child: SizedBox(
              width: 64,
              child: Text(
                ShortcutSettings.labelFor(current),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: current == null ? null : onClear,
            ),
        ],
      ),
    );
  }

  /// Opens a modal that captures the next non-modifier key press.
  Future<LogicalKeyboardKey?> _captureKey() {
    return showDialog<LogicalKeyboardKey>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Press a key'),
            content: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final k = event.logicalKey;
                  if (ShortcutSettings.isModifier(k)) {
                    return KeyEventResult.ignored;
                  }
                  Navigator.of(context).pop(k);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: const SizedBox(
                height: 56,
                child: Center(child: Text('Waiting for a key…')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // -- Shared bits ----------------------------------------------------------

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _durationRow({
    required String label,
    required int ms,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required ValueChanged<int> onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label)),
          Expanded(
            child: Slider(
              value: ms.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min) ~/ 250,
              label: '${(ms / 1000).toStringAsFixed(1)} s',
              onChanged: (v) => onChanged(v.round()),
              onChangeEnd: (v) => onChangeEnd(v.round()),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text('${(ms / 1000).toStringAsFixed(1)}s'),
          ),
        ],
      ),
    );
  }
}
