import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/preferences/display_preferences.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/auth/auth_repository.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/calendar/screens/calendar_screen.dart';
import 'package:mobile/features/messaging/screens/messages_screen.dart';
import 'package:mobile/features/notes/screens/notes_screen.dart';
import 'package:mobile/features/reading_list/screens/create_book_screen.dart';
import 'package:mobile/features/saved/screens/saved_screen.dart';
import 'package:mobile/features/settings/screens/change_password_screen.dart';
import 'package:mobile/features/settings/widgets/settings_checkbox_tile.dart';
import 'package:mobile/features/settings/widgets/settings_item_row.dart';
import 'package:mobile/features/settings/widgets/settings_section_title.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// HEADER
// ----------------------------------------------------------------------
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCES',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 48,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Refine your reading experience and\nmanage your editorial archive.',
          style: GoogleFonts.inter(
            color: AppColors.homeTextDark.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
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
            MaterialPageRoute(builder: (_) => const FriendsScreen()),
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
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Ghi chú',
        subtitle: 'Thư mục, nhãn, ghim, lưu trữ và thùng rác',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Lịch & Pomodoro',
        subtitle: 'Quản lý công việc và phiên tập trung',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Đã lưu',
        subtitle: 'Bài viết và review để đọc sau',
        actionText: 'Open',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedScreen()),
        ),
      ),
      const SizedBox(height: 20),
      SettingsItemRow(
        title: 'Thêm sách',
        subtitle: 'Tạo một mục catalog mà không cần viết review',
        actionText: 'Create',
        onActionTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateBookScreen()),
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
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
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
          onActionTap: () => Navigator.pushNamed(context, AppRoutes.apiDemo),
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
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({super.key});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  static const _digestKey = 'notification_weekly_digest';
  static const _alertsKey = 'notification_immediate_alerts';

  bool _isWeeklyDigestChecked = true;
  bool _isImmediateAlertsChecked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isWeeklyDigestChecked = preferences.getBool(_digestKey) ?? true;
      _isImmediateAlertsChecked = preferences.getBool(_alertsKey) ?? false;
    });
  }

  Future<void> _setDigest(bool value) async {
    setState(() => _isWeeklyDigestChecked = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_digestKey, value);
  }

  Future<void> _setAlerts(bool value) async {
    setState(() => _isImmediateAlertsChecked = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_alertsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(text: 'NOTIFICATIONS'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.hoverWash,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              SettingsCheckboxTile(
                title: 'Weekly Digest',
                subtitle:
                    'A curated collection of the week\'s most\nprofound essays, delivered every Sunday\nmorning.',
                isChecked: _isWeeklyDigestChecked,
                onChanged: _setDigest,
              ),
              const SizedBox(height: 32),
              SettingsCheckboxTile(
                title: 'Immediate Publication Alerts',
                subtitle:
                    'Real-time alerts when your followed critics\npublish new reviews.',
                isChecked: _isImmediateAlertsChecked,
                onChanged: _setAlerts,
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
        Text(
          'Editorial Intelligence',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.homeTextDark,
            fontSize: 22,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'V1.1.0 — NOOK MOBILE',
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Privacy Policy', style: _linkStyle()),
            const SizedBox(width: 20),
            Text('Terms of Service', style: _linkStyle()),
            const SizedBox(width: 20),
            Text('Copyright', style: _linkStyle()),
          ],
        ),
        const SizedBox(height: 40),
        EditorialPillButton(
          label: 'Log Out Account',
          destructive: true,
          expanded: true,
          onPressed: () async {
            final repository = AuthRepository();
            await repository.logout();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            }
          },
        ),
      ],
    );
  }

  TextStyle _linkStyle() {
    return GoogleFonts.inter(
      color: AppColors.homeTextDark.withValues(alpha: 0.8),
      fontSize: 11,
    );
  }
}
