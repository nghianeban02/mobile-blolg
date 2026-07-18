import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';

/// App bar nội dung dùng chung (back, logo, actions).
class _DetailAppBarContent extends StatelessWidget {
  final String? title;

  const _DetailAppBarContent({this.title});

  void _openOwnProfile(BuildContext context) {
    final profile = SessionCache.profile;
    if (profile == null) return;
    openUserProfile(context, userId: profile.id, displayName: profile.username);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.homeTextDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: title != null && title!.isNotEmpty
                ? Text(
                    title!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.6,
                      color: AppColors.homeTextDark,
                    ),
                  )
                : Image.asset(
                    'assets/images/app_logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: EditorialHeaderChip(
            icon: Icons.add,
            backgroundColor: AppColors.primaryBrown.withValues(alpha: 0.12),
            iconColor: AppColors.primaryBrown,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const CreateBookReviewScreen(),
                ),
              );
            },
          ),
        ),
        if (SessionCache.profile != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: EditorialHeaderChip(
              icon: Icons.person_outline,
              onPressed: () => _openOwnProfile(context),
            ),
          )
        else
          const SizedBox(width: 12),
      ],
    );
  }
}

/// Thanh app bar thường — dùng trong [Column], [SliverToBoxAdapter], v.v.
class DetailAppBar extends StatelessWidget {
  final String? title;

  const DetailAppBar({super.key, this.title});

  static const double toolbarHeight = 60;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: toolbarHeight,
      child: _DetailAppBarContent(title: title),
    );
  }
}

/// [SliverAppBar] — chỉ đặt trực tiếp trong [CustomScrollView.slivers].
class DetailSliverAppBar extends StatelessWidget {
  final String? title;

  const DetailSliverAppBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      toolbarHeight: DetailAppBar.toolbarHeight,
      expandedHeight: DetailAppBar.toolbarHeight,
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        bottom: false,
        child: _DetailAppBarContent(title: title),
      ),
    );
  }
}
