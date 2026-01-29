import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/ui/component/element/background_effect.dart';
import 'package:flutter_ai_music/ui/component/element/top_categories.dart';
import 'package:flutter_ai_music/ui/component/element/track_tile.dart';
import 'package:flutter_ai_music/ui/component/navigation/track_options_bottom_sheet.dart';
import 'package:flutter_ai_music/utils/mock_tracks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../component/element/recent_tracks.dart';
import '../component/element/recently_played_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late ScrollController _controller;
  List<Track> tracks = [];
  int selectedGenreIndex = -1;
  UIState _state = UIState.loading;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          tracks = mockTracks;
          _state = UIState.ready;
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGenreChanged(int index) async {
    setState(() {});
  }

  List<EffectState> _buildStates(double height) => [
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
    final states = _buildStates(height);

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
          onRefresh: () async => Fluttertoast.showToast(msg: 'Already up to date!'),
          child: Scrollbar(
            controller: _controller,
            interactive: true,
            radius: const Radius.elliptical(5, 5),
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
                                style: TextStyle(fontFamily: "SpotifyMixUI", fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.push('/search_detail'),
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch02),
                            ),
                            PopupMenuButton<SortType>(
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedChart03),
                              onSelected: (value) {},
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
                if (_state == UIState.loading)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: double.infinity,
                      child: Lottie.asset("assets/animations/impress.json", repeat: false),
                    ),
                  )
                else ...[
                  SliverPadding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), sliver: const TopCategories()),
                  const SliverToBoxAdapter(child: RecentlyPlayedSection()),
                  SliverToBoxAdapter(child: const RecentTracksSection()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TrackTile(
                        track: tracks[index],
                        onTap: () {},
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.5,
                            minChildSize: 0.5,
                            maxChildSize: 0.75,
                            snap: true,
                            snapSizes: const [0.5, 0.75],
                            builder: (context, controller) =>
                                TrackOptionsBottomSheet(track: tracks[index], scrollController: controller),
                          ),
                        ),
                        currentTrackId: currentTrack?.id,
                      ),
                      childCount: tracks.length,
                    ),
                  )
                ],
                // if (_isFetching)
                //   SliverToBoxAdapter(
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(vertical: 16.0),
                //       child: Center(
                //         child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurfaceVariant),
                //       ),
                //     ),
                //   ),
                SliverToBoxAdapter(child: const SizedBox(height: 200)),
              ],
            ),
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

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // final Color backgroundColor = overlapsContent
    //     ? Theme.of(context).colorScheme.surfaceDim.withAlpha(100)
    //     : Colors.transparent;

    final double blurAmount = overlapsContent ? 5.0 : 0.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
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
