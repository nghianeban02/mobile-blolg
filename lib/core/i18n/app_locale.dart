/// Locales hỗ trợ — khớp `web-blog/lib/i18n/locales.ts`.
enum AppLocale {
  vi('vi', 'vi_VN'),
  en('en', 'en_US'),
  ja('ja', 'ja_JP'),
  de('de', 'de_DE');

  const AppLocale(this.code, this.intlTag);

  final String code;
  final String intlTag;

  static const defaultLocale = AppLocale.vi;

  static AppLocale? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final locale in AppLocale.values) {
      if (locale.code == value) return locale;
    }
    return null;
  }

  static AppLocale detectFromPlatform(String? languageCode) {
    final code = languageCode?.toLowerCase() ?? '';
    if (code.startsWith('vi')) return AppLocale.vi;
    if (code.startsWith('ja')) return AppLocale.ja;
    if (code.startsWith('de')) return AppLocale.de;
    if (code.startsWith('en')) return AppLocale.en;
    return defaultLocale;
  }
}
