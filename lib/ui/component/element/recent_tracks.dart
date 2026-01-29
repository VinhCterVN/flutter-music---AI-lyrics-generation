import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/enums/ui_state.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecentTracksSection extends ConsumerStatefulWidget {
  const RecentTracksSection({super.key});

  @override
  ConsumerState<RecentTracksSection> createState() => _RecentTracksSectionState();
}

class _RecentTracksSectionState extends ConsumerState<RecentTracksSection> {
  List<Track> _tracks = [];
  UIState _state = UIState.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecentTracks());
  }

  Future<void> _fetchRecentTracks() async {
    setState(() => _state = UIState.loading);
    try {
      final tracks = await ref.read(trackServiceProvider).getRecentTracks();
      if (!mounted) return;
      setState(() {
        _tracks = tracks.data;
        _state = UIState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = UIState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == UIState.loading) {
      return SizedBox.shrink();
    }
    final trackGroups = _tracks.isEmpty
        ? []
        : List<List<Track>>.generate((_tracks.length / 4).ceil(), (index) => _tracks.skip(index * 4).take(4).toList());
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withAlpha((0.05 * 255).toInt()),
        ),
        child: Column(
          spacing: 10,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Don't miss your recent tracks",
                      style: TextStyle(
                        fontFamily: "SpotifyMixUI",
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "See All",
                      style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),

            CarouselSlider(
              options: CarouselOptions(height: 270, viewportFraction: 0.93, padEnds: false),
              items: trackGroups.map((group) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      margin: EdgeInsets.only(left: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(group.length, (index) {
                          final track = group[index] as Track;
                          return InkWell(
                            onTap: () {},
                            onLongPress: () {
                              Fluttertoast.showToast(
                                msg: "Added to your library",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );
                              SpotifyService.getSpotifyArtist(track.artistId);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: track.images.first,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.name,
                                          style: TextStyle(
                                            fontFamily: "SpotifyMixUI",
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          track.artistName ?? track.artistType.name,
                                          style: TextStyle(fontFamily: "SpotifyMixUI"),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
