import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/detail_app_bar.dart';
import 'package:mobile/core/widgets/editorial_form_field.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/users_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileDto profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usersRepo = BeBlogUsersRepository();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  bool _saving = false;
  String _feedVisibility = 'PUBLIC';

  static const _feedVisibilityOptions = [
    ('PUBLIC', 'Public'),
    ('FRIENDS_ONLY', 'Friends only'),
    ('PRIVATE', 'Private'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.profile.title ?? '';
    _bioController.text = widget.profile.bio ?? '';
    _feedVisibility = widget.profile.feedVisibility ?? 'PUBLIC';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _usersRepo.updateMe(
      title: _titleController.text.trim(),
      bio: _bioController.text.trim(),
      feedVisibility: _feedVisibility,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success && result.data != null) {
      SessionCache.setProfile(result.data!);
      Navigator.pop(context, result.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Không lưu được hồ sơ.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const DetailSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit profile',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    EditorialFormField(
                      label: 'Display title',
                      hint: 'Your name on the archive',
                      controller: _titleController,
                    ),
                    const SizedBox(height: 16),
                    EditorialFormField(
                      label: 'Bio',
                      hint: 'A short editorial bio',
                      controller: _bioController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FEED VISIBILITY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.homeTextDark.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_feedVisibility),
                      initialValue: _feedVisibility,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      items: _feedVisibilityOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.$1,
                              child: Text(e.$2, style: GoogleFonts.inter()),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _feedVisibility = v);
                              }
                            },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _saving ? 'Saving…' : 'Save profile',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
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
