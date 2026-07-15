import 'dart:convert';
import 'dart:io';

/// Encodes a local image file as a `data:` URL for APIs that only accept URL strings.
class ImageDataUrlEncoder {
  ImageDataUrlEncoder._();

  static String mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static Future<String> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    final mime = mimeTypeFromPath(file.path);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}
