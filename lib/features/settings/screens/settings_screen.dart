import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/main_app_bar.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';
import 'package:mobile/features/settings/screens/edit_profile_screen.dart';
import 'package:mobile/features/admin/widgets/admin_tools_section.dart';
import 'package:mobile/features/profile/screens/user_profile_screen.dart';
import 'package:mobile/features/settings/widgets/settings_components.dart';

/// Settings tab: profile from `GET /api/users/me`, edit via `PUT /api/users/me`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final _usersRepo = BeBlogUsersRepository();

  bool _loading = true;
  UserProfileDto? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void refreshProfile() => _loadProfile(forceRefresh: true);

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final result = await _usersRepo.me(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = result.data;
    });
  }

  void _openPublicProfile() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: profile.id,
          initialDisplayName: profile.title?.trim().isNotEmpty == true
              ? profile.title!.trim()
              : profile.username,
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.push<UserProfileDto>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const MainAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const SettingsHeader(),
                  const SizedBox(height: 40),
                  ProfileCard(
                    profile: _profile,
                    isLoading: _loading,
                    onEdit: _openEdit,
                    onViewPublic: _openPublicProfile,
                  ),
                  const SizedBox(height: 40),
                  AdminToolsSection(profile: _profile),
                  if (_profile?.isAdmin == true) const SizedBox(height: 40),
                  const FriendsSection(),
                  const SizedBox(height: 40),
                  const PersonalToolsSection(),
                  const SizedBox(height: 40),
                  AccountSecuritySection(profile: _profile),
                  const SizedBox(height: 48),
                  const DeveloperBeBlogSection(),
                  const SizedBox(height: 48),
                  const ReadingExperienceSection(),
                  const SizedBox(height: 48),
                  const NotificationsSection(),
                  const SizedBox(height: 64),
                  const SettingsFooter(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
