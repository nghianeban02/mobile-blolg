import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/i18n/app_locale.dart';
import 'package:mobile/core/i18n/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocaleController loads vi catalog and interpolates params', () async {
    final locale = LocaleController.instance;
    await locale.load();
    expect(locale.locale, isNotNull);
    expect(locale.t('nav.home'), isNot(equals('nav.home')));
    expect(locale.t('common.stars', {'count': 5}), contains('5'));
  });

  test('AppLocale.detectFromPlatform maps language codes', () {
    expect(AppLocale.detectFromPlatform('ja-JP'), AppLocale.ja);
    expect(AppLocale.detectFromPlatform('de'), AppLocale.de);
    expect(AppLocale.detectFromPlatform('en-US'), AppLocale.en);
    expect(AppLocale.detectFromPlatform('fr'), AppLocale.vi);
  });
}
