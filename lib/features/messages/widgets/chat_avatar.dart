import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Avatar tròn cho chat — ảnh nếu có, không thì chữ cái đầu trên nền brown.
class ChatAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool online;

  const ChatAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 44,
    this.online = false,
  });

  String? get _resolvedUrl {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final avatar = ClipOval(
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _fallback(initial),
              placeholder: (_, _) => _fallback(initial),
            )
          : _fallback(initial),
    );
    if (!online) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(String initial) => Container(
        width: size,
        height: size,
        color: AppColors.primaryBrown.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.4,
          ),
        ),
      );
}
