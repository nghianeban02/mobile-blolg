import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/navigation/open_user_profile.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';

/// App bar chi tiết — back + wordmark Nook / title (giống DetailHeader web).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkForeground : AppColors.homeTextDark;

    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ink,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: title != null && title!.isNotEmpty
              ? Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                )
              : const Center(
                  child: SiteBrand(
                    variant: SiteBrandVariant.header,
                    showMark: true,
                    markSize: 24,
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: EditorialHeaderChip(
            icon: Icons.add_rounded,
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
            padding: const EdgeInsets.only(right: 8),
            child: EditorialHeaderChip(
              icon: Icons.person_outline_rounded,
              onPressed: () => _openOwnProfile(context),
            ),
          )
        else
          const SizedBox(width: 8),
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
