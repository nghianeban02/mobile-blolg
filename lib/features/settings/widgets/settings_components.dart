import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/preferences/display_preferences.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/notifications_repository.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/calendar/screens/calendar_screen.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/messages/screens/conversations_screen.dart';
import 'package:mobile/features/notes/screens/notes_screen.dart';
import 'package:mobile/features/reading_list/screens/create_book_screen.dart';
import 'package:mobile/features/saved/screens/saved_screen.dart';
import 'package:mobile/features/settings/screens/change_password_screen.dart';
import 'package:mobile/features/settings/widgets/settings_checkbox_tile.dart';
import 'package:mobile/features/settings/widgets/settings_item_row.dart';
import 'package:mobile/features/settings/widgets/settings_section_title.dart';

// ----------------------------------------------------------------------
// HEADER
// ----------------------------------------------------------------------
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditorialPageHeader(
      title: 'Cài đặt',
      subtitle: 'Tuỳ chỉnh trải nghiệm đọc và quản lý tài khoản Nook.',
      padding: EdgeInsets.zero,
    );
  }
}

// ----------------------------------------------------------------------
// PROFILE CARD
// ----------------------------------------------------------------------
class ProfileCard extends StatelessWidget {
  final UserProfileDto? profile;
  final VoidCallback? onEdit;
  final VoidCallback? onViewPublic;
  final bool isLoading;

  const ProfileCard({
    super.key,
    this.profile,
    this.onEdit,
    this.onViewPublic,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.title?.trim().isNotEmpty == true
        ? profile!.title!.trim()
        : (profile?.username ?? 'Reader');
    final bio = profile?.bio?.trim().isNotEmpty == true
        ? '"${profile!.bio!.trim()}"'
        : '"Your editorial voice lives here."';
    final email = profile?.email ?? profile?.username ?? '';

    return EditorialSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.coverSand,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBrown,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(color: AppColors.primaryBrown),
            )
          else ...[
            Text(
              displayName,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.homeTextDark,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.inter(
                  color: AppColors.homeTextLight,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              bio,
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              EditorialPillButton(
                label: 'Edit Profile',
                onPressed: isLoading ? null : onEdit,
              ),
              EditorialPillButton(
                label: 'View Public Page',
                outline: true,
                onPressed: isLoading ? null : onViewPublic,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// FRIENDS — `/api/friends`
// ----------------------------------------------------------------------
class FriendsSection extends StatelessWidget {
  const FriendsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'SOCIAL'),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'Editorial circle',
          subtitle: 'Friends, incoming and outgoing requests',
          actionText: 'Open',
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// PERSONAL TOOLS — web-blog parity routes
// ----------------------------------------------------------------------
class PersonalToolsSection extends StatelessWidget {
  const PersonalToolsSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SettingsSectionTitle(text: 'PERSONAL TOOLS'),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Tin nhắn',
        subtitle: 'Trò chuyện riêng, nhóm và gửi ảnh',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ConversationsScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Ghi chú',
        subtitle: 'Thư mục, nhãn, ghim, lưu trữ và thùng rác',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Lịch & Pomodoro',
        subtitle: 'Quản lý công việc và phiên tập trung',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const CalendarScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Đã lưu',
        subtitle: 'Bài viết và review để đọc sau',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SavedScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Thêm sách',
        subtitle: 'Tạo một mục catalog mà không cần viết review',
        actionText: 'Create',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const CreateBookScreen()),
        ),
      ),
    ],
  );
}

// ----------------------------------------------------------------------
// ACCOUNT SECURITY
// ----------------------------------------------------------------------
class AccountSecuritySection extends StatelessWidget {
  final UserProfileDto? profile;

  const AccountSecuritySection({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    final email = profile?.email?.trim().isNotEmpty == true
        ? profile!.email!.trim()
        : (profile?.username ?? 'Chưa cập nhật email');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'ACCOUNT SECURITY'),
        const SizedBox(height: 24),
        SettingsItemRow(title: 'Email Address', subtitle: email),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'Password',
          subtitle: 'Đổi mật khẩu đăng nhập của bạn',
          actionText: 'Update',
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// DEVELOPER — Spring be-blog API samples
// ----------------------------------------------------------------------
class DeveloperBeBlogSection extends StatelessWidget {
  const DeveloperBeBlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'DEVELOPER'),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: 'be-blog REST samples',
          subtitle: 'Posts, books, reviews, catalog, JWT demos',
          actionText: 'Open',
          onActionTap: () => context.push(AppRoutes.apiDemo),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// READING EXPERIENCE
// ----------------------------------------------------------------------
class ReadingExperienceSection extends StatefulWidget {
  const ReadingExperienceSection({super.key});

  @override
  State<ReadingExperienceSection> createState() =>
      _ReadingExperienceSectionState();
}

class _ReadingExperienceSectionState extends State<ReadingExperienceSection> {
  final _preferences = DisplayPreferences.instance;

  @override
  void initState() {
    super.initState();
    _preferences.addListener(_refresh);
  }

  @override
  void dispose() {
    _preferences.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  ButtonStyle get _segmentedPillStyle => ButtonStyle(
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    side: const WidgetStatePropertyAll(
      BorderSide(color: AppColors.borderStrong),
    ),
    textStyle: WidgetStatePropertyAll(
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'READING EXPERIENCE'),
        const SizedBox(height: 24),
        Text(
          'Theme',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_brightness_outlined),
            ),
          ],
          selected: {_preferences.themeMode},
          showSelectedIcon: false,
          style: _segmentedPillStyle,
          onSelectionChanged: (value) => _preferences.setThemeMode(value.first),
        ),
        const SizedBox(height: 32),
        Text(
          'Typography Scale',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<AppFontScale>(
          segments: const [
            ButtonSegment(value: AppFontScale.small, label: Text('Small')),
            ButtonSegment(value: AppFontScale.medium, label: Text('Medium')),
            ButtonSegment(value: AppFontScale.large, label: Text('Large')),
          ],
          selected: {_preferences.fontScale},
          showSelectedIcon: false,
          style: _segmentedPillStyle,
          onSelectionChanged: (value) => _preferences.setFontScale(value.first),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// NOTIFICATIONS
// ----------------------------------------------------------------------
/// Tùy chọn push theo loại — `GET/PUT /api/notifications/preferences`.
/// Áp dụng cho mọi thiết bị của tài khoản; server thực thi khi gửi FCM.
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  final _notificationsRepo = BeBlogNotificationsRepository();

  PushPreferencesDto? _preferences;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final result = await _notificationsRepo.pushPreferences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _preferences = result.data;
      _loadFailed = result.data == null;
    });
  }

  Future<void> _apply(PushPreferencesDto next) async {
    final previous = _preferences ?? PushPreferencesDto.defaults;
    setState(() => _preferences = next);
    final result = await _notificationsRepo.updatePushPreferences(next);
    if (!mounted) return;
    if (result.data == null) {
      // Hoàn tác khi lưu thất bại để UI luôn khớp server.
      setState(() => _preferences = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được tùy chọn thông báo. Thử lại.')),
      );
    } else {
      setState(() => _preferences = result.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences ?? PushPreferencesDto.defaults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'PUSH NOTIFICATIONS'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.hoverWash,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              : _loadFailed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Không tải được tùy chọn thông báo.',
                          style: GoogleFonts.inter(
                            color: AppColors.homeTextDark.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Thử lại')),
                      ],
                    )
                  : Column(
                      children: [
                        SettingsCheckboxTile(
                          title: 'Tin nhắn mới',
                          subtitle: 'Tin nhắn chat khi bạn không mở app.',
                          isChecked: preferences.messages,
                          onChanged: (v) => _apply(preferences.copyWith(messages: v)),
                        ),
                        const SizedBox(height: 24),
                        SettingsCheckboxTile(
                          title: 'Cuộc gọi & cuộc gọi nhỡ',
                          subtitle: 'Cuộc gọi đến và thông báo gọi nhỡ.',
                          isChecked: preferences.calls,
                          onChanged: (v) => _apply(preferences.copyWith(calls: v)),
                        ),
                        const SizedBox(height: 24),
                        SettingsCheckboxTile(
                          title: 'Lời mời kết bạn',
                          subtitle: 'Lời mời mới và khi được chấp nhận.',
                          isChecked: preferences.friends,
                          onChanged: (v) => _apply(preferences.copyWith(friends: v)),
                        ),
                        const SizedBox(height: 24),
                        SettingsCheckboxTile(
                          title: 'Bình luận & trả lời',
                          subtitle: 'Bình luận trên bài viết/review của bạn.',
                          isChecked: preferences.comments,
                          onChanged: (v) => _apply(preferences.copyWith(comments: v)),
                        ),
                        const SizedBox(height: 24),
                        SettingsCheckboxTile(
                          title: 'Lượt thích',
                          subtitle: 'Khi có người thích nội dung của bạn.',
                          isChecked: preferences.likes,
                          onChanged: (v) => _apply(preferences.copyWith(likes: v)),
                        ),
                        const SizedBox(height: 24),
                        SettingsCheckboxTile(
                          title: 'Cập nhật hệ thống',
                          subtitle: 'Duyệt bài và thông báo quản trị.',
                          isChecked: preferences.system,
                          onChanged: (v) => _apply(preferences.copyWith(system: v)),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// FOOTER
// ----------------------------------------------------------------------
class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SiteBrand(
          variant: SiteBrandVariant.header,
          showSlogan: true,
          showMark: true,
          markSize: 28,
        ),
        const SizedBox(height: 12),
        Text(
          'Nook Mobile · 1.1.0',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 32),
        EditorialPillButton(
          label: 'Đăng xuất',
          destructive: true,
          expanded: true,
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
        ),
      ],
    );
  }
}
