import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/background_effect.dart';
import 'package:flutter_ai_music/ui/component/element/track_tile.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../data/database/track_database.dart';
import '../component/element/recent_tracks.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedTracks());
  }

  Future<void> fetchTracks() async {
    final trackService = ref.read(trackServiceProvider);
    final res = await trackService.getAllTracks();
    if (!mounted) return;
    setState(() => tracks = res);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTracks() async {
    final savedTracks = await TrackDatabase.instance.getAllTracks();
    log("Loaded ${savedTracks.length} saved tracks from database");
    if (!mounted) return;
    setState(() => tracks = savedTracks);
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

  Future<void> _playTrack(WidgetRef ref, List<Track> allTracks, int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: allTracks, selectedIndex: selectedIndex);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }

  List<EffectState> buildStates(double height) => [
    EffectState(
      height: height * 0.75,
      alignment: const Alignment(-0.85, -0.65),
      radius: 0.55,
      colors: [Colors.cyan.withAlpha(15), Colors.transparent],
    ),
    EffectState(
      height: height * 0.75,
      alignment: const Alignment(0.85, -0.6),
      radius: 0.75,
      colors: [Theme.of(context).colorScheme.onSecondaryFixed.withAlpha(100), Colors.transparent],
    ),
    EffectState(
      height: height * 0.75,
      alignment: const Alignment(0, -0.22),
      radius: 0.55,
      colors: [Theme.of(context).colorScheme.onTertiaryFixedVariant.withAlpha(25), Colors.transparent],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider).value;
    final height = MediaQuery.of(context).size.height;
    final surfaceDim = Theme.of(context).colorScheme.surfaceDim;
    final states = buildStates(height);

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
                  height: height * 0.75,
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
                ...states.map((effectState) => BackgroundEffect(state: effectState, opacity: opacity)),
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
                      GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/icons/cloud.svg", width: 42),
                            const SizedBox(width: 10),
                            const Text(
                              'Flussic',
                              style: TextStyle(fontFamily: "Klavika", fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async => await fetchTracks(),
                            icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch02),
                          ),
                          PopupMenuButton<SortType>(
                            icon: const HugeIcon(icon: HugeIcons.strokeRoundedChart03),
                            onSelected: (value) {
                              setState(() {
                                tracks = switch (value) {
                                  SortType.newest => tracks..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                                  SortType.popular => tracks,
                                  SortType.duration => tracks..shuffle(),
                                };
                              });
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
                          _playTrack(ref, tracks, index);
                        },
                      )
                    : SizedBox.shrink(),
              ),

              if (tracks.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: double.infinity,
                    child: Lottie.asset("assets/animations/impress.json", repeat: false),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TrackTile(
                      track: tracks[index],
                      onTap: () => _playTrack(ref, tracks, index),
                      onLongPress: () {},
                      currentTrackId: currentTrack?.id,
                    ),
                    childCount: tracks.length,
                  ),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 200)),
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
                duration: const Duration(milliseconds: 300),
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
