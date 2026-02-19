import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/user.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaylistAuthor extends ConsumerStatefulWidget {
  final String userId;
  final Playlist playlist;

  const PlaylistAuthor({super.key, required this.userId, required this.playlist});

  @override
  ConsumerState<PlaylistAuthor> createState() => _PlaylistAuthorState();
}

class _PlaylistAuthorState extends ConsumerState<PlaylistAuthor> {
  User? _author;

  @override
  void initState() {
    _fetchUser();
    super.initState();
  }

  Future<void> _fetchUser() async {
    final user = await ref.read(userServiceProvider).getUserFromId(widget.userId);
    setState(() => _author = user);
  }

  @override
  Widget build(BuildContext context) {
    if (_author == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 8,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.person, color: Colors.white54, size: 16),
          ),
          Text(
            "Loading...  •  ${widget.playlist.trackIds.length} songs",
            style: TextStyle(
              fontFamily: "SpotifyMixUI",
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: (-0.5),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 8,
      children: [
        ClipOval(
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: _author?.photoUrl ?? "https://i.pravatar.cc/300?u=${_author?.id}",
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Icon(Icons.person, color: Colors.white54, size: 16),
            ),
          ),
        ),

        Text(
          "${_author!.displayName.isNotEmpty ? _author!.displayName : "Author"}  •  ${widget.playlist.trackIds.length} songs",
          style: TextStyle(
            fontFamily: "SpotifyMixUI",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: (-0.5),
          ),
        ),
      ],
    );
  }
}
