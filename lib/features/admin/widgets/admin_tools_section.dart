import 'package:flutter/material.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/admin/screens/admin_catalog_screen.dart';
import 'package:mobile/features/admin/screens/admin_posts_screen.dart';
import 'package:mobile/features/admin/screens/admin_users_screen.dart';
import 'package:mobile/features/settings/widgets/settings_item_row.dart';
import 'package:mobile/features/settings/widgets/settings_section_title.dart';

/// Admin-only shortcuts for unused be-blog management APIs.
class AdminToolsSection extends StatelessWidget {
  final UserProfileDto? profile;

  const AdminToolsSection({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile?.isAdmin != true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'EDITORIAL ADMIN'),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'Post moderation',
          subtitle: 'Review, approve or reject pending posts',
          actionText: 'Review',
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AdminPostsScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'Catalog',
          subtitle: 'Tags, genres, authors — create, edit, delete',
          actionText: 'Manage',
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AdminCatalogScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'Members',
          subtitle: 'All registered readers and critics',
          actionText: 'View',
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AdminUsersScreen()),
            );
          },
        ),
      ],
    );
  }
}
