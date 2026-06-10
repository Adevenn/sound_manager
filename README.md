# Sound Manager

A desktop soundboard and ambiance mixer for tabletop game masters, built with
Flutter. Run three independent audio channels at once — **Ambiance**, **Music**
and **Effects** — and drive a whole game session's soundscape from one window.

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.7-02569B?logo=flutter)

## Features

### Three parallel channels
- **Ambiance** and **Music** play side by side, each with its own playlist,
  loop/shuffle modes, seek bar and volume.
- **Effects** is a launchpad-style soundboard docked at the bottom: paginated
  banks of one-shot pads with per-effect colour, icon and volume.

### Playback
- **Fades & cross-fades** — smooth fade in/out on play/pause and true two-player
  cross-fade on track changes, with configurable short/long durations.
- **Scene transitions** — switching scenes cross-fades all three channels
  together over a configurable duration.
- **Auto-duck** — ambiance and music dip to a configurable level while an
  effect is sounding, then ramp back up.
- **Press-and-hold loop effects** — flag an effect as *Hold = loop* (rain,
  wind…) and it loops for exactly as long as the pad is held.
- **URL streaming** — playlists can mix local files and `http(s)` audio
  streams (direct audio URLs: an `.mp3`/`.ogg` file or a web-radio stream —
  *page* links from Spotify/YouTube/etc. are not audio and cannot be played).

### Scenes
Save the entire desk state (the three playlists + volumes) as a named **scene**
("Tavern", "Combat", "Dungeon"…) and recall it in one click, with a smooth
full-soundscape cross-fade. Scenes can be renamed, duplicated and deleted.

### Generative ambiance
Flag any effects as **Generative** (distant howls, thunder, creaking doors…)
and toggle the dice button in the app bar: the app fires a random one at a
random interval (configurable min/max delay), endlessly, hands-free.

### Campaigns
Each **campaign** is a fully isolated profile — its own playlists, scenes,
soundboard and per-channel settings. Switch from the chip in the app bar;
create, rename or delete campaigns from the same dialog. Existing data is
migrated into the *Default* campaign automatically on first launch.

### Quality of life
- **Drag & drop from the file explorer** straight onto any channel.
- **Keyboard shortcuts** (rebindable): global play/pause, per-channel
  pause/next, and one key per soundboard slot (defaults: `Space`, `1`–`9`).
- **Mouse wheel** over any volume slider adjusts it.
- **Search/filter** boxes in the playlist editor (source folder + playlist).
- Playlist **rename / duplicate / save-as**, drag-to-reorder, missing-file
  detection (broken tracks are flagged, never crash playback).
- Window size & position are remembered between launches.
- Everything persists: per-channel volume, current playlist, current track,
  loop/shuffle modes, all settings.

## Getting started

```bash
flutter pub get
flutter run -t lib/controller/main.dart
```

> **Note** — the entrypoint is `lib/controller/main.dart` (not the default
> `lib/main.dart`), so the `-t` flag is required for `run` and `build`:
>
> ```bash
> flutter build windows -t lib/controller/main.dart
> ```

Supported audio formats: `.mp3`, `.wav`, `.ogg`, `.flac`, `.m4a`, `.aac`
(actual codec support depends on the platform's media backend).

## Usage tips

| Action | How |
|---|---|
| Add tracks | Drag files from the explorer onto a channel, or open the playlist editor (coloured button) and click/drag from the source folder |
| Add a URL stream | Playlist editor → link button |
| Configure an effect pad | Right-click (or long-press) the pad |
| Trigger effects | Click a pad, or keys `1`–`9` |
| Hold-to-loop effect | Enable *Hold = loop* in the pad config, then press and hold |
| Stop every effect | Stop button in the Effects header |
| Save / apply a scene | Movie icon in the app bar |
| Generative mode | Flag pads as *Generative*, then the dice icon in the app bar |
| Switch campaign | Campaign chip in the app bar |
| Rebind shortcuts | Settings → Keyboard shortcuts |

## Data & storage

All data lives under the platform application-support directory:

```
<appSupport>/Data/Campaigns/<campaign>/
  Playlist/<name>.json     # one file per playlist
  scenes.json              # the campaign's scenes
```

Settings (volumes, fades, shortcuts, window bounds…) are stored in shared
preferences, namespaced per campaign. All JSON writes are atomic (temp file +
rename), so a crash can never corrupt saved data.

## Architecture

```
lib/
  controller/main.dart        # entrypoint + main screen (channels, scenes, campaigns)
  model/                      # pure logic, no Flutter UI imports
    audio_player_manager.dart # one logical channel: dual players, fades, effect pool
    playlist.dart             # in-memory playlist (loop, shuffle bag, reorder)
    *_repository.dart         # JSON persistence (playlists, scenes)
    campaign_manager.dart     # per-campaign storage roots + switching
    duck_controller.dart      # global auto-duck state
    generative_trigger.dart   # random-effect ambiance timer
    shortcut_settings.dart    # rebindable keys with conflict stealing
  view/
    playlist_screen.dart      # playlist editor (folder browser + working list)
    settings_screen.dart      # audio, duck, generative and shortcut settings
    widget/                   # channel panel, soundboard, pads, drop target…
```

Key design points:

- Each channel owns **two** `AudioPlayer`s so a track change can truly
  cross-fade (the incoming track ramps up on the idle player while the
  outgoing one ramps down, then they swap roles).
- Effects play on a small **pooled** set of players so pads can overlap without
  spawning a native player per trigger; held loops are never recycled out from
  under the user.
- Models are UI-free and covered by unit tests (`flutter test`).

## Development

```bash
flutter analyze          # static analysis (zero warnings policy)
flutter test             # unit tests
dart format lib/ test/   # formatting
```
