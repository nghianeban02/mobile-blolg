import 'package:flutter/material.dart';
import 'package:mobile/features/profile/screens/user_profile_screen.dart';

Future<void> openUserProfile(
  BuildContext context, {
  required String userId,
  String? displayName,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          UserProfileScreen(userId: userId, initialDisplayName: displayName),
    ),
  ).then((_) {});
}
