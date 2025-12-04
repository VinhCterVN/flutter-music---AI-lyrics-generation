import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/audio_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/audio_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late ScrollController _controller;
  List<Track> tracks = [];
  StreamSubscription<List<Track>>? _sub;

  @override
  void initState() {
    _controller = ScrollController();

    final trackService = ref.read(trackServiceProvider);
    _sub = trackService.streamTrackList(ref).listen((newTracks) {
      setState(() {
        tracks = newTracks;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
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
    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverPersistentHeader(delegate: MyStickyHeader(), floating: true),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(
              leading: CircleAvatar(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadiusGeometry.all(Radius.circular(4))),
                  child: CachedNetworkImage(
                    imageUrl: tracks[index].images.first,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => Icon(Icons.image_outlined),
                  ),
                ),
              ),
              title: Text(tracks[index].name, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tracks[index].createdAt.toString()),
              onTap: () => _playTrack(context, ref, tracks, index),
            ),
            childCount: tracks.length,
          ),
        ),
      ],
    );
  }
}

class MyStickyHeader extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(55), offset: Offset(0, 4), blurRadius: 6, spreadRadius: 0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Container with bottom shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  double get maxExtent => 80 + MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.top;

  @override
  double get minExtent => 60 + MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.top;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
