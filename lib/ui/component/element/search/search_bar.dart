import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/track_tile.dart';
import 'package:flutter_ai_music/utils/debouncer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/models/track.dart';
import '../../../../utils/audio_helper.dart';

class MySearchBar extends ConsumerStatefulWidget {
  const MySearchBar({super.key});

  @override
  ConsumerState<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends ConsumerState<MySearchBar> {
  late final SearchController _searchController;
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() => ref.read(trackSearchQueryProvider.notifier).state = query);
  }

  Future<void> _playTrack(WidgetRef ref, List<Track> allTracks, int selectedIndex) async {
    try {
      AudioHelper.playTrackFromList(ref, allTracks: allTracks, selectedIndex: selectedIndex);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error playing track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
            bodyLarge: const TextStyle(fontFamily: "SpotifyMixUI", fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        child: SearchAnchor(
          searchController: _searchController,
          viewConstraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
          builder: (context, controller) {
            return SearchBar(
              controller: controller,
              onTap: () => controller.openView(),
              hintText: "Search tracks...",
              textStyle: WidgetStatePropertyAll(GoogleFonts.poppins()),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAiSearch),
            );
          },
          viewBackgroundColor: Theme.of(context).colorScheme.surfaceDim,
          viewHintText: "What are you looking for?",
          viewTrailing: [
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedTextClear),
              onPressed: () {
                _searchController.clear();
                ref.read(trackSearchQueryProvider.notifier).state = "";
              },
            ),
          ],
          suggestionsBuilder: (context, controller) {
            _onSearchChanged(controller.text);
            return [
              Consumer(
                builder: (context, ref, child) {
                  final searchResult = ref.watch(trackSearchProvider);
                  return SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                    child: searchResult.when(
                      data: (tracks) {
                        if (tracks.isEmpty) {
                          return Center(child: Text("No results found.", style: GoogleFonts.poppins()));
                        }

                        // if (searchQuery.isEmpty) {
                        //   return Center(
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       spacing: 4,
                        //       children: [
                        //         Lottie.asset("assets/animations/impress.json", repeat: false),
                        //         Text("Type something to search tracks", style: GoogleFonts.poppins(fontSize: 16)),
                        //       ],
                        //     ),
                        //   );
                        // }

                        return CustomScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(50),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            width: 100,
                                            height: 100,
                                            clipBehavior: Clip.hardEdge,
                                            child: CachedNetworkImage(imageUrl: tracks.first.images.first),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tracks.first.name,
                                            style: const TextStyle(
                                              fontFamily: "SpotifyMixUI",
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),

                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).colorScheme.tertiaryContainer,
                                          ),
                                          child: IconButton(
                                            onPressed: () => _playTrack(ref, tracks, 0),
                                            icon: HugeIcon(icon: HugeIcons.strokeRoundedPlay),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (tracks.length > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
                                  child: Text(
                                    "Tracks",
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => TrackTile(
                                  track: tracks[index + 1],
                                  onTap: () => _playTrack(ref, tracks, index + 1),
                                  onLongPress: () => Fluttertoast.showToast(msg: tracks[index + 1].name),
                                  currentTrackId: -1,
                                ),
                                childCount: tracks.length - 1,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text("Error: $error")),
                    ),
                  );
                },
              ),
            ];
          },
        ),
      ),
    );
  }
}
