import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/catalog_repository.dart';
import 'package:mobile/data/repositories/reviews_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

class ReviewTagsSection extends StatefulWidget {
  final String reviewId;
  final String? reviewUserId;

  const ReviewTagsSection({
    super.key,
    required this.reviewId,
    this.reviewUserId,
  });

  @override
  State<ReviewTagsSection> createState() => _ReviewTagsSectionState();
}

class _ReviewTagsSectionState extends State<ReviewTagsSection> {
  final _reviewsRepo = BeBlogReviewsRepository();
  final _catalogRepo = BeBlogCatalogRepository();
  final _usersRepo = BeBlogUsersRepository();

  List<TagDto> _tags = const [];
  List<ReviewTagDto> _reviewTags = const [];
  List<TagDto> _allTags = const [];
  bool _loading = true;
  bool _canEdit = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _resolveCanEdit();
  }

  Future<void> _resolveCanEdit() async {
    if (SessionCache.isAdmin) {
      setState(() => _canEdit = true);
      return;
    }
    final me = await _usersRepo.me();
    if (!mounted) return;
    final userId = me.data?.id;
    final owner = widget.reviewUserId;
    setState(() {
      _canEdit =
          me.data?.isAdmin == true ||
          (userId != null && owner != null && userId == owner);
    });
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _reviewsRepo.getTags(widget.reviewId),
      _catalogRepo.getTags(),
    ]);
    if (!mounted) return;

    final reviewTags =
        (results[0] as BeBlogRepoResult<List<ReviewTagDto>>).data ??
        const <ReviewTagDto>[];
    final allTags =
        (results[1] as BeBlogRepoResult<List<TagDto>>).data ?? const <TagDto>[];
    final byId = {for (final t in allTags) t.id: t};

    final resolved = <TagDto>[];
    for (final rt in reviewTags) {
      final tag = byId[rt.tagId];
      if (tag != null) resolved.add(tag);
    }

    setState(() {
      _loading = false;
      _reviewTags = reviewTags;
      _allTags = allTags;
      _tags = resolved;
    });
  }

  Future<void> _openAddTag() async {
    final attached = _reviewTags.map((e) => e.tagId).toSet();
    final available = _allTags.where((t) => !attached.contains(t.id)).toList();
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All tags are already attached.',
            style: GoogleFonts.inter(),
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<TagDto>(
      context: context,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Add tag',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...available.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.name, style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, t),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;

    setState(() => _busy = true);
    final result = await _reviewsRepo.addTag(
      reviewId: widget.reviewId,
      tagId: picked.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not add tag.')),
      );
    }
  }

  Future<void> _removeTag(TagDto tag) async {
    setState(() => _busy = true);
    final result = await _reviewsRepo.removeTag(
      reviewId: widget.reviewId,
      tagId: tag.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_tags.isEmpty && !_canEdit) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: PostSectionLabel(text: 'Tags')),
              if (_canEdit)
                TextButton(
                  onPressed: _busy ? null : _openAddTag,
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
          const SizedBox(height: 12),
          if (_tags.isEmpty)
            Text(
              'No tags yet.',
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
              children: _tags.map((t) {
                return InputChip(
                  label: Text(
                    t.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  backgroundColor: AppColors.coverSand.withValues(alpha: 0.5),
                  shape: const StadiumBorder(),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                  onDeleted: _canEdit && !_busy ? () => _removeTag(t) : null,
                  deleteIconColor: AppColors.primaryBrown,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
