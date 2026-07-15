import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/books_repository.dart';
import 'package:mobile/data/repositories/catalog_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

class _AuthorLine {
  final String authorId;
  final String line;

  const _AuthorLine({required this.authorId, required this.line});
}

class _GenreChip {
  final String genreId;
  final String name;

  const _GenreChip({required this.genreId, required this.name});
}

class BookDetailCatalogSection extends StatefulWidget {
  final String bookId;

  const BookDetailCatalogSection({super.key, required this.bookId});

  @override
  State<BookDetailCatalogSection> createState() =>
      _BookDetailCatalogSectionState();
}

class _BookDetailCatalogSectionState extends State<BookDetailCatalogSection> {
  final _booksRepo = BeBlogBooksRepository();
  final _catalogRepo = BeBlogCatalogRepository();
  final _usersRepo = BeBlogUsersRepository();

  bool _loading = true;
  bool _canManage = SessionCache.isAdmin;
  List<_AuthorLine> _authorLines = const [];
  List<_GenreChip> _genres = const [];
  List<AuthorDto> _allAuthors = const [];
  List<GenreDto> _allGenres = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _resolveAdmin();
  }

  Future<void> _resolveAdmin() async {
    if (SessionCache.isAdmin) {
      if (!_canManage) setState(() => _canManage = true);
      return;
    }
    final me = await _usersRepo.me();
    if (!mounted) return;
    if (me.data?.isAdmin == true) setState(() => _canManage = true);
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _booksRepo.getAuthors(widget.bookId),
      _booksRepo.getGenres(widget.bookId),
      _catalogRepo.getAuthors(),
      _catalogRepo.getGenres(),
    ]);
    if (!mounted) return;

    final bookAuthors =
        (results[0] as BeBlogRepoResult<List<BookAuthorDto>>).data ?? const [];
    final bookGenres =
        (results[1] as BeBlogRepoResult<List<BookGenreDto>>).data ?? const [];
    final allAuthors =
        (results[2] as BeBlogRepoResult<List<AuthorDto>>).data ?? const [];
    final allGenres =
        (results[3] as BeBlogRepoResult<List<GenreDto>>).data ?? const [];

    final authorById = {for (final a in allAuthors) a.id: a};
    final genreById = {for (final g in allGenres) g.id: g};

    final authorLines = <_AuthorLine>[];
    for (final ba in bookAuthors) {
      final author = authorById[ba.authorId];
      if (author == null) continue;
      final role = ba.role?.trim();
      authorLines.add(
        _AuthorLine(
          authorId: ba.authorId,
          line: role != null && role.isNotEmpty
              ? '${author.name} ($role)'
              : author.name,
        ),
      );
    }

    final genreChips = <_GenreChip>[];
    for (final bg in bookGenres) {
      final genre = genreById[bg.genreId];
      if (genre != null) {
        genreChips.add(_GenreChip(genreId: bg.genreId, name: genre.name));
      }
    }

    setState(() {
      _loading = false;
      _authorLines = authorLines;
      _genres = genreChips;
      _allAuthors = allAuthors;
      _allGenres = allGenres;
    });
  }

  Future<void> _addAuthor() async {
    final attached = _authorLines.map((e) => e.authorId).toSet();
    final available = _allAuthors
        .where((a) => !attached.contains(a.id))
        .toList();
    if (available.isEmpty) return;

    final picked = await showModalBottomSheet<AuthorDto>(
      context: context,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Link author',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...available.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name, style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, a),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;

    final result = await _booksRepo.addAuthor(
      bookId: widget.bookId,
      authorId: picked.id,
    );
    if (!mounted) return;
    if (result.success) {
      await _load();
    }
  }

  Future<void> _removeAuthor(String authorId) async {
    final result = await _booksRepo.removeAuthor(
      bookId: widget.bookId,
      authorId: authorId,
    );
    if (!mounted) return;
    if (result.success) await _load();
  }

  Future<void> _addGenre() async {
    final attached = _genres.map((e) => e.genreId).toSet();
    final available = _allGenres
        .where((g) => !attached.contains(g.id))
        .toList();
    if (available.isEmpty) return;

    final picked = await showModalBottomSheet<GenreDto>(
      context: context,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Link genre',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...available.map(
              (g) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(g.name, style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, g),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;

    final result = await _booksRepo.addGenre(
      bookId: widget.bookId,
      genreId: picked.id,
    );
    if (!mounted) return;
    if (result.success) await _load();
  }

  Future<void> _removeGenre(String genreId) async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Remove genre?',
      message: 'This genre link will be removed from the book.',
      confirmLabel: 'Remove',
    );
    if (!ok) return;
    final result = await _booksRepo.removeGenre(
      bookId: widget.bookId,
      genreId: genreId,
    );
    if (!mounted) return;
    if (result.success) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_authorLines.isEmpty && _genres.isEmpty && !_canManage) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_authorLines.isNotEmpty || _canManage) ...[
            Row(
              children: [
                const Expanded(child: PostSectionLabel(text: 'Authors')),
                if (_canManage)
                  TextButton(
                    onPressed: _addAuthor,
                    child: Text(
                      'Add',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_authorLines.isEmpty && _canManage)
              Text(
                'No authors linked.',
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._authorLines.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.line,
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_canManage)
                        IconButton(
                          onPressed: () => _removeAuthor(entry.authorId),
                          icon: const Icon(Icons.close, size: 16),
                          color: AppColors.homeTextLight,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
          if (_genres.isNotEmpty || _canManage) ...[
            Row(
              children: [
                const Expanded(child: PostSectionLabel(text: 'Genres')),
                if (_canManage)
                  TextButton(
                    onPressed: _addGenre,
                    child: Text(
                      'Add',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_genres.isEmpty && _canManage)
              Text(
                'No genres linked.',
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genres.map((g) {
                  return InputChip(
                    label: Text(
                      g.name,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.coverTeal.withValues(
                      alpha: 0.25,
                    ),
                    onDeleted: _canManage
                        ? () => _removeGenre(g.genreId)
                        : null,
                    deleteIconColor: AppColors.primaryBrown,
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}
