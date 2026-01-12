import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecentTracksSection extends ConsumerStatefulWidget {
  final List<Track> tracks;
  final Function(Track) onTrackTap;

  const RecentTracksSection({super.key, required this.tracks, required this.onTrackTap});

  @override
  ConsumerState<RecentTracksSection> createState() => _RecentTracksSectionState();
}

class _RecentTracksSectionState extends ConsumerState<RecentTracksSection> {
  @override
  Widget build(BuildContext context) {
    final randomTracks = widget.tracks.take(20).toList();
    final trackGroups = randomTracks.isEmpty
        ? []
        : List<List<Track>>.generate(
            (randomTracks.length / 4).ceil(),
            (index) => randomTracks.skip(index * 4).take(4).toList(),
          );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withAlpha((0.15 * 255).toInt()),
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
                        fontWeight: FontWeight.bold,
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
              options: CarouselOptions(height: 270, enableInfiniteScroll: true, viewportFraction: 0.93, padEnds: false),
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
                            onTap: () => widget.onTrackTap(track),
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
                                    child: Image.network(track.images.first, width: 50, height: 50, fit: BoxFit.cover),
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
                                          track.artistType.name,
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
