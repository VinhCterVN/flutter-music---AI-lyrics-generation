import 'package:on_audio_query/on_audio_query.dart';

/// Thin wrapper around OnAudioQuery providing the two calls we need:
/// 1. All unique folders that contain at least one audio file.
/// 2. All songs inside a given folder path.
class LocalAudioService {
  static final LocalAudioService instance = LocalAudioService._();
  LocalAudioService._();

  final OnAudioQuery _query = OnAudioQuery();

  /// Request READ_MEDIA_AUDIO / READ_EXTERNAL_STORAGE permission.
  Future<bool> requestPermission() => _query.permissionsRequest();

  Future<bool> get hasPermission => _query.permissionsStatus();

  /// Returns a de-duplicated, sorted list of folder paths that contain audio.
  Future<List<LocalFolder>> getFolders() async {
    final songs = await _query.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final Map<String, LocalFolder> folderMap = {};
    for (final song in songs) {
      final path = song.data; // e.g. /storage/emulated/0/Music/song.mp3
      final folderPath = path.substring(0, path.lastIndexOf('/'));
      final folderName = folderPath.split('/').last;

      if (!folderMap.containsKey(folderPath)) {
        folderMap[folderPath] = LocalFolder(
          path: folderPath,
          name: folderName.isEmpty ? 'Root' : folderName,
          songCount: 1,
        );
      } else {
        folderMap[folderPath] = folderMap[folderPath]!.incrementCount();
      }
    }

    final folders = folderMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Returns all audio files inside [folderPath].
  Future<List<SongModel>> getSongsInFolder(String folderPath) async {
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    return songs.where((s) {
      final songFolder = s.data.substring(0, s.data.lastIndexOf('/'));
      return songFolder == folderPath;
    }).toList();
  }

  OnAudioQuery get query => _query;
}

class LocalFolder {
  final String path;
  final String name;
  final int songCount;

  const LocalFolder({
    required this.path,
    required this.name,
    required this.songCount,
  });

  LocalFolder incrementCount() => LocalFolder(path: path, name: name, songCount: songCount + 1);
}
