import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_ai_music/utils/functions.dart';
import 'package:flutter_ai_music/utils/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GenreDetailPage extends ConsumerWidget {
  final String genre;

  const GenreDetailPage({super.key, required this.genre});

  Color _getGenreColor(String genre) {
    final hash = genre.toLowerCase().hashCode;
    final colors = [
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreColor = _getGenreColor(genre);
    final size = MediaQuery.sizeOf(context);

    final bgColor = mixColors([MapEntry(genreColor, 0.25), const MapEntry(Colors.black, 0.75)]);
    final tracksAsyncValue = ref.watch(tracksByGenreProvider(genre));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    genreColor.withAlpha((0.85 * 255).toInt()),
                    genreColor.withAlpha((0.3 * 255).toInt()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Custom App Bar / Header info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50), // Spacing for back button row
                        Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        tracksAsyncValue.when(
                          data: (tracks) => Text(
                            'Genre • ${tracks.length} tracks available',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha((0.7 * 255).toInt()),
                            ),
                          ),
                          loading: () => const Text('Genre • Loading tracks...', style: TextStyle(color: Colors.white70)),
                          error: (_, __) => const Text('Genre • Error loading tracks', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(height: 24),
                        // Quick Action Play Button
                        tracksAsyncValue.when(
                          data: (tracks) {
                            if (tracks.isEmpty) return const SizedBox();
                            return Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  onPressed: () {
                                    AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: 0);
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                  label: const Text('Play Genre', style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: () {
                                    final shuffled = List<Track>.from(tracks)..shuffle();
                                    AudioHelper.playTrackFromList(ref, allTracks: shuffled, selectedIndex: 0);
                                  },
                                  icon: const Icon(Icons.shuffle_rounded),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Tracks list
                tracksAsyncValue.when(
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off_outlined, size: 64, color: Colors.white30),
                              SizedBox(height: 16),
                              Text(
                                'No tracks found for this genre',
                                style: TextStyle(fontSize: 16, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = tracks[index];
                            return _GenreTrackListTile(
                              track: track,
                              index: index,
                              onTap: () {
                                AudioHelper.playTrackFromList(ref, allTracks: tracks, selectedIndex: index);
                              },
                              onLongPress: () {
                                showTrackOptions(context, track);
                              },
                            );
                          },
                          childCount: tracks.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Failed to load tracks: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Floating Back Button
          Positioned(
            top: 10,
            left: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: context.pop,
                child: ClipOval(
                  child: Container(
                    color: Colors.black26,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreTrackListTile extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GenreTrackListTile({
    required this.track,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: track.images.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade900),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade900,
                    child: const Icon(Icons.music_note, color: Colors.white30),
                  ),
                )
              : Container(
                  color: Colors.grey.shade900,
                  child: const Icon(Icons.music_note, color: Colors.white30),
                ),
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.1),
      ),
      subtitle: Row(
        children: [
          if (track.isFavorite) ...[
            const Icon(Icons.favorite_rounded, size: 12, color: Colors.greenAccent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              track.artistName ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha((0.6 * 255).toInt())),
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
        onPressed: onLongPress,
      ),
    );
  }
}
