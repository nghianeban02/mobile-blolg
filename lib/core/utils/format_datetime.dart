/// Định dạng ngày giờ đầy đủ cho bình luận: `dd/MM/yyyy · HH:mm`.
String formatCommentDateTime(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year;
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y · $h:$min';
}
