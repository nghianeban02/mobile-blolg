import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/search/archive_search_index.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_filter_tabs.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/search_repository.dart';
import 'package:mobile/features/search/widgets/search_archive_results.dart';
import 'package:mobile/features/search/widgets/search_components.dart';

/// Search tab: live filter over posts, reviews, and books from the API.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

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
    final seed = widget.initialQuery?.trim() ?? '';
    if (seed.isNotEmpty) {
      _queryController.text = seed;
      _query = seed;
    }
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  SearchHeader(controller: _queryController),
                  const SizedBox(height: 24),
                  if (!_indexLoading && _indexError == null) ...[
                    TrendingCollections(
                      onCollectionTap: _applyCollectionFilter,
                    ),
                    const SizedBox(height: 32),
                    const LibrariansNote(),
                    const SizedBox(height: 24),
                  ],
                  if (showResults) ...[
                    EditorialFilterTabs(
                      padding: const EdgeInsets.only(bottom: 24),
                      tabs: [
                        EditorialFilterTab(
                          id: 'all',
                          label: context.t('search.tabAll'),
                          count: _counts.all,
                        ),
                        EditorialFilterTab(
                          id: 'posts',
                          label: context.t('search.tabPosts'),
                          count: _counts.posts,
                        ),
                        EditorialFilterTab(
                          id: 'reviews',
                          label: context.t('search.tabReviews'),
                          count: _counts.reviews,
                        ),
                        EditorialFilterTab(
                          id: 'books',
                          label: context.t('search.tabBooks'),
                          count: _counts.books,
                        ),
                      ],
                      activeId: switch (_filter) {
                        ArchiveSearchFilter.all => 'all',
                        ArchiveSearchFilter.posts => 'posts',
                        ArchiveSearchFilter.reviews => 'reviews',
                        ArchiveSearchFilter.books => 'books',
                      },
                      onChanged: (id) {
                        setState(() {
                          _filter = switch (id) {
                            'posts' => ArchiveSearchFilter.posts,
                            'reviews' => ArchiveSearchFilter.reviews,
                            'books' => ArchiveSearchFilter.books,
                            _ => ArchiveSearchFilter.all,
                          };
                        });
                        _runServerSearch();
                      },
                    ),
                    Text(
                      context.t('search.sectionContent'),
                      style: AppTypography.sectionEyebrow(context),
                    ),
                    const SizedBox(height: 16),
                    SearchArchiveResults(
                      hits: _hits,
                      isLoading: _serverSearching,
                      error: _indexError,
                      onRetry: () => _loadIndex(forceRefresh: true),
                    ),
                  ] else if (!_indexLoading && _indexError == null) ...[
                    Text(
                      context.t('search.stats', {
                        'posts': _posts.length,
                        'reviews': _reviews.length,
                        'books': _books.length,
                      }),
                      style: AppTypography.body(
                        context,
                        size: 12,
                        color: context.palette.muted,
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
