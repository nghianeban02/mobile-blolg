/// Date helpers aligned with web `formatDate` / `formatTimeAgo` (no intl dep).
abstract final class AppDateFormat {
  static const _monthsVi = [
    'Th1',
    'Th2',
    'Th3',
    'Th4',
    'Th5',
    'Th6',
    'Th7',
    'Th8',
    'Th9',
    'Th10',
    'Th11',
    'Th12',
  ];

  static String formatDate(DateTime? date, {String locale = 'vi'}) {
    if (date == null) return '';
    final d = date.toLocal();
    if (locale.startsWith('vi')) {
      return '${d.day} ${_monthsVi[d.month - 1]}, ${d.year}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String formatTimeAgo(DateTime? date, {String locale = 'vi'}) {
    if (date == null) return '';
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    final vi = locale.startsWith('vi');
    if (diff.inSeconds < 60) return vi ? 'vừa xong' : 'just now';
    if (diff.inMinutes < 60) {
      return vi ? '${diff.inMinutes} phút trước' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return vi ? '${diff.inHours} giờ trước' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return vi ? '${diff.inDays} ngày trước' : '${diff.inDays}d ago';
    }
    return formatDate(local, locale: locale);
  }
}
