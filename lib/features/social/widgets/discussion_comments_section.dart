import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/comments_repository.dart';
import 'package:mobile/data/repositories/post_comments_repository.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/social/models/discussion_target.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/features/social/widgets/comment_composer_bar.dart';
import 'package:mobile/features/social/widgets/comment_tile.dart';

/// Bình luận + trả lời cho post hoặc review sách.
class DiscussionCommentsSection extends StatefulWidget {
  final DiscussionTarget target;
  final String targetId;

  const DiscussionCommentsSection({
    super.key,
    required this.target,
    required this.targetId,
  });

  @override
  State<DiscussionCommentsSection> createState() =>
      _DiscussionCommentsSectionState();
}

class _DiscussionCommentsSectionState extends State<DiscussionCommentsSection> {
  final _reviewCommentsRepo = BeBlogCommentsRepository();
  final _postCommentsRepo = BeBlogPostCommentsRepository();
  final _authRepo = AuthRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _rootInputController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  List<CommentDto> _threads = const [];
  String? _currentUserId = SessionCache.profile?.id;
  String? _editingCommentId;
  String? _replyingToId;
  String? _replyingToLabel;
  final Set<String> _expandedThreadIds = {};
  final _editController = TextEditingController();
  final _replyController = TextEditingController();

  bool get _isReview => widget.target == DiscussionTarget.review;

  static const _emptyHint = 'Chưa có bình luận nào.';

  @override
  void initState() {
    super.initState();
    _load();
    _resolveUser();
  }

  @override
  void dispose() {
    _rootInputController.dispose();
    _editController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _resolveUser() async {
    if (_currentUserId != null) return;
    final me = await _usersRepo.me();
    if (!mounted) return;
    if (me.success && me.data != null) {
      setState(() => _currentUserId = me.data!.id);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = _isReview
        ? await _reviewCommentsRepo.listByReview(widget.targetId)
        : await _postCommentsRepo.listByPost(widget.targetId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _threads = result.data ?? const [];
    });
  }

  bool _canManage(CommentDto c) =>
      c.canEdit || (_currentUserId != null && c.userId == _currentUserId);

  Future<bool> _ensureLoggedIn() async {
    final token = await _authRepo.getToken();
    if (token != null && token.isNotEmpty) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đăng nhập để bình luận.', style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }

  Future<void> _submitRoot() async {
    final text = _rootInputController.text.trim();
    if (text.isEmpty) return;
    if (!await _ensureLoggedIn()) return;

    setState(() => _submitting = true);
    final result = _isReview
        ? await _reviewCommentsRepo.create(
            reviewId: widget.targetId,
            content: text,
          )
        : await _postCommentsRepo.create(
            postId: widget.targetId,
            content: text,
          );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      _rootInputController.clear();
      await _load();
    } else {
      _showError(result.message ?? 'Không gửi được bình luận.');
    }
  }

  String? _rootIdForCommentId(String commentId) {
    for (final root in _threads) {
      if (root.id == commentId) return root.id;
      if (root.replies.any((r) => r.id == commentId)) return root.id;
    }
    return null;
  }

  String? _rootIdForComment(CommentDto target) =>
      _rootIdForCommentId(target.id);

  void _expandThread(String rootId) {
    setState(() => _expandedThreadIds.add(rootId));
  }

  void _collapseThread(String rootId) {
    setState(() => _expandedThreadIds.remove(rootId));
  }

  void _startReply(CommentDto target) {
    final label = target.username?.trim().isNotEmpty == true
        ? target.username!
        : 'Reader';
    final rootId = _rootIdForComment(target);
    setState(() {
      _replyingToId = target.id;
      _replyingToLabel = label;
      _replyController.clear();
      _editingCommentId = null;
      if (rootId != null) _expandedThreadIds.add(rootId);
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToLabel = null;
      _replyController.clear();
    });
  }

  Future<void> _submitReply() async {
    final parentId = _replyingToId;
    final text = _replyController.text.trim();
    if (parentId == null || text.isEmpty) return;
    if (!await _ensureLoggedIn()) return;

    setState(() => _submitting = true);
    final result = _isReview
        ? await _reviewCommentsRepo.reply(
            reviewId: widget.targetId,
            commentId: parentId,
            content: text,
          )
        : await _postCommentsRepo.reply(
            postId: widget.targetId,
            commentId: parentId,
            content: text,
          );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      final expandRoot = _rootIdForCommentId(parentId);
      _cancelReply();
      await _load();
      if (mounted && expandRoot != null) {
        setState(() => _expandedThreadIds.add(expandRoot));
      }
    } else {
      _showError(result.message ?? 'Không gửi được trả lời.');
    }
  }

  void _startEdit(CommentDto c) {
    setState(() {
      _editingCommentId = c.id;
      _editController.text = c.content;
      _cancelReply();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(CommentDto c) async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final result = _isReview
        ? await _reviewCommentsRepo.update(
            reviewId: widget.targetId,
            commentId: c.id,
            content: text,
          )
        : await _postCommentsRepo.update(
            postId: widget.targetId,
            commentId: c.id,
            content: text,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      _cancelEdit();
      await _load();
    } else {
      _showError(result.message ?? 'Không cập nhật được.');
    }
  }

  Future<void> _deleteComment(CommentDto c) async {
    final ok = await showEditorialConfirmDialog(
      context,
      title: 'Xóa bình luận?',
      message: 'Nội dung này sẽ bị gỡ khỏi thảo luận.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    final result = _isReview
        ? await _reviewCommentsRepo.delete(
            reviewId: widget.targetId,
            commentId: c.id,
          )
        : await _postCommentsRepo.delete(
            postId: widget.targetId,
            commentId: c.id,
          );
    if (!mounted) return;
    if (result.success) {
      if (_replyingToId == c.id) _cancelReply();
      await _load();
    } else {
      _showError(result.message ?? 'Không xóa được.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = countCommentsThreaded(_threads);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSectionLabel(text: 'BÌNH LUẬN ($total)'),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
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
          else if (_threads.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _emptyHint,
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._threads.map(
              (root) => _CommentThread(
                key: ValueKey(root.id),
                root: root,
                repliesExpanded: _expandedThreadIds.contains(root.id),
                onExpandReplies: () => _expandThread(root.id),
                onCollapseReplies: () => _collapseThread(root.id),
                editingCommentId: _editingCommentId,
                replyingToId: _replyingToId,
                editController: _editController,
                replyController: _replyController,
                replyingToLabel: _replyingToLabel,
                submitting: _submitting,
                canManage: _canManage,
                onReply: _startReply,
                onCancelReply: _cancelReply,
                onSubmitReply: _submitReply,
                onEdit: _startEdit,
                onCancelEdit: _cancelEdit,
                onSaveEdit: _saveEdit,
                onDelete: _deleteComment,
              ),
            ),
          const SizedBox(height: 16),
          CommentComposerBar(
            controller: _rootInputController,
            hint: 'Viết bình luận…',
            submitLabel: 'Đăng',
            submitting: _submitting,
            onSubmit: _submitRoot,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _CommentThread extends StatelessWidget {
  final CommentDto root;
  final bool repliesExpanded;
  final VoidCallback onExpandReplies;
  final VoidCallback onCollapseReplies;
  final String? editingCommentId;
  final String? replyingToId;
  final TextEditingController editController;
  final TextEditingController replyController;
  final String? replyingToLabel;
  final bool submitting;
  final bool Function(CommentDto) canManage;
  final void Function(CommentDto) onReply;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmitReply;
  final void Function(CommentDto) onEdit;
  final VoidCallback onCancelEdit;
  final void Function(CommentDto) onSaveEdit;
  final void Function(CommentDto) onDelete;

  const _CommentThread({
    super.key,
    required this.root,
    required this.repliesExpanded,
    required this.onExpandReplies,
    required this.onCollapseReplies,
    required this.editingCommentId,
    required this.replyingToId,
    required this.editController,
    required this.replyController,
    required this.replyingToLabel,
    required this.submitting,
    required this.canManage,
    required this.onReply,
    required this.onCancelReply,
    required this.onSubmitReply,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final replyCount = root.replies.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommentTile(
            comment: root,
            replyCount: replyCount > 0 && !repliesExpanded ? replyCount : null,
            editing: editingCommentId == root.id,
            showReplyComposer: replyingToId == root.id,
            editController: editController,
            replyController: replyController,
            replyingToLabel: replyingToLabel,
            submitting: submitting,
            canManage: canManage(root),
            onReply: () => onReply(root),
            onCancelReply: onCancelReply,
            onSubmitReply: onSubmitReply,
            onEdit: () => onEdit(root),
            onCancelEdit: onCancelEdit,
            onSaveEdit: () => onSaveEdit(root),
            onDelete: () => onDelete(root),
          ),
          if (replyCount > 0 && !repliesExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: _ThreadRepliesToggle(
                label: 'Xem thêm $replyCount trả lời',
                onTap: onExpandReplies,
              ),
            ),
          if (repliesExpanded) ...[
            ...root.replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 10),
                child: CommentTile(
                  comment: reply,
                  isReply: true,
                  editing: editingCommentId == reply.id,
                  showReplyComposer: replyingToId == reply.id,
                  editController: editController,
                  replyController: replyController,
                  replyingToLabel: replyingToLabel,
                  submitting: submitting,
                  canManage: canManage(reply),
                  onReply: () => onReply(reply),
                  onCancelReply: onCancelReply,
                  onSubmitReply: onSubmitReply,
                  onEdit: () => onEdit(reply),
                  onCancelEdit: onCancelEdit,
                  onSaveEdit: () => onSaveEdit(reply),
                  onDelete: () => onDelete(reply),
                ),
              ),
            ),
            if (replyCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: _ThreadRepliesToggle(
                  label: 'Thu gọn',
                  onTap: onCollapseReplies,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ThreadRepliesToggle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ThreadRepliesToggle({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: EditorialLinkButton(
        label: label,
        onPressed: onTap,
        emphasized: true,
      ),
    );
  }
}
