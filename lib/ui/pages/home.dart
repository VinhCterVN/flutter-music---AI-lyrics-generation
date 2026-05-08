import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/ui/component/element/home/home_discovery_sections.dart';
import 'package:flutter_ai_music/ui/component/element/top_categories.dart';
import 'package:flutter_ai_music/utils/mock_tracks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
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
  late final List<Widget> _dynamicHomeSections;
  int selectedGenreIndex = -1;
  UIState _state = UIState.loading;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _dynamicHomeSections = [const HomeDiscoverySections(), const SliverToBoxAdapter(child: RecentTracksSection())]
      ..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
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
    if (selectedGenreIndex == index) return;
    setState(() {
      selectedGenreIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        controller: _controller,
        cacheExtent: 1000.0,
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
            const SliverPadding(padding: EdgeInsets.fromLTRB(18, 0, 18, 12), sliver: TopCategories()),
            const SliverToBoxAdapter(child: RecentlyPlayedSection()),
            ..._dynamicHomeSections,
          ],
          SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),
    );
  }
}

class GenreStickyDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  GenreStickyDelegate({this.selectedIndex = 0, required this.onChanged});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
              child: ChoiceChip(
                label: Text(genres[index], style: const TextStyle(color: Colors.white, fontSize: 13)),
                selected: index == selectedIndex,
                onSelected: (_) => onChanged(index),
                backgroundColor: Colors.white.withAlpha(25),
                elevation: 0,
                side: BorderSide.none,
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
