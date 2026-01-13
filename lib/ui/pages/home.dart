import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/recent_tracks.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late ScrollController _controller;
  List<Track> tracks = [];
  int selectedGenreIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) => fetchTracks());
  }

  Future<void> fetchTracks() async {
    final trackService = ref.read(trackServiceProvider);
    final res = await trackService.getAllTracks(ref);
    if (!mounted) return;
    setState(() => tracks = res);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGenreChanged(int index) async {
    setState(() {
      if (index == selectedGenreIndex) {
        selectedGenreIndex = -1;
      } else {
        selectedGenreIndex = index;
      }
    });
  }

  Future<void> _playTrack(BuildContext context, WidgetRef ref, List<Track> allTracks, int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: allTracks, selectedIndex: selectedIndex);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing track: $e'), duration: const Duration(seconds: 1)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final authService = ref.read(authenticationServiceProvider);
    final height = MediaQuery.of(context).size.height;
    final surfaceDim = Theme.of(context).colorScheme.surfaceDim;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scrollOffset = _controller.hasClients ? _controller.offset : 0.0;
            final opacity = (1.0 - (scrollOffset / 200)).clamp(0.0, 1.0);

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 1.0],
                        colors: [
                          Color.lerp(surfaceDim, Theme.of(context).colorScheme.onPrimaryFixed, opacity)!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.5,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.95, -0.75),
                          radius: 0.25,
                          colors: [Colors.cyan.withAlpha(25), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.75,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.85, -0.6),
                          radius: 0.75,
                          colors: [Theme.of(context).colorScheme.onSecondaryFixed.withAlpha(100), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        RefreshIndicator(
          onRefresh: () async => await fetchTracks(),
          child: CustomScrollView(
            controller: _controller,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset("assets/icons/cloud.svg", width: 42),
                          const SizedBox(width: 10),
                          const Text(
                            'Flussic',
                            style: TextStyle(fontFamily: "Klavika", fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
                          PopupMenuButton<SortType>(
                            icon: const Icon(Icons.sort),
                            onSelected: (value) {
                              setState(() {});
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: SortType.newest, child: Text('Newest')),
                              PopupMenuItem(value: SortType.popular, child: Text('Most popular')),
                              PopupMenuItem(value: SortType.duration, child: Text('Duration')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: GenreStickyDelegate(selectedIndex: selectedGenreIndex, onChanged: _onGenreChanged),
              ),

              SliverToBoxAdapter(
                child: tracks.isNotEmpty
                    ? RecentTracksSection(
                        tracks: tracks,
                        onTrackTap: (track) {
                          final index = tracks.indexOf(track);
                          _playTrack(context, ref, tracks, index);
                        },
                      )
                    : SizedBox.shrink(),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ListTile(
                    visualDensity: VisualDensity(vertical: -3),
                    minVerticalPadding: 0,
                    leading: CircleAvatar(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                        child: CachedNetworkImage(
                          imageUrl: tracks[index].images.first,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(Icons.image_outlined),
                          placeholder: (context, url) =>
                              Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        ),
                      ),
                    ),
                    title: Text(
                      tracks[index].name,
                      maxLines: 1,
                      style: TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tracks[index].artistType.name, style: TextStyle(fontFamily: "SpotifyMixUI")),
                    onTap: () => _playTrack(context, ref, tracks, index),
                    onLongPress: () => showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      builder: (context) => BottomSheet(
                        onClosing: () => Navigator.pop(context),
                        builder: (c) => Padding(padding: EdgeInsets.all(8), child: Text(tracks[index].name)),
                      ),
                    ),
                  ),
                  childCount: (tracks.length / 2).toInt(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GenreStickyDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  GenreStickyDelegate({this.selectedIndex = 0, required this.onChanged});

  final List<String> genres = [
    "Pop",
    "Rock",
    "Jazz",
    "Classical",
    "Hip-Hop",
    "Electronic",
    "Country",
    "Reggae",
    "Blues",
    "Folk",
  ];

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final Color backgroundColor = overlapsContent
        ? Theme.of(context).colorScheme.surfaceDim.withAlpha(180)
        : Colors.transparent;

    final double blurAmount = overlapsContent ? 10.0 : 0.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          color: backgroundColor,
          height: 88,
          alignment: Alignment.center,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: ChoiceChip(
                  label: Text(genres[index], style: TextStyle(color: Colors.white, fontSize: 13)),
                  selected: index == selectedIndex,
                  onSelected: (_) => onChanged(index),
                  backgroundColor: Colors.white.withAlpha(25),
                  elevation: 0,
                  side: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 88.0;

  @override
  double get minExtent => 88.0;

  @override
  bool shouldRebuild(covariant GenreStickyDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

enum SortType { newest, popular, duration }
