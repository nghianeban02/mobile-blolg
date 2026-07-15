import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

/// Downloads a network image and saves it to the device photo library.
class PostImageSaveService {
  static Future<String?> saveFromUrl(String url) async {
    if (url.isEmpty) return 'URL ảnh không hợp lệ.';

    try {
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          return 'Cần quyền lưu ảnh vào thư viện ảnh.';
        }
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return 'Không tải được ảnh (${response.statusCode}).';
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) return 'Ảnh trống hoặc không hợp lệ.';

      final name = 'mobile_blog_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(bytes, name: name);
      return null;
    } on GalException catch (e) {
      return switch (e.type) {
        GalExceptionType.accessDenied => 'Cần quyền lưu ảnh vào thư viện ảnh.',
        GalExceptionType.notEnoughSpace => 'Không đủ dung lượng lưu trữ.',
        GalExceptionType.notSupportedFormat =>
          'Định dạng ảnh không được hỗ trợ.',
        GalExceptionType.unexpected => 'Lỗi không xác định khi lưu ảnh.',
      };
    } catch (_) {
      return 'Không thể lưu ảnh. Thử lại sau.';
    }
  }
}
