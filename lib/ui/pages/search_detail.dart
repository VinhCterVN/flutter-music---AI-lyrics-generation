import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/component/element/search/search_result_detail.dart';
import 'package:flutter_ai_music/ui/component/element/search/search_suggestion.dart';
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
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  List<Search> _histories = [];
  List<Search> _trending = [];
  List<Search> _filteredHistories = [];
  SearchResult? _searchResult;

  bool _showDivider = false;
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _textController = SearchController();
    _focusNode = FocusNode()..addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      if (widget.query?.isNotEmpty == true) {
        _textController.text = widget.query!;
        _performSearch(widget.query!);
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final searchService = ref.read(searchServiceProvider);
    final [histories, trending] = await Future.wait([
      searchService.getSearchHistory(),
      searchService.getTrendingSearch(),
    ]);

    if (!mounted) return;
    setState(() {
      _histories = histories;
      _filteredHistories = _histories;
      _trending = trending;
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _showResults = false);
    }
  }

  void _onScroll() {
    if (_focusNode.hasFocus) SystemChannels.textInput.invokeMethod('TextInput.hide');

    final shouldShow = _scrollController.offset > 0;
    if (shouldShow != _showDivider) {
      setState(() => _showDivider = shouldShow);
    }
  }

  void _onQueryChanged(String query) => setState(() {
    if (query.isEmpty) {
      _filteredHistories = _histories;
    } else {
      _filteredHistories = _histories.where((e) => e.keyword.toLowerCase().startsWith(query.toLowerCase())).toList();
    }
  });

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _showResults = false;
      _searchResult = null;
    });

    final result = await ref.read(searchServiceProvider).search(query);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _searchResult = result;
      _showResults = true;
    });
  }

  void _handleBack() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool showSuggestions = _focusNode.hasFocus || _searchResult == null || !_showResults;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceDim,
      appBar: _buildAppBar(theme),
      body: Stack(
        children: [
          if (_searchResult != null)
            Visibility(
              visible: !showSuggestions && !_isLoading,
              maintainState: true,
              child: SearchResultDetail(result: _searchResult),
            ),

          if (showSuggestions && !_isLoading)
            SearchSuggestion(
              scrollController: _scrollController,
              trending: _trending,
              histories: _filteredHistories,
              isQueryEmpty: _textController.text.isEmpty,
              onBackgroundTap: _focusNode.requestFocus,
              onSearchTap: (query) {
                _textController.text = query;
                _performSearch(query);
              },
              onFillTap: (query) {
                _textController.text = query;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
                _onQueryChanged(query);
              },
            ),

          if (_isLoading)
            Container(
              color: theme.colorScheme.surfaceDim,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      titleSpacing: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surfaceDim,
      leading: IconButton(onPressed: _handleBack, icon: const Icon(Icons.arrow_back_rounded, weight: 0.5)),
      title: SizedBox(
        height: 38,
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          style: GoogleFonts.roboto(),
          onChanged: _onQueryChanged,
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Find your tracks, artists…',
            hintStyle: GoogleFonts.roboto(color: theme.colorScheme.onSurface.withAlpha(153)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const HugeIcon(icon: HugeIconsStrokeRounded.chart03),
        ),
        IconButton(
          onPressed: () async {
            if (await Permission.microphone.request().isGranted) {
              Fluttertoast.showToast(msg: "Mic permission granted");
            }
          },
          icon: const HugeIcon(icon: HugeIconsStrokeRounded.aiMic),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showDivider ? 1 : 0,
          color: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
