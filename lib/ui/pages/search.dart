import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/element/press_scale.dart';
import 'package:flutter_ai_music/ui/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            toolbarHeight: 48,
            scrolledUnderElevation: 0,
            backgroundColor: scheme.surfaceDim,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CircleAvatar(backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150')),
            ),
            leadingWidth: 50,
            title: const Text(
              'Search',
              style: TextStyle(fontFamily: appFontFamily, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 23),
                onPressed: () {},
              ),
            ],
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(topPadding: MediaQuery.paddingOf(context).top),
          ),

          SliverToBoxAdapter(child: _buildAdSection("Featured Ads")),

          SliverToBoxAdapter(child: _buildAdSection("Recent Promotions")),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Category $index",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.25),
                  ),
                ),
                childCount: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 5,
            itemBuilder: (context, index) {
              final randomImage = 'https://picsum.photos/200/300?random=${index + Random().nextInt(1000)}';
              return PressScale(
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100 * ((index % 5) + 1)],
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: NetworkImage(randomImage), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarDelegate({required this.topPadding});

  final double topPadding;

  static const _searchBarHeight = 48.0;
  static const _verticalPadding = 4.0;

  double get _extent => topPadding + _searchBarHeight + (_verticalPadding * 2);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      color: scheme.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, _verticalPadding, 16, _verticalPadding * 2),
        child: Container(
          height: _searchBarHeight,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: const TextField(
            decoration: InputDecoration(
              hintText: "What should we listen to?",
              hintStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, letterSpacing: -0.25),
              prefixIcon: Padding(
                padding: EdgeInsets.all(8.0),
                child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.black87),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => topPadding != oldDelegate.topPadding;
}
