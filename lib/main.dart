import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/images/app_image_cache.dart';
import 'package:mobile/core/services/push_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap in-memory decoded images to reduce jank on long feeds.
  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20;

  CacheManager.logLevel = CacheManagerLogLevel.warning;
  AppImageCache.manager;

  // Resolve Inter + Playfair once at startup for smoother first scroll.
  await GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
    GoogleFonts.playfairDisplay(),
  ]);

  // FCM push — không chặn khởi động; tự tắt khi Firebase chưa cấu hình.
  unawaited(PushNotificationsService.instance.initialize());

  runApp(const MobileApp());
}
