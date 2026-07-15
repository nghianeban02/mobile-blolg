/// Truncates long API text for list cards (avoids laying out full bodies).
String textExcerpt(String? text, {int maxLength = 160}) {
  if (text == null) return '';
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength).trimRight()}…';
}
