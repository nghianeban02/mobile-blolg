/// Lowercase slug for catalog create/update payloads.
String slugify(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}
