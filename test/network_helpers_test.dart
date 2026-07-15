import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/be_blog_http.dart';

void main() {
  test('HTTP URI builder encodes query parameters', () {
    final uri = BeBlogHttp.uri('/api/search', {
      'q': 'sách hay',
      'type': 'books',
    });

    expect(uri.origin, Uri.parse(ApiConstants.baseUrl).origin);
    expect(uri.path, '/api/search');
    expect(uri.queryParameters['q'], 'sách hay');
    expect(uri.queryParameters['type'], 'books');
  });
}
