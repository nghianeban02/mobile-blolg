import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/catalog_repository.dart';

/// Multi-select authors & genres when composing a new library book.
class CreateBookCatalogPicker extends StatefulWidget {
  final Set<String> selectedAuthorIds;
  final Set<String> selectedGenreIds;
  final ValueChanged<Set<String>> onAuthorsChanged;
  final ValueChanged<Set<String>> onGenresChanged;
  final bool enabled;

  const CreateBookCatalogPicker({
    super.key,
    required this.selectedAuthorIds,
    required this.selectedGenreIds,
    required this.onAuthorsChanged,
    required this.onGenresChanged,
    this.enabled = true,
  });

  @override
  State<CreateBookCatalogPicker> createState() =>
      _CreateBookCatalogPickerState();
}

class _CreateBookCatalogPickerState extends State<CreateBookCatalogPicker> {
  final _catalogRepo = BeBlogCatalogRepository();

  bool _loading = true;
  List<AuthorDto> _authors = const [];
  List<GenreDto> _genres = const [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final results = await Future.wait([
      _catalogRepo.getAuthors(),
      _catalogRepo.getGenres(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _authors =
          (results[0] as BeBlogRepoResult<List<AuthorDto>>).data ?? const [];
      _genres =
          (results[1] as BeBlogRepoResult<List<GenreDto>>).data ?? const [];
    });
  }

  Future<void> _pickAuthor() async {
    if (!widget.enabled) return;
    final available = _authors
        .where((a) => !widget.selectedAuthorIds.contains(a.id))
        .toList();
    if (available.isEmpty) {
      _showSnack('Đã chọn hết tác giả trong catalog.');
      return;
    }
    final picked = await _showPickerSheet<AuthorDto>(
      title: 'Chọn tác giả',
      items: available,
      label: (a) => a.name,
    );
    if (picked == null) return;
    widget.onAuthorsChanged({...widget.selectedAuthorIds, picked.id});
  }

  Future<void> _pickGenre() async {
    if (!widget.enabled) return;
    final available = _genres
        .where((g) => !widget.selectedGenreIds.contains(g.id))
        .toList();
    if (available.isEmpty) {
      _showSnack('Đã chọn hết thể loại trong catalog.');
      return;
    }
    final picked = await _showPickerSheet<GenreDto>(
      title: 'Chọn thể loại',
      items: available,
      label: (g) => g.name,
    );
    if (picked == null) return;
    widget.onGenresChanged({...widget.selectedGenreIds, picked.id});
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.inter())),
    );
  }

  Future<T?> _showPickerSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.homeTextDark,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label(item), style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AuthorDto> get _selectedAuthors =>
      _authors.where((a) => widget.selectedAuthorIds.contains(a.id)).toList();

  List<GenreDto> get _selectedGenres =>
      _genres.where((g) => widget.selectedGenreIds.contains(g.id)).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(color: AppColors.primaryBrown),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CatalogRow(
          label: 'Authors',
          onAdd: _pickAuthor,
          enabled: widget.enabled,
          emptyHint: _authors.isEmpty
              ? 'Chưa có tác giả. Thêm trong Settings → Catalog.'
              : 'Tùy chọn — gắn tác giả với sách.',
          chips: _selectedAuthors
              .map(
                (a) => _PickerChip(
                  label: a.name,
                  onDeleted: widget.enabled
                      ? () {
                          final next = Set<String>.from(
                            widget.selectedAuthorIds,
                          )..remove(a.id);
                          widget.onAuthorsChanged(next);
                        }
                      : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _CatalogRow(
          label: 'Genres',
          onAdd: _pickGenre,
          enabled: widget.enabled,
          emptyHint: _genres.isEmpty
              ? 'Chưa có thể loại. Thêm trong Settings → Catalog.'
              : 'Tùy chọn — phân loại sách.',
          chips: _selectedGenres
              .map(
                (g) => _PickerChip(
                  label: g.name,
                  sandTone: false,
                  onDeleted: widget.enabled
                      ? () {
                          final next = Set<String>.from(widget.selectedGenreIds)
                            ..remove(g.id);
                          widget.onGenresChanged(next);
                        }
                      : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;
  final bool enabled;
  final String emptyHint;
  final List<Widget> chips;

  const _CatalogRow({
    required this.label,
    required this.onAdd,
    required this.enabled,
    required this.emptyHint,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.homeTextDark.withValues(alpha: 0.8),
                ),
              ),
            ),
            TextButton(
              onPressed: enabled ? onAdd : null,
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
        const SizedBox(height: 8),
        if (chips.isEmpty)
          Text(
            emptyHint,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.homeTextLight,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool sandTone;

  const _PickerChip({
    required this.label,
    this.onDeleted,
    this.sandTone = true,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.homeTextDark,
        ),
      ),
      backgroundColor: sandTone
          ? AppColors.coverSand.withValues(alpha: 0.5)
          : AppColors.coverTeal.withValues(alpha: 0.25),
      side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      deleteIconColor: AppColors.primaryBrown,
      onDeleted: onDeleted,
    );
  }
}
