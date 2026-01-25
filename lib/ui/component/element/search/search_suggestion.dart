import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/ui/component/dialog/delete_search_log.dart';

class SearchSuggestion extends StatelessWidget {
  final ScrollController scrollController;
  final List<Search> trending;
  final List<Search> histories;
  final bool isQueryEmpty;
  final VoidCallback onBackgroundTap;
  final ValueChanged<String> onSearchTap;
  final ValueChanged<String> onFillTap;

  const SearchSuggestion({
    super.key,
    required this.scrollController,
    required this.trending,
    required this.histories,
    required this.isQueryEmpty,
    required this.onBackgroundTap,
    required this.onSearchTap,
    required this.onFillTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBackgroundTap,
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (isQueryEmpty && trending.isNotEmpty) ...[
            _buildHeader("Trending searches:"),
            SliverList.builder(
              itemCount: trending.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -1.5),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha((0.2 * 255).toInt())),
                  clipBehavior: Clip.hardEdge,
                  child: const Icon(Icons.trending_up_rounded),
                ),
                title: Text(trending[index].keyword, maxLines: 1),
                trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
                onTap: () => onSearchTap(trending[index].keyword),
              ),
            ),
          ],

          if (histories.isNotEmpty) ...[
            _buildHeader("Histories:"),
            SliverList.builder(
              itemCount: histories.length,
              itemBuilder: (context, index) {
                final item = histories[index];
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -1.5),
                  leading: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.history_rounded)),
                  title: Text(item.keyword, maxLines: 1),
                  trailing: IconButton(
                    icon: const Icon(Icons.subdirectory_arrow_left_rounded),
                    onPressed: () => onFillTap(item.keyword),
                  ),
                  onTap: () => onSearchTap(item.keyword),
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (c) => Dialog(
                      elevation: 4,
                      child: DeleteSearchLogDialog(search: item),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: const TextStyle(fontFamily: "SpotifyMixUI",fontWeight: FontWeight.w800, fontSize: 18)),
      ),
    );
  }
}
