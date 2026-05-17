import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/featured_tracks_section.dart';
import 'package:flutter_ai_music/ui/component/element/home/home_discovery_sections.dart';
import 'package:flutter_ai_music/ui/component/element/top_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../component/element/recent_tracks.dart';
import '../component/element/recently_played_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _featuredTracksLimit = 12;
  static const _recentlyPlayedLimit = 10;
  static const _recentTracksLimit = 20;

  late ScrollController _controller;
  late final List<Widget> _dynamicHomeSections;
  int selectedGenreIndex = -1;
  int _selectedHeaderChipIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _dynamicHomeSections = [const HomeDiscoverySections(), const SliverToBoxAdapter(child: RecentTracksSection())]
      ..shuffle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: CustomScrollView(
        controller: _controller,
        cacheExtent: size.height * 2,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 157.5,
            backgroundColor: theme.colorScheme.surfaceDim,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.paddingOf(context).top;
                final collapsedHeight = kToolbarHeight + topPadding;
                final collapseProgress = ((collapsedHeight + 36 - constraints.maxHeight) / 36).clamp(0.0, 1.0);
                final searchMorphProgress = Curves.easeOutCubic.transform(collapseProgress.toDouble());

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: collapseProgress.toDouble(),
                    child: IgnorePointer(
                      ignoring: collapseProgress < 0.95,
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          height: kToolbarHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.45 * collapseProgress.toDouble(),
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: _buildCollapsedHeader(theme, collapseProgress.toDouble()),
                        ),
                      ),
                    ),
                  ),
                  expandedTitleScale: 1,
                  background: Stack(
                    fit: StackFit.loose,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.onPrimaryFixedVariant.withAlpha(200), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SizedBox.expand(),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
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
                            const SizedBox(height: 14),
                            IgnorePointer(
                              ignoring: collapseProgress > 0.92,
                              child: _buildMorphingSearchBar(theme, searchMorphProgress, constraints.maxWidth - 32),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            leading: SizedBox.shrink(),
            leadingWidth: 0.0,
          ),
          const SliverPadding(padding: EdgeInsets.fromLTRB(18, 0, 18, 12), sliver: TopCategories()),
          const SliverToBoxAdapter(child: FeaturedTracksSection()),
          const SliverToBoxAdapter(child: RecentlyPlayedSection()),
          ..._dynamicHomeSections,
          SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),
    );
  }

  Future<void> _refreshHome() async {
    ref.invalidate(homeDiscoveryProvider);
    ref.invalidate(featuredTracksProvider(_featuredTracksLimit));
    ref.invalidate(recentTracksProvider(_recentlyPlayedLimit));
    ref.invalidate(recentTracksProvider(_recentTracksLimit));
    await ref.read(homeDiscoveryProvider.future);
  }

  Widget _buildMorphingSearchBar(ThemeData theme, double progress, double maxWidth) {
    final expandedWidth = maxWidth.clamp(44.0, 600.0);
    final barWidth = lerpDouble(expandedWidth, 44, progress)!;
    final barHeight = lerpDouble(48, 40, progress)!;
    final borderRadius = lerpDouble(12, 20, progress)!;
    final horizontalPadding = lerpDouble(16, 10, progress)!;
    final textOpacity = (1 - (progress * 1.35)).clamp(0.0, 1.0);
    final shadowOpacity = lerpDouble(0.06, 0.0, progress)!;
    final borderOpacity = lerpDouble(0.55, 0.2, progress)!;
    final finalLeftOffset = (expandedWidth - 92).clamp(0.0, expandedWidth);
    final horizontalOffset = lerpDouble(0, finalLeftOffset, progress)!;
    final verticalOffset = lerpDouble(0, -42, progress)!;
    final scale = lerpDouble(1, 0.92, progress)!;
    final morphOpacity = progress > 0.94 ? (1 - ((progress - 0.94) / 0.06)).clamp(0.0, 1.0) : 1.0;

    return Transform.translate(
      offset: Offset(horizontalOffset, verticalOffset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: morphOpacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/search_detail'),
              child: SizedBox(
                width: barWidth,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: lerpDouble(0.94, 0.98, progress)!),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: borderOpacity),
                      width: lerpDouble(0.5, 0.8, progress)!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        blurRadius: lerpDouble(18, 8, progress)!,
                        offset: Offset(0, lerpDouble(8, 2, progress)!),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch02,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: lerpDouble(20, 18, progress)!,
                      ),
                      if (textOpacity > 0) ...[
                        SizedBox(width: lerpDouble(12, 0, progress)!),
                        Expanded(
                          child: Opacity(
                            opacity: textOpacity,
                            child: Text(
                              'Search songs, moods, and artists',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: lerpDouble(14, 12, progress)!,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(ThemeData theme, double collapseProgress) {
    final chips = ['For You', 'Focus'];
    final collapsedSearchOpacity = ((collapseProgress - 0.9) / 0.1).clamp(0.0, 1.0);

    return Row(
      children: [
        const _CollapsedHeaderAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(chips.length, (index) {
                final isSelected = _selectedHeaderChipIndex == index;

                return Padding(
                  padding: EdgeInsets.only(right: index == chips.length - 1 ? 0 : 8),
                  child: ChoiceChip(
                    label: Text(chips[index]),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedHeaderChipIndex = index;
                      });
                    },
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.18)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Opacity(
          opacity: collapsedSearchOpacity,
          child: IgnorePointer(
            ignoring: collapsedSearchOpacity < 0.95,
            child: IconButton(
              onPressed: () => context.push('/search_detail'),
              visualDensity: VisualDensity.compact,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch02, size: 20),
            ),
          ),
        ),
        PopupMenuButton<SortType>(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreHorizontalCircle01, size: 20),
          onSelected: (value) {},
          itemBuilder: (context) => const [
            PopupMenuItem(value: SortType.newest, child: Text('Newest')),
            PopupMenuItem(value: SortType.popular, child: Text('Most popular')),
            PopupMenuItem(value: SortType.duration, child: Text('Duration')),
          ],
        ),
      ],
    );
  }
}

enum SortType { newest, popular, duration }

class _CollapsedHeaderAvatar extends ConsumerWidget {
  const _CollapsedHeaderAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final photoUrl = user?.userMetadata?["photoUrl"] ?? 'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';

    return InkWell(
      onTap: () => Scaffold.of(context).openDrawer(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withValues(alpha: 0.14)),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: 'avatar-drawer',
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Icon(Icons.account_circle, size: 24, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
