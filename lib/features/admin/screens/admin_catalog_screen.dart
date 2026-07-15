import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/utils/slugify.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/catalog_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Admin CRUD for tags, genres, authors (`/api/tags`, `/api/genres`, `/api/authors`).
class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen>
    with SingleTickerProviderStateMixin {
  final _catalogRepo = BeBlogCatalogRepository();
  late final TabController _tabs;

  bool _loading = true;
  String? _error;
  List<TagDto> _tags = const [];
  List<GenreDto> _genres = const [];
  List<AuthorDto> _authors = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      _catalogRepo.getTags(),
      _catalogRepo.getGenres(),
      _catalogRepo.getAuthors(),
    ]);
    if (!mounted) return;
    final tags = results[0];
    final genres = results[1];
    final authors = results[2];
    if (!tags.success && !genres.success && !authors.success) {
      setState(() {
        _loading = false;
        _error = tags.message ?? 'Could not load catalog.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _tags = (tags as BeBlogRepoResult<List<TagDto>>).data ?? const [];
      _genres = (genres as BeBlogRepoResult<List<GenreDto>>).data ?? const [];
      _authors =
          (authors as BeBlogRepoResult<List<AuthorDto>>).data ?? const [];
    });
  }

  Future<void> _openTagEditor({TagDto? existing}) async {
    final saved = await _showCatalogEditor<TagDto>(
      title: existing == null ? 'New tag' : 'Edit tag',
      initialName: existing?.name ?? '',
      initialColor: existing?.color ?? '#8D5A47',
      onSave: (name, extra) async {
        final slug = existing?.slug ?? slugify(name);
        final draft = TagDto(
          id: existing?.id ?? '',
          name: name,
          slug: slug,
          color: extra,
        );
        if (existing == null) {
          return _catalogRepo.createTag(draft);
        }
        return _catalogRepo.updateTag(existing.id, draft);
      },
      extraLabel: 'Color (hex)',
    );
    if (saved == true) await _load();
  }

  Future<void> _openGenreEditor({GenreDto? existing}) async {
    final saved = await _showCatalogEditor<GenreDto>(
      title: existing == null ? 'New genre' : 'Edit genre',
      initialName: existing?.name ?? '',
      onSave: (name, _) async {
        final slug = existing?.slug ?? slugify(name);
        final draft = GenreDto(id: existing?.id ?? '', name: name, slug: slug);
        if (existing == null) {
          return _catalogRepo.createGenre(draft);
        }
        return _catalogRepo.updateGenre(existing.id, draft);
      },
    );
    if (saved == true) await _load();
  }

  Future<void> _openAuthorEditor({AuthorDto? existing}) async {
    final saved = await _showCatalogEditor<AuthorDto>(
      title: existing == null ? 'New author' : 'Edit author',
      initialName: existing?.name ?? '',
      initialBio: existing?.bio,
      onSave: (name, bio) async {
        final slug = existing?.slug ?? slugify(name);
        final draft = AuthorDto(
          id: existing?.id ?? '',
          name: name,
          slug: slug,
          bio: bio?.trim().isEmpty == true ? null : bio?.trim(),
        );
        if (existing == null) {
          return _catalogRepo.createAuthor(draft);
        }
        return _catalogRepo.updateAuthor(existing.id, draft);
      },
      bioField: true,
    );
    if (saved == true) await _load();
  }

  Future<bool?> _showCatalogEditor<T>({
    required String title,
    required String initialName,
    String? initialColor,
    String? initialBio,
    String extraLabel = '',
    bool bioField = false,
    required Future<dynamic> Function(String name, String? extra) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final extraCtrl = TextEditingController(
      text: initialColor ?? initialBio ?? '',
    );
    var saving = false;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.homeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  EditorialFormField(label: 'Name', controller: nameCtrl),
                  if (bioField) ...[
                    const SizedBox(height: 16),
                    EditorialFormField(
                      label: 'Bio',
                      controller: extraCtrl,
                      maxLines: 3,
                    ),
                  ] else if (extraLabel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    EditorialFormField(
                      label: extraLabel,
                      controller: extraCtrl,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            setModalState(() => saving = true);
                            final result = await onSave(
                              name,
                              extraCtrl.text.trim().isEmpty
                                  ? null
                                  : extraCtrl.text.trim(),
                            );
                            if (!context.mounted) return;
                            if (result.success) {
                              Navigator.pop(context, true);
                            } else {
                              setModalState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.message ?? 'Save failed.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      saving ? 'Saving…' : 'Save',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTag(TagDto tag) async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Delete tag?',
      message: '“${tag.name}” will be removed from the catalog.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final result = await _catalogRepo.deleteTag(tag.id);
    if (!mounted) return;
    if (result.success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Delete failed.')),
      );
    }
  }

  Future<void> _deleteGenre(GenreDto genre) async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Delete genre?',
      message: '“${genre.name}” will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final result = await _catalogRepo.deleteGenre(genre.id);
    if (!mounted) return;
    if (result.success) await _load();
  }

  Future<void> _deleteAuthor(AuthorDto author) async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Delete author?',
      message: '“${author.name}” will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final result = await _catalogRepo.deleteAuthor(author.id);
    if (!mounted) return;
    if (result.success) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const DetailAppBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catalog',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabs,
                    labelColor: AppColors.primaryBrown,
                    unselectedLabelColor: AppColors.homeTextLight,
                    indicatorColor: AppColors.primaryBrown,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    tabs: const [
                      Tab(text: 'TAGS'),
                      Tab(text: 'GENRES'),
                      Tab(text: 'AUTHORS'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBrown,
                      ),
                    )
                  : _error != null
                  ? AsyncLoadingView(
                      isLoading: false,
                      errorMessage: _error,
                      onRetry: _load,
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _CatalogList<TagDto>(
                          items: _tags,
                          label: (t) => t.name,
                          onAdd: () => _openTagEditor(),
                          onEdit: (t) => _openTagEditor(existing: t),
                          onDelete: _deleteTag,
                        ),
                        _CatalogList<GenreDto>(
                          items: _genres,
                          label: (g) => g.name,
                          onAdd: () => _openGenreEditor(),
                          onEdit: (g) => _openGenreEditor(existing: g),
                          onDelete: _deleteGenre,
                        ),
                        _CatalogList<AuthorDto>(
                          items: _authors,
                          label: (a) => a.name,
                          subtitle: (a) => a.bio,
                          onAdd: () => _openAuthorEditor(),
                          onEdit: (a) => _openAuthorEditor(existing: a),
                          onDelete: _deleteAuthor,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) label;
  final String? Function(T)? subtitle;
  final VoidCallback onAdd;
  final void Function(T) onEdit;
  final void Function(T) onDelete;

  const _CatalogList({
    required this.items,
    required this.label,
    this.subtitle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add,
              size: 16,
              color: AppColors.primaryBrown,
            ),
            label: Text(
              'Add new',
              style: GoogleFonts.inter(
                color: AppColors.primaryBrown,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        PostSectionLabel(text: '${items.length} entries'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'No entries yet.',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 13,
            ),
          )
        else
          ...items.map((item) {
            final sub = subtitle?.call(item);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: ListTile(
                title: Text(
                  label(item),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: sub != null && sub.isNotEmpty
                    ? Text(
                        sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.homeTextLight,
                        ),
                      )
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit(item);
                    if (v == 'delete') onDelete(item);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
