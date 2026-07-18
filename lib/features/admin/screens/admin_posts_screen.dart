import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/core/utils/text_excerpt.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/post_moderation_repository.dart';
import 'package:mobile/features/posts/screens/post_detail_screen.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';

/// Hàng chờ duyệt bài — `GET /api/admin/posts/pending` (ADMIN).
class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final _repo = BeBlogPostModerationRepository();

  bool _loading = true;
  String? _error;
  List<PostDto> _pending = const [];
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.pending();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _pending = result.data ?? const [];
      } else {
        _error = result.message ?? 'Không tải được hàng chờ duyệt.';
      }
    });
  }

  Future<void> _approve(PostDto post) async {
    if (_busyIds.contains(post.id)) return;
    setState(() => _busyIds.add(post.id));
    final result = await _repo.approve(post.id);
    if (!mounted) return;
    setState(() => _busyIds.remove(post.id));
    if (result.success) {
      setState(
        () => _pending = _pending.where((p) => p.id != post.id).toList(),
      );
      _snack('Đã duyệt “${post.title}”.', AppColors.success);
    } else {
      _snack(result.message ?? 'Không thể duyệt bài.', AppColors.error);
    }
  }

  Future<void> _reject(PostDto post) async {
    if (_busyIds.contains(post.id)) return;
    final reason = await _askRejectReason(post.title);
    if (reason == null || !mounted) return; // hủy

    setState(() => _busyIds.add(post.id));
    final result = await _repo.reject(post.id, reason: reason);
    if (!mounted) return;
    setState(() => _busyIds.remove(post.id));
    if (result.success) {
      setState(
        () => _pending = _pending.where((p) => p.id != post.id).toList(),
      );
      _snack('Đã từ chối “${post.title}”.', AppColors.homeTextDark);
    } else {
      _snack(result.message ?? 'Không thể từ chối bài.', AppColors.error);
    }
  }

  Future<String?> _askRejectReason(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Từ chối bài viết?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“$title” sẽ bị từ chối. Lý do (tùy chọn) sẽ hiển thị cho tác giả.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Lý do từ chối…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.homeTextLight,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Từ chối',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPost(PostDto post) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(postId: post.id, initialPost: post),
      ),
    );
    if (mounted) unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryBrown,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const DetailSliverAppBar(title: 'Moderation'),
              SliverToBoxAdapter(child: _buildHeader()),
              if (_loading || _error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncLoadingView(
                    isLoading: _loading,
                    errorMessage: _error,
                    onRetry: _load,
                  ),
                )
              else if (_pending.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                  sliver: SliverList.separated(
                    itemCount: _pending.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final post = _pending[i];
                      return _PendingPostCard(
                        post: post,
                        busy: _busyIds.contains(post.id),
                        onApprove: () => _approve(post),
                        onReject: () => _reject(post),
                        onOpen: () => _openPost(post),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostSectionLabel(text: 'Editorial admin'),
          const SizedBox(height: 12),
          Text(
            'Pending\nposts',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loading
                ? 'Đang tải…'
                : '${_pending.length} bài đang chờ duyệt. Chạm để xem chi tiết.',
            style: GoogleFonts.inter(
              color: AppColors.homeTextLight,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.homeTextLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có bài nào chờ duyệt.',
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPostCard extends StatelessWidget {
  final PostDto post;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpen;

  const _PendingPostCard({
    required this.post,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            boxShadow: isDark ? null : editorialSoftShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const EditorialStatusChip(
                    label: 'Pending',
                    backgroundColor: AppColors.coverSand,
                  ),
                  const Spacer(),
                  if (post.createdAt != null)
                    Text(
                      formatCommentDateTime(post.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.homeTextLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title.isEmpty ? '(Không tiêu đề)' : post.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
              if (post.content.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  textExcerpt(post.content, maxLength: 140),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.homeTextLight,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Duyệt',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Từ chối',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
