import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AudioSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Volume maître',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
                  title: const Text('Fondus (fade in/out)'),
                  subtitle: const Text(
                    'Transitions en douceur à la lecture/pause',
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
                    'Recouvre les deux morceaux lors d\'un changement',
                  ),
                  value: value,
                  onChanged: settings.setCrossfadeEnabled,
                ),
          ),
          const Divider(),
          const Text(
            'Durées de fondu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ValueListenableBuilder<int>(
            valueListenable: settings.shortFadeMs,
            builder:
                (context, value, child) => _durationRow(
                  label: 'Pause / lecture',
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
                  label: 'Changement de morceau',
                  ms: value,
                  min: 0,
                  max: 8000,
                  onChanged: (v) => settings.longFadeMs.value = v,
                  onChangeEnd: (v) => settings.setLongFadeMs(v),
                ),
          ),
        ],
      ),
    );
  }

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
