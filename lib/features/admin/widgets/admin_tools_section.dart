import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/admin/screens/admin_catalog_screen.dart';
import 'package:mobile/features/admin/screens/admin_posts_screen.dart';
import 'package:mobile/features/admin/screens/admin_users_screen.dart';
import 'package:mobile/features/settings/widgets/settings_item_row.dart';
import 'package:mobile/features/settings/widgets/settings_section_title.dart';

/// Admin shortcuts — parity web settings admin links.
class AdminToolsSection extends StatelessWidget {
  final UserProfileDto? profile;

  const AdminToolsSection({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile?.isAdmin != true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(text: context.t('common.admin').toUpperCase()),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: context.t('settings.adminPosts'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AdminPostsScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: context.t('settings.adminCatalog'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AdminCatalogScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: context.t('settings.adminUsers'),
          actionText: context.t('common.viewDetails'),
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
