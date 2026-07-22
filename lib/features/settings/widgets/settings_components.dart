import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/app_locale.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/messaging/chat_sounds.dart';
import 'package:mobile/core/preferences/display_preferences.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/notifications_repository.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/friends/screens/friends_screen.dart';
import 'package:mobile/features/settings/screens/change_password_screen.dart';
import 'package:mobile/features/settings/widgets/settings_checkbox_tile.dart';
import 'package:mobile/features/settings/widgets/settings_item_row.dart';
import 'package:mobile/features/settings/widgets/settings_section_title.dart';
import 'package:mobile/features/settings/widgets/settings_switch.dart';

// ----------------------------------------------------------------------
// HEADER
// ----------------------------------------------------------------------
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return EditorialPageHeader(
      title: context.t('settings.title'),
      subtitle: context.t('settings.subtitle'),
      padding: EdgeInsets.zero,
    );
  }
}

// ----------------------------------------------------------------------
// LANGUAGE — parity web LanguageSettings
// ----------------------------------------------------------------------
class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleController.instance;
    return ListenableBuilder(
      listenable: locale,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionTitle(
              text: context.t('language.title').toUpperCase(),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('language.subtitle'),
              style: GoogleFonts.inter(
                color: AppColors.homeTextLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in AppLocale.values)
                  _LocaleChip(
                    locale: option,
                    selected: locale.locale == option,
                    label: context.t('language.${option.code}'),
                    onTap: () => locale.setLocale(option),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LocaleChip extends StatelessWidget {
  final AppLocale locale;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _LocaleChip({
    required this.locale,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryBrown.withValues(alpha: 0.12)
          : AppColors.hoverWash,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primaryBrown : AppColors.borderStrong,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 148,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locale.code.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.homeTextLight,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// CHAT SOUNDS — parity web ChatSoundSettings
// ----------------------------------------------------------------------
class ChatSoundSettingsSection extends StatefulWidget {
  const ChatSoundSettingsSection({super.key});

  @override
  State<ChatSoundSettingsSection> createState() =>
      _ChatSoundSettingsSectionState();
}

class _ChatSoundSettingsSectionState extends State<ChatSoundSettingsSection> {
  final _prefs = ChatSoundPreferences.instance;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_refresh);
    _prefs.load();
  }

  @override
  void dispose() {
    _prefs.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle(String key) async {
    if (key == 'messages') {
      await _prefs.set(messages: !_prefs.messages);
    } else {
      await _prefs.set(calls: !_prefs.calls);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t('push.saved'))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(text: context.t('push.soundsTitle').toUpperCase()),
        const SizedBox(height: 8),
        Text(
          context.t('push.soundsSubtitle'),
          style: GoogleFonts.inter(
            color: AppColors.homeTextLight,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.hoverWash,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('push.soundMessages'),
                        style: GoogleFonts.inter(
                          color: AppColors.homeTextDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SettingsSwitch(
                      value: _prefs.messages,
                      onChanged: (_) => _toggle('messages'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('push.soundCalls'),
                        style: GoogleFonts.inter(
                          color: AppColors.homeTextDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SettingsSwitch(
                      value: _prefs.calls,
                      onChanged: (_) => _toggle('calls'),
                    ),
                  ],
                ),
              ),
            ],
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
                label: context.t('settings.editProfile'),
                onPressed: isLoading ? null : onEdit,
              ),
              EditorialPillButton(
                label: context.t('settings.viewProfile'),
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
// QUICK LINKS — parity web settings.quickLinks
// ----------------------------------------------------------------------
class QuickLinksSection extends StatelessWidget {
  const QuickLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          text: context.t('settings.quickLinks').toUpperCase(),
        ),
        const SizedBox(height: 20),
        SettingsItemRow(
          title: context.t('common.friends'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
          ),
        ),
        const SizedBox(height: 16),
        SettingsItemRow(
          title: context.t('common.notifications'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(height: 16),
        SettingsItemRow(
          title: context.t('settings.readingList'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () => context.go(AppRoutes.library),
        ),
        const SizedBox(height: 16),
        SettingsItemRow(
          title: context.t('nav.library'),
          actionText: context.t('common.viewDetails'),
          onActionTap: () => context.go(AppRoutes.library),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// ACCOUNT SECURITY — parity web settings.account / password
// ----------------------------------------------------------------------
class AccountSecuritySection extends StatelessWidget {
  final UserProfileDto? profile;

  const AccountSecuritySection({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    final email = profile?.email?.trim().isNotEmpty == true
        ? profile!.email!.trim()
        : (profile?.username ?? '—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(text: context.t('settings.account').toUpperCase()),
        const SizedBox(height: 24),
        SettingsItemRow(title: context.t('auth.email'), subtitle: email),
        const SizedBox(height: 24),
        SettingsItemRow(
          title: context.t('settings.passwordTitle'),
          subtitle: context.t('settings.passwordSubtitle'),
          actionText: context.t('common.edit'),
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const ChangePasswordScreen(),
            ),
          ),
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
        const SnackBar(
          content: Text('Không lưu được tùy chọn thông báo. Thử lại.'),
        ),
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
                      onChanged: (v) =>
                          _apply(preferences.copyWith(messages: v)),
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
                      onChanged: (v) =>
                          _apply(preferences.copyWith(friends: v)),
                    ),
                    const SizedBox(height: 24),
                    SettingsCheckboxTile(
                      title: 'Bình luận & trả lời',
                      subtitle: 'Bình luận trên bài viết/review của bạn.',
                      isChecked: preferences.comments,
                      onChanged: (v) =>
                          _apply(preferences.copyWith(comments: v)),
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
        const SiteBrand(variant: SiteBrandVariant.header, showSlogan: true),
        const SizedBox(height: 12),
        const SizedBox(height: 32),
        EditorialPillButton(
          label: context.t('common.logout'),
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
