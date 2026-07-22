import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/core/i18n/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime i18n — catalog flat JSON từ web-blog (`assets/i18n/{locale}.json`).
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const _storageKey = 'app_locale';

  AppLocale _locale = AppLocale.defaultLocale;
  Map<String, String> _messages = const {};
  bool _ready = false;

  AppLocale get locale => _locale;
  bool get ready => _ready;
  Locale get materialLocale => Locale(_locale.code);

  static const supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en'),
    Locale('ja'),
    Locale('de'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = AppLocale.tryParse(prefs.getString(_storageKey));
    final platform = PlatformDispatcher.instance.locale.languageCode;
    _locale = stored ?? AppLocale.detectFromPlatform(platform);
    await _loadMessages(_locale);
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(AppLocale next) async {
    if (_locale == next && _messages.isNotEmpty) return;
    _locale = next;
    await _loadMessages(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, next.code);
    notifyListeners();
  }

  /// Tra cứu key dạng `nav.home`, thay `{name}` bằng [params].
  String t(String key, [Map<String, Object?>? params]) {
    final raw = _messages[key] ?? key;
    if (params == null || params.isEmpty) return raw;
    return raw.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final name = match.group(1)!;
      final value = params[name];
      return value != null ? '$value' : match.group(0)!;
    });
  }

  Future<void> _loadMessages(AppLocale locale) async {
    final json = await rootBundle.loadString('assets/i18n/${locale.code}.json');
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    _messages = decoded.map((k, v) => MapEntry(k, v.toString()));
  }
}

/// Shortcut: `context.t('nav.home')`.
extension LocaleTranslateX on BuildContext {
  String t(String key, [Map<String, Object?>? params]) =>
      LocaleController.instance.t(key, params);

  AppLocale get appLocale => LocaleController.instance.locale;
}

/// Rebuild khi đổi ngôn ngữ.
class LocaleScope extends StatelessWidget {
  final Widget Function(BuildContext context, LocaleController locale) builder;

  const LocaleScope({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => builder(context, LocaleController.instance),
    );
  }
}
