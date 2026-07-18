import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/async_loading_view.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/posts/widgets/post_section_label.dart';
import 'package:mobile/features/profile/screens/user_profile_screen.dart';

/// Admin: `GET /api/users/search?q=...` (no global user list on backend).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _usersRepo = BeBlogUsersRepository();
  final _queryCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  List<UserPublicDto> _users = const [];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _users = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _usersRepo.searchUsers(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _users = result.data ?? const [];
      } else {
        _error = result.message ?? 'Could not search users.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const DetailSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editorial\nmembers',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.homeTextDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search readers via `GET /api/users/search`.',
                      style: GoogleFonts.inter(
                        color: AppColors.homeTextLight,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _queryCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Username or display name…',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.homeTextLight,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          color: AppColors.primaryBrown,
                          onPressed: _search,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AsyncLoadingView(
                      isLoading: _loading,
                      errorMessage: _error,
                      onRetry: _search,
                    ),
                    if (!_loading &&
                        _error == null &&
                        _queryCtrl.text.trim().isNotEmpty) ...[
                      PostSectionLabel(text: '${_users.length} readers'),
                      const SizedBox(height: 16),
                      if (_users.isEmpty)
                        Text(
                          'No users matched.',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextLight,
                            fontSize: 13,
                          ),
                        )
                      else
                        ..._users.map((u) {
                          final display = u.displayName;
                          return EditorialSurfaceCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => UserProfileScreen(
                                    userId: u.id,
                                    initialDisplayName: display,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  display,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '@${u.username}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.homeTextLight,
                                  ),
                                ),
                                if (u.bio != null &&
                                    u.bio!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    u.bio!.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.homeTextLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
