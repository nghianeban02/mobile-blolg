/// Body for **be-blog** `POST /api/auth/register`.
class RegisterRequest {
  final String username;
  final String email;
  final String password;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
  };
}

class RegisterResult {
  final bool success;
  final String? message;

  /// true khi backend yêu cầu xác nhận email (HTTP 202) trước khi đăng nhập.
  final bool needsVerification;

  const RegisterResult({
    required this.success,
    this.message,
    this.needsVerification = false,
  });
}

/// Kết quả `POST /api/auth/verify-email` / `resend-verification`.
class VerifyEmailResult {
  final bool success;
  final String? message;
  final String? username;

  const VerifyEmailResult({required this.success, this.message, this.username});
}
