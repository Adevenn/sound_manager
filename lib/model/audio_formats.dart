import 'package:path/path.dart' as p;

/// Audio file extensions the app accepts (folder scan, drag & drop).
const Set<String> kAudioExtensions = {
  '.mp3',
  '.wav',
  '.ogg',
  '.flac',
  '.m4a',
  '.aac',
};

/// True when [path] points at a file with a supported audio extension.
bool isAudioFile(String path) =>
    kAudioExtensions.contains(p.extension(path).toLowerCase());

/// Hosts whose links are web *pages*, not audio streams: a player can never
/// read them (e.g. a Spotify track link returns HTML, not audio).
const List<String> kPageOnlyHosts = [
  'spotify.com',
  'youtube.com',
  'youtu.be',
  'music.apple.com',
  'deezer.com',
  'soundcloud.com',
  'tidal.com',
  'bandcamp.com',
];

/// Returns a user-facing problem description for [url], or null when it looks
/// playable (a direct http(s) audio URL such as an .mp3 file or a web-radio
/// stream).
String? urlStreamProblem(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    return 'Enter a valid http(s) URL.';
  }
  final host = uri.host.toLowerCase();
  if (kPageOnlyHosts.any((h) => host == h || host.endsWith('.$h'))) {
    return 'Links from ${uri.host} are web pages, not audio streams — they '
        'cannot be played. Use a direct audio URL instead (a .mp3/.ogg '
        'file or a web-radio stream).';
  }
  return null;
}
