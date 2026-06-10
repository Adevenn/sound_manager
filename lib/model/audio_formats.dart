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
