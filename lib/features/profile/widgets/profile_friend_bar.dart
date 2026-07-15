import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/repositories/friends_repository.dart';

/// Friend actions from [UserProfileViewDto.relationStatus].
class ProfileFriendBar extends StatefulWidget {
  final String userId;
  final String? relationStatus;
  final VoidCallback onChanged;

  const ProfileFriendBar({
    super.key,
    required this.userId,
    required this.relationStatus,
    required this.onChanged,
  });

  @override
  State<ProfileFriendBar> createState() => _ProfileFriendBarState();
}

class _ProfileFriendBarState extends State<ProfileFriendBar> {
  final _friendsRepo = BeBlogFriendsRepository();

  bool _busy = false;
  String? _pendingRequestId;

  @override
  void initState() {
    super.initState();
    _resolvePendingRequestId();
  }

  @override
  void didUpdateWidget(covariant ProfileFriendBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relationStatus != widget.relationStatus ||
        oldWidget.userId != widget.userId) {
      _pendingRequestId = null;
      _resolvePendingRequestId();
    }
  }

  Future<void> _resolvePendingRequestId() async {
    final status = widget.relationStatus;
    if (status != 'PENDING_INCOMING' && status != 'PENDING_OUTGOING') return;

    if (status == 'PENDING_INCOMING') {
      final result = await _friendsRepo.incomingRequests();
      if (!mounted || !result.success) return;
      final match = result.data?.where((f) => f.requesterId == widget.userId);
      setState(
        () => _pendingRequestId = match?.isNotEmpty == true
            ? match!.first.id
            : null,
      );
      return;
    }

    final result = await _friendsRepo.outgoingRequests();
    if (!mounted || !result.success) return;
    final match = result.data?.where((f) => f.addresseeId == widget.userId);
    setState(
      () => _pendingRequestId = match?.isNotEmpty == true
          ? match!.first.id
          : null,
    );
  }

  Future<void> _run(Future<BeBlogRepoResult<dynamic>> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Thao tác thất bại.')),
      );
    }
  }

  Future<void> _confirmUnfriend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hủy kết bạn?', style: GoogleFonts.playfairDisplay()),
        content: Text(
          'Bạn sẽ không còn thấy feed riêng tư của người này.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _friendsRepo.unfriend(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.relationStatus;
    if (status == null || status == 'SELF') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _busy
          ? const SizedBox(
              height: 36,
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
          : switch (status) {
              'NONE' => _primaryButton('Gửi lời mời kết bạn', () {
                _run(() => _friendsRepo.sendRequest(widget.userId));
              }),
              'PENDING_OUTGOING' => _secondaryButton('Hủy lời mời', () {
                final id = _pendingRequestId;
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tải mã lời mời…')),
                  );
                  _resolvePendingRequestId();
                  return;
                }
                _run(() => _friendsRepo.cancelRequest(id));
              }),
              'PENDING_INCOMING' => Row(
                children: [
                  Expanded(
                    child: _primaryButton('Chấp nhận', () {
                      final id = _pendingRequestId;
                      if (id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang tải mã lời mời…')),
                        );
                        _resolvePendingRequestId();
                        return;
                      }
                      _run(() => _friendsRepo.acceptRequest(id));
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _secondaryButton('Từ chối', () {
                      final id = _pendingRequestId;
                      if (id == null) {
                        _resolvePendingRequestId();
                        return;
                      }
                      _run(() => _friendsRepo.rejectRequest(id));
                    }),
                  ),
                ],
              ),
              'FRIENDS' => _secondaryButton('Hủy kết bạn', _confirmUnfriend),
              _ => const SizedBox.shrink(),
            },
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          side: const BorderSide(color: AppColors.primaryBrown),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
