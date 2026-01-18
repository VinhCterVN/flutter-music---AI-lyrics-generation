import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/utils/debouncer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchDetailPage extends ConsumerStatefulWidget {
  final String? query;

  const SearchDetailPage({super.key, this.query});

  @override
  ConsumerState<SearchDetailPage> createState() => _SearchDetailPageState();
}

class _SearchDetailPageState extends ConsumerState<SearchDetailPage> {
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 1000));
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  List<Search> _histories = [], _trending = [], _filtered = [];
  bool _showDivider = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _scrollController.addListener(_onScroll);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      if (widget.query != null && widget.query!.isNotEmpty) {
        _textController.text = widget.query!;
        _onSearchChanged(widget.query!);
      }
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadData() async {
    final histories = await ref.read(searchServiceProvider).getSearchHistory();
    final trending = await ref.read(searchServiceProvider).getTrendingSearch();
    if (!mounted) return;
    setState(() {
      _trending = trending;
      _histories = histories;
      _filtered = histories;
    });
    debugPrint('Loaded ${histories.length} histories and ${trending.length} trending searches.');
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_showDivider) {
      setState(() => _showDivider = true);
    } else if (_scrollController.offset <= 0 && _showDivider) {
      setState(() => _showDivider = false);
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) return;
    ref.read(searchServiceProvider).insertSearch(query);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _histories;
      } else {
        _filtered = _histories.where((element) => element.keyword.startsWith(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      Fluttertoast.showToast(msg: 'Microphone permission granted.');
    } else if (status.isDenied) {
      Fluttertoast.showToast(msg: 'Microphone permission is required for this feature.');
    } else if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(msg: 'Please enable microphone permission from settings.');
      await openAppSettings();
    } else if (status.isRestricted) {
      Fluttertoast.showToast(msg: 'Microphone permission is restricted and cannot be requested.');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        leading: IconButton(onPressed: context.pop, icon: const Icon(Icons.arrow_back_rounded, weight: 0.5)),
        title: SizedBox(
          height: 38,
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: GoogleFonts.roboto(),
            onChanged: _onSearchChanged,
            onSubmitted: _onSearch,
            decoration: InputDecoration(
              hintText: 'Find your tracks, artists…',
              hintStyle: GoogleFonts.roboto(color: Theme.of(context).colorScheme.onSurface.withAlpha(153)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          const SizedBox(width: 4),
          IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest),
            ),
            onPressed: () {},
            icon: const HugeIcon(icon: HugeIconsStrokeRounded.chart03),
          ),
          IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest),
            ),
            onPressed: () => _requestMicrophonePermission(),
            icon: const HugeIcon(icon: HugeIconsStrokeRounded.aiMic),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showDivider ? 1 : 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceDim,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (_textController.text.isEmpty && _trending.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text("Trending searches: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              SliverList.builder(
                itemCount: _trending.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.trending_up_rounded),
                    title: Text(
                      _trending[index].keyword,
                      style: const TextStyle(fontSize: 15, letterSpacing: 0),
                      maxLines: 1,
                    ),
                    trailing: const Icon(Icons.search_rounded),
                    onTap: () => Fluttertoast.showToast(msg: 'Search for "Trending Search Item ${index + 1}"'),
                  );
                },
              ),
            ],
            SliverList.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history_rounded),
                  title: Text(
                    _filtered[index].keyword,
                    style: const TextStyle(fontSize: 15, letterSpacing: 0),
                    maxLines: 1,
                  ),
                  trailing: const Icon(Icons.subdirectory_arrow_left_rounded),
                  onTap: () => Fluttertoast.showToast(msg: 'Search for "${_filtered[index].keyword}"'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
