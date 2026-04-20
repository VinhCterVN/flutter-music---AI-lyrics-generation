import 'package:flutter/material.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/search/track_top_search.dart';
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

  void _onSearchChanged() {
    _debouncer.call(() {
      if (!mounted) return;
      final query = _searchController.text;
      ref.read(trackSearchQueryProvider.notifier).state = query;
    });
  }

  @override
  void dispose() {
    _debouncer.stop();
    _searchController.dispose();
    super.dispose();
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
    final queryState = ref.watch(trackSearchQueryProvider);
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
          builder: (context, controller) => SearchBar(
            controller: controller,
            onTap: () => controller.openView(),
            hintText: "Search tracks...",
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            textStyle: WidgetStatePropertyAll(GoogleFonts.poppins()),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedAiSearch),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          viewBackgroundColor: Theme.of(context).colorScheme.surfaceDim,
          viewHintText: "What are you looking for?",
          viewTrailing: [
            if (queryState.isNotEmpty)
              IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedEraser01),
                onPressed: () {
                  _searchController.clear();
                  ref.read(trackSearchQueryProvider.notifier).state = "";
                },
              ),
          ],
          viewOnClose: () => FocusManager.instance.primaryFocus?.unfocus(),
          suggestionsBuilder: (context, controller) {
            _onSearchChanged();
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
                              child: TrackTopSearch(track: tracks.first, onTap: () => _playTrack(ref, tracks, 0)),
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
