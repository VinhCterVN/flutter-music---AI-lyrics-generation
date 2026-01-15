
import 'package:flutter_ai_music/service/playlist_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playlistServiceProvider = Provider<PlaylistService>((ref) => PlaylistService(ref));