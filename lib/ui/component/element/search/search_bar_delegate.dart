import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/element/search/search_bar.dart';

class SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return const MySearchBar();
  }

  @override
  double get maxExtent => 72; // Height when fully expanded
  @override
  double get minExtent => 72; // Height when collapsed (same = pinned)
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
