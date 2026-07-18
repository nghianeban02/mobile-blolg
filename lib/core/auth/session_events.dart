import 'dart:async';

/// Phát tín hiệu phiên đăng nhập hết hạn (401 từ API có auth).
///
/// be-blog dùng JWT đơn 24h, không có refresh token — khi hết hạn chỉ có thể
/// đăng nhập lại. AuthBloc lắng nghe stream này để dọn phiên và điều hướng.
class SessionEvents {
  SessionEvents._();

  static final SessionEvents instance = SessionEvents._();

  final StreamController<void> _expiredController =
      StreamController<void>.broadcast();

  DateTime? _lastEmit;

  Stream<void> get onSessionExpired => _expiredController.stream;

  /// Debounce 5s để tránh dồn dập khi nhiều request cùng nhận 401.
  void notifySessionExpired() {
    final now = DateTime.now();
    if (_lastEmit != null && now.difference(_lastEmit!).inSeconds < 5) return;
    _lastEmit = now;
    _expiredController.add(null);
  }
}
