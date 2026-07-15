import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/models/engagement_dtos.dart';
import 'package:mobile/data/repositories/post_moderation_repository.dart';
import 'package:mobile/data/repositories/posts_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/screens/edit_post_screen.dart';
import 'package:mobile/features/posts/screens/post_image_viewer_screen.dart';
import 'package:mobile/features/posts/utils/post_image_urls.dart';
import 'package:mobile/features/posts/widgets/post_detail_body.dart';
import 'package:mobile/features/posts/widgets/post_network_image.dart';
import 'package:mobile/features/social/models/discussion_target.dart';
import 'package:mobile/features/social/widgets/discussion_comments_section.dart';
import 'package:mobile/features/social/widgets/engagement_like_bar.dart';
import 'package:mobile/features/saved/widgets/bookmark_button.dart';

/// Single post from `GET /api/posts/{id}` — editorial layout aligned with home.
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostDto? initialPost;

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postsRepo = BeBlogPostsRepository();
  final _moderationRepo = BeBlogPostModerationRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _authRepo = AuthRepository();

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isModerating = false;
  bool _isAdmin = SessionCache.isAdmin;
  String? _error;
  PostDto? _post;

  bool get _canDeletePost => _post?.canDelete == true || _isAdmin;
  bool get _canEditPost => _post?.canEdit == true || _isAdmin;
  bool get _canApprove => _post?.canApprove == true;

  static const double _heroHeight = 340;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPost;
    if (seed != null && seed.id == widget.postId) {
      _post = seed;
      _isLoading = false;
    }
    _loadPost();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    if (SessionCache.isAdmin) {
      if (!_isAdmin) setState(() => _isAdmin = true);
      return;
    }
    final token = await _authRepo.getToken();
    if (token == null || token.isEmpty) return;

    final me = await _usersRepo.me();
    if (!mounted) return;
    setState(() => _isAdmin = me.success && (me.data?.isAdmin ?? false));
  }

  Future<void> _loadPost() async {
    if (_post == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await _postsRepo.getOne(widget.postId);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success && result.data != null) {
        _post = result.data;
        _error = null;
      } else if (_post == null) {
        _error = result.message ?? 'Không tải được bài viết.';
      }
    });
  }

  Future<void> _confirmDelete() async {
    final post = _post;
    if (post == null) return;

    final confirmed = await showEditorialConfirmDialog(
      context,
      title: 'Xóa bài viết?',
      message: '“${post.title}” sẽ bị xóa cùng toàn bộ ảnh.',
      confirmLabel: 'Xóa',
      destructive: true,
    );

    if (confirmed != true || !mounted) return;
    await _deletePost();
  }

  Future<void> _openEdit() async {
    final post = _post;
    if (post == null) return;
    final updated = await Navigator.push<PostDto>(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(post: post)),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _post = updated);
    } else {
      // Có thể đã đổi gallery nhưng hủy ở bước cuối — tải lại cho chắc.
      _loadPost();
    }
  }

  Future<void> _approve() async {
    final post = _post;
    if (post == null || _isModerating) return;
    setState(() => _isModerating = true);
    final result = await _moderationRepo.approve(post.id);
    if (!mounted) return;
    setState(() {
      _isModerating = false;
      if (result.success && result.data != null) _post = result.data;
    });
    _moderationSnack(
      result.success,
      result.success
          ? 'Đã duyệt bài viết.'
          : (result.message ?? 'Không thể duyệt bài.'),
    );
  }

  Future<void> _reject() async {
    final post = _post;
    if (post == null || _isModerating) return;

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.homeBackground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Từ chối bài viết?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lý do (tùy chọn) sẽ hiển thị cho tác giả.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối…',
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
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

    if (reason == null || !mounted) return;
    setState(() => _isModerating = true);
    final result = await _moderationRepo.reject(post.id, reason: reason);
    if (!mounted) return;
    setState(() {
      _isModerating = false;
      if (result.success && result.data != null) _post = result.data;
    });
    _moderationSnack(
      result.success,
      result.success
          ? 'Đã từ chối bài viết.'
          : (result.message ?? 'Không thể từ chối bài.'),
    );
  }

  void _moderationSnack(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deletePost() async {
    setState(() => _isDeleting = true);

    final result = await _postsRepo.delete(widget.postId);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa bài viết.', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'Không thể xóa bài viết.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _post?.hasTitleImage == true
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBrown),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFlatAppBar(useLightIcons: false),
            Expanded(
              child: AsyncLoadingView(
                isLoading: false,
                errorMessage: _error,
                onRetry: _loadPost,
              ),
            ),
          ],
        ),
      );
    }

    final post = _post;
    if (post == null) return const SizedBox.shrink();

    final hasHero = post.hasTitleImage;
    final imageUrls = postDetailImageUrls(post);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: hasHero,
          expandedHeight: hasHero ? _heroHeight : 0,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.homeBackground,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: _NavIconButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            icon: Icons.arrow_back_ios_new,
            light: hasHero,
          ),
          actions: [
            BookmarkButton(
              entityType: BookmarkEntityType.post,
              entityId: post.id,
              light: hasHero,
            ),
            if (_canEditPost)
              _NavIconButton(
                onPressed: (_isDeleting || _post == null) ? null : _openEdit,
                icon: Icons.edit_outlined,
                light: hasHero,
              ),
            if (_canDeletePost)
              _NavIconButton(
                onPressed: (_isDeleting || _post == null)
                    ? null
                    : _confirmDelete,
                icon: Icons.delete_outline,
                light: hasHero,
                iconColor: hasHero ? Colors.white : AppColors.error,
                child: _isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: hasHero ? Colors.white : AppColors.error,
                        ),
                      )
                    : null,
              ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: hasHero
              ? FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PostNetworkImage(
                        url: post.resolveTitleImageUrl(ApiConstants.baseUrl),
                        fallbackColor: AppColors.coverSand,
                        onTap: imageUrls.isEmpty
                            ? null
                            : () => PostImageViewerScreen.open(
                                context,
                                imageUrls: imageUrls,
                                initialIndex: 0,
                              ),
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                AppColors.homeBackground,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, hasHero ? 8 : 0, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (post.isPending || post.isRejected) ...[
                  _PostStatusBanner(post: post),
                  const SizedBox(height: 16),
                ],
                if (_canApprove) ...[
                  _ModerationBar(
                    busy: _isModerating,
                    onApprove: _approve,
                    onReject: _reject,
                  ),
                  const SizedBox(height: 16),
                ],
                PostDetailBody(post: post),
                const SizedBox(height: 8),
                EngagementLikeBar(
                  target: DiscussionTarget.post,
                  targetId: post.id,
                ),
                const SizedBox(height: 16),
                DiscussionCommentsSection(
                  target: DiscussionTarget.post,
                  targetId: post.id,
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }

  Widget _buildFlatAppBar({required bool useLightIcons}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _NavIconButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            icon: Icons.arrow_back_ios_new,
            light: useLightIcons,
          ),
          const Spacer(),
          if (_canDeletePost)
            _NavIconButton(
              onPressed: (_isDeleting || _post == null) ? null : _confirmDelete,
              icon: Icons.delete_outline,
              light: useLightIcons,
              iconColor: useLightIcons ? Colors.white : AppColors.error,
            ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool light;
  final Color? iconColor;
  final Widget? child;

  const _NavIconButton({
    required this.onPressed,
    required this.icon,
    this.light = false,
    this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? (light ? Colors.white : AppColors.homeTextDark);

    return IconButton(
      onPressed: onPressed,
      icon: child ?? Icon(icon, size: 20, color: color),
    );
  }
}

/// Banner trạng thái duyệt (pending / rejected) hiển thị cho chủ bài & admin.
class _PostStatusBanner extends StatelessWidget {
  final PostDto post;

  const _PostStatusBanner({required this.post});

  @override
  Widget build(BuildContext context) {
    final rejected = post.isRejected;
    final color = rejected ? AppColors.error : AppColors.primaryBrown;
    final title = rejected ? 'Bài viết bị từ chối' : 'Đang chờ duyệt';
    final reason = post.rejectionReason?.trim();
    final message = rejected
        ? (reason != null && reason.isNotEmpty
              ? 'Lý do: $reason'
              : 'Bài viết chưa được công khai. Hãy chỉnh sửa và lưu lại để gửi duyệt.')
        : 'Bài viết sẽ hiển thị công khai sau khi được biên tập viên duyệt.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rejected ? Icons.cancel_outlined : Icons.hourglass_empty,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: AppColors.homeTextDark.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng nút duyệt/từ chối cho biên tập viên (canApprove).
class _ModerationBar extends StatelessWidget {
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ModerationBar({
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBrown,
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: Text(
              'Duyệt',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: Text(
              'Từ chối',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
