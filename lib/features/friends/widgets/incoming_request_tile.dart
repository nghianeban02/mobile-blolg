import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/friends_repository.dart';
import 'package:mobile/features/friends/widgets/friend_user_tile.dart';

class IncomingRequestTile extends StatefulWidget {
  final FriendshipDto friendship;
  final VoidCallback onChanged;
  final void Function(UserPublicDto user) onOpenProfile;

  const IncomingRequestTile({
    super.key,
    required this.friendship,
    required this.onChanged,
    required this.onOpenProfile,
  });

  @override
  State<IncomingRequestTile> createState() => _IncomingRequestTileState();
}

class _IncomingRequestTileState extends State<IncomingRequestTile> {
  final _repo = BeBlogFriendsRepository();
  bool _busy = false;

  UserPublicDto? get _user => widget.friendship.requester;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _repo.acceptRequest(widget.friendship.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onChanged();
    } else {
      _snack(result.message ?? 'Không chấp nhận được.');
    }
  }

  Future<void> _reject() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _repo.rejectRequest(widget.friendship.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onChanged();
    } else {
      _snack(result.message ?? 'Không từ chối được.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FriendUserTile(
          user: user,
          onTap: () => widget.onOpenProfile(user),
          trailing: const EditorialStatusChip(
            label: 'Lời mời',
            backgroundColor: AppColors.coverTeal,
          ),
        ),
        EditorialSurfaceCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          child: _busy
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
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
              : Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _accept,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          'Chấp nhận',
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
                        onPressed: _reject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBrown,
                          side: const BorderSide(color: AppColors.primaryBrown),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
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
        ),
      ],
    );
  }
}
