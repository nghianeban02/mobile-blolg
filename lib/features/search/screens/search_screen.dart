import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/search/archive_search_index.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/repositories/search_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/search/widgets/search_archive_results.dart';
import 'package:mobile/features/search/widgets/search_components.dart';

/// Search tab: live filter over posts, reviews, and books from the API.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _searchRepository = BeBlogSearchRepository();
  Timer? _debounce;

  bool _indexLoading = true;
  String? _indexError;
  List<PostDto> _posts = const [];
  List<ReviewDto> _reviews = const [];
  List<BookDto> _books = const [];
  List<ArchiveSearchHit> _hits = const [];
  String _query = '';
  ArchiveSearchFilter _filter = ArchiveSearchFilter.all;
  SearchCountsDto _counts = const SearchCountsDto();
  bool _serverSearching = false;

  @override
  void initState() {
    super.initState();
    _loadIndex();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadIndex({bool forceRefresh = false}) async {
    setState(() {
      _indexLoading = true;
      _indexError = null;
    });
    try {
      final data = await ArchiveSearchIndex.load(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _indexLoading = false;
        _posts = data.posts;
        _reviews = data.reviews;
        _books = data.books;
        _hits = ArchiveSearchIndex.search(
          _query,
          posts: _posts,
          reviews: _reviews,
          books: _books,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _indexLoading = false;
        _indexError = e.toString();
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      final q = _queryController.text;
      setState(() {
        _query = q;
      });
      _runServerSearch();
    });
  }

  Future<void> _runServerSearch() async {
    final query = _query.trim();
    if (query.isEmpty) {
      setState(() => _hits = const []);
      return;
    }
    setState(() => _serverSearching = true);
    final result = await _searchRepository.search(query, filter: _filter);
    if (!mounted) return;
    setState(() {
      _serverSearching = false;
      if (result.success && result.data != null) {
        _hits = result.data!.hits;
        _counts = result.data!.counts;
        _indexError = null;
      } else {
        // Offline/local fallback keeps search useful when the server is unreachable.
        _hits =
            ArchiveSearchIndex.search(
              query,
              posts: _posts,
              reviews: _reviews,
              books: _books,
            ).where((hit) {
              return switch (_filter) {
                ArchiveSearchFilter.all => true,
                ArchiveSearchFilter.posts =>
                  hit.type == ArchiveSearchHitType.post,
                ArchiveSearchFilter.reviews =>
                  hit.type == ArchiveSearchHitType.review,
                ArchiveSearchFilter.books =>
                  hit.type == ArchiveSearchHitType.book,
              };
            }).toList();
      }
    });
  }

  void _applyCollectionFilter(String keyword) {
    _queryController.text = keyword;
    setState(() {
      _query = keyword;
    });
    _runServerSearch();
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _query.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const MainAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  SearchHeader(controller: _queryController),
                  const SizedBox(height: 32),
                  if (!_indexLoading && _indexError == null) ...[
                    TrendingCollections(
                      onCollectionTap: _applyCollectionFilter,
                    ),
                    const SizedBox(height: 40),
                    const LibrariansNote(),
                    const SizedBox(height: 32),
                  ],
                  if (showResults) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<ArchiveSearchFilter>(
                        segments: [
                          ButtonSegment(
                            value: ArchiveSearchFilter.all,
                            label: Text('Tất cả (${_counts.all})'),
                          ),
                          ButtonSegment(
                            value: ArchiveSearchFilter.posts,
                            label: Text('Bài (${_counts.posts})'),
                          ),
                          ButtonSegment(
                            value: ArchiveSearchFilter.reviews,
                            label: Text('Review (${_counts.reviews})'),
                          ),
                          ButtonSegment(
                            value: ArchiveSearchFilter.books,
                            label: Text('Sách (${_counts.books})'),
                          ),
                        ],
                        selected: {_filter},
                        showSelectedIcon: false,
                        onSelectionChanged: (selected) {
                          setState(() => _filter = selected.first);
                          _runServerSearch();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const PostSectionLabel(text: 'Search results'),
                    const SizedBox(height: 16),
                    SearchArchiveResults(
                      hits: _hits,
                      isLoading: _serverSearching,
                      error: _indexError,
                      onRetry: () => _loadIndex(forceRefresh: true),
                    ),
                  ] else if (!_indexLoading && _indexError == null) ...[
                    Text(
                      '${_posts.length} posts · ${_reviews.length} reviews · ${_books.length} books indexed',
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextLight,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
