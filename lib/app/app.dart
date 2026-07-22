import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/messaging/chat_sounds.dart';
import 'package:mobile/core/pomodoro/pomodoro_floating_timer.dart';
import 'package:mobile/core/preferences/display_preferences.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/services/push_notifications_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/messages/call/call_controller.dart';
import 'package:mobile/features/messages/call/call_overlay.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';

/// Root app: [AuthBloc] + [NotificationsBloc] toàn cục + GoRouter + theme + i18n.
class MobileApp extends StatefulWidget {
  const MobileApp({super.key});

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  final _display = DisplayPreferences.instance;
  final _locale = LocaleController.instance;
  late final AuthBloc _authBloc;
  late final NotificationsBloc _notificationsBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(const AuthAppStarted());
    _notificationsBloc = NotificationsBloc()..startPolling();
    _router = createAppRouter(_authBloc);
    _display.addListener(_refresh);
    _locale.addListener(_refresh);
    _display.load();
    _locale.load();
    unawaited(ChatSoundPreferences.instance.load());
    // Deep link từ notification cuộc gọi (Nhận / tap khi app tắt).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _consumePushLaunchLink(),
    );
  }

  void _consumePushLaunchLink() {
    final link = PushNotificationsService.pendingLaunchLink;
    if (link == null || link.isEmpty) return;
    PushNotificationsService.pendingLaunchLink = null;
    try {
      final uri = Uri.parse(
        link.startsWith('http') ? link : 'https://nooknh.com$link',
      );
      if (uri.path.startsWith('/messages') || uri.path == AppRoutes.messages) {
        final conversation = uri.queryParameters['conversation'];
        final answer = uri.queryParameters['answer'] == '1';
        final target = conversation == null || conversation.isEmpty
            ? AppRoutes.messages
            : '${AppRoutes.messages}?conversation=$conversation';
        _router.go(target);
        if (answer) {
          CallController.instance.requestAutoAnswer();
        }
      }
    } catch (_) {
      // ignore malformed push link
    }
  }

  @override
  void dispose() {
    _display.removeListener(_refresh);
    _locale.removeListener(_refresh);
    _router.dispose();
    _notificationsBloc.close();
    _authBloc.close();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Poll nhẹ khi có pending link từ notification (app vừa mở từ nền).
    final pending = PushNotificationsService.pendingLaunchLink;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _consumePushLaunchLink(),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _notificationsBloc),
      ],
      child: MaterialApp.router(
        title: AppConfig.appLabel,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildLightTheme(),
        darkTheme: AppTheme.buildDarkTheme(),
        themeMode: _display.themeMode,
        locale: _locale.materialLocale,
        supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(_display.textScale),
            ),
            child: BlocListener<AuthBloc, AuthState>(
              listenWhen: (prev, next) =>
                  prev.profile?.id != next.profile?.id ||
                  prev.status != next.status,
              listener: (context, state) {
                final userId = state.isAuthenticated ? state.profile?.id : null;
                CallController.instance.bind(userId);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child ?? const SizedBox.shrink(),
                  const PomodoroFloatingTimer(),
                  const CallOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
