import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStore.instance.clear();
  });

  test('read returns null when empty', () async {
    expect(await TokenStore.instance.read(), isNull);
  });

  test('write then read returns token', () async {
    await TokenStore.instance.write('jwt-abc');
    expect(await TokenStore.instance.read(), 'jwt-abc');
    await TokenStore.instance.clear();
    expect(await TokenStore.instance.read(), isNull);
  });

  test('legacy prefs key matches historical auth_token', () {
    expect(TokenStore.legacyPrefsKey, 'auth_token');
  });
}
