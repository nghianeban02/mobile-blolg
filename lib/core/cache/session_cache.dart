import 'package:mobile/data/models/dtos.dart';

/// Short-lived cache for `/api/users/me` (admin flag, profile).
class SessionCache {
  SessionCache._();

  static UserProfileDto? _profile;
  static DateTime? _expiresAt;
  static const Duration _ttl = Duration(minutes: 5);

  static UserProfileDto? get profile {
    if (_profile == null || _isExpired) {
      _profile = null;
      return null;
    }
    return _profile;
  }

  static bool get isAdmin => profile?.isAdmin ?? false;

  static void setProfile(UserProfileDto profile) {
    _profile = profile;
    _expiresAt = DateTime.now().add(_ttl);
  }

  static void clear() {
    _profile = null;
    _expiresAt = null;
  }

  static bool get _isExpired =>
      _expiresAt == null || DateTime.now().isAfter(_expiresAt!);
}
