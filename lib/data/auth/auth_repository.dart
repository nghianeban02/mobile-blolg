import 'dart:async';
import 'dart:convert';

import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/cache/api_list_cache.dart';
import 'package:mobile/core/cache/session_cache.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/core/network/be_blog_response_parser.dart';
import 'package:mobile/core/services/push_notifications_service.dart';
import 'package:mobile/data/auth/login_request.dart';
import 'package:mobile/data/auth/login_response.dart';
import 'package:mobile/data/auth/register_request.dart';

/// Handles authentication-related logic, interacting with the backend API
/// to perform login and managing the local session token via [TokenStore]
/// (flutter_secure_storage).
class AuthRepository {

  /// Performs a login attempt by hitting the backend API.
  /// Returns a [LoginResponse] which dictates if the action was successful or not.
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await BeBlogHttp.postJson(
        ApiConstants.authLogin,
        auth: false,
        body: request.toJson(),
      );

      final responseBody = _decodeBody(response.body);

      if (BeBlogResponseParser.isSuccess(response.statusCode)) {
        final loginResponse = LoginResponse.fromJson(responseBody);

        if (loginResponse.token != null) {
          ApiListCache.clear();
          SessionCache.clear();
          BeBlogHttp.invalidateImageAuthHeaders();
          await _saveToken(loginResponse.token!);
          // Đăng ký thiết bị nhận thông báo đẩy cho tài khoản vừa đăng nhập.
          unawaited(PushNotificationsService.instance.syncRegistration());
        }

        return loginResponse;
      }

      return LoginResponse(
        success: false,
        message:
            responseBody['error'] as String? ??
            responseBody['message'] as String? ??
            'Đăng nhập thất bại. Vui lòng thử lại.',
      );
    } on Exception catch (e) {
      return LoginResponse(success: false, message: _parseError(e));
    }
  }

  /// Read-only guest session, matching the public web entry flow.
  Future<LoginResponse> loginAsGuest() async {
    try {
      final response = await BeBlogHttp.postJson(
        ApiConstants.authGuest,
        auth: false,
      );
      final body = _decodeBody(response.body);
      if (!BeBlogResponseParser.isSuccess(response.statusCode)) {
        return LoginResponse(
          success: false,
          message:
              body['error'] as String? ??
              body['message'] as String? ??
              'Không thể mở chế độ khách.',
        );
      }
      final result = LoginResponse.fromJson(body);
      if (result.token != null) {
        ApiListCache.clear();
        SessionCache.clear();
        BeBlogHttp.invalidateImageAuthHeaders();
        await _saveToken(result.token!);
      }
      return result;
    } on Exception catch (e) {
      return LoginResponse(success: false, message: _parseError(e));
    }
  }

  /// `POST /api/auth/register` — **be-blog** `AuthController`.
  Future<RegisterResult> register(RegisterRequest request) async {
    try {
      final response = await BeBlogHttp.postJson(
        ApiConstants.authRegister,
        auth: false,
        body: request.toJson(),
      );
      final responseBody = _decodeBody(response.body);
      if (response.statusCode == 201 ||
          BeBlogResponseParser.isSuccess(response.statusCode)) {
        // 202 ACCEPTED → cần xác nhận email; 201 CREATED → đăng nhập được ngay.
        final needsVerification = response.statusCode == 202;
        return RegisterResult(
          success: true,
          needsVerification: needsVerification,
          message:
              responseBody['message'] as String? ??
              (needsVerification
                  ? 'Kiểm tra email để xác nhận tài khoản.'
                  : 'Đăng ký thành công.'),
        );
      }
      return RegisterResult(
        success: false,
        message:
            responseBody['error'] as String? ??
            responseBody['message'] as String? ??
            'Đăng ký thất bại.',
      );
    } on Exception catch (e) {
      return RegisterResult(success: false, message: _parseError(e));
    }
  }

  /// `POST /api/auth/verify-email` — xác nhận token từ email.
  Future<VerifyEmailResult> verifyEmail(String token) async {
    try {
      final response = await BeBlogHttp.postJson(
        ApiConstants.authVerifyEmail,
        auth: false,
        body: {'token': token.trim()},
      );
      final body = _decodeBody(response.body);
      if (BeBlogResponseParser.isSuccess(response.statusCode)) {
        return VerifyEmailResult(
          success: true,
          message: body['message'] as String? ?? 'Email đã được xác nhận.',
          username: body['username'] as String?,
        );
      }
      return VerifyEmailResult(
        success: false,
        message:
            body['error'] as String? ??
            body['message'] as String? ??
            'Mã xác nhận không hợp lệ hoặc đã hết hạn.',
      );
    } on Exception catch (e) {
      return VerifyEmailResult(success: false, message: _parseError(e));
    }
  }

  /// `POST /api/auth/resend-verification` — gửi lại link xác nhận.
  Future<VerifyEmailResult> resendVerification(String email) async {
    try {
      final response = await BeBlogHttp.postJson(
        ApiConstants.authResendVerification,
        auth: false,
        body: {'email': email.trim()},
      );
      final body = _decodeBody(response.body);
      if (BeBlogResponseParser.isSuccess(response.statusCode)) {
        return VerifyEmailResult(
          success: true,
          message:
              body['message'] as String? ??
              'Nếu email đang chờ xác nhận, chúng tôi đã gửi lại link.',
        );
      }
      return VerifyEmailResult(
        success: false,
        message:
            body['error'] as String? ??
            body['message'] as String? ??
            'Không thể gửi lại email xác nhận.',
      );
    } on Exception catch (e) {
      return VerifyEmailResult(success: false, message: _parseError(e));
    }
  }

  /// Sends a password-reset email without revealing account existence.
  Future<AuthActionResult> requestPasswordReset(String email) =>
      _publicAuthAction(
        ApiConstants.authForgotPassword,
        {'email': email.trim()},
        fallback: 'Nếu tài khoản tồn tại, email đặt lại mật khẩu đã được gửi.',
      );

  /// Resets a password using the one-time token received by email.
  Future<AuthActionResult> resetPassword({
    required String token,
    required String newPassword,
  }) => _publicAuthAction(ApiConstants.authResetPassword, {
    'token': token.trim(),
    'newPassword': newPassword,
  }, fallback: 'Mật khẩu đã được đặt lại.');

  Future<AuthActionResult> _publicAuthAction(
    String path,
    Map<String, dynamic> body, {
    required String fallback,
  }) async {
    try {
      final response = await BeBlogHttp.postJson(path, auth: false, body: body);
      final decoded = _decodeBody(response.body);
      if (BeBlogResponseParser.isSuccess(response.statusCode)) {
        return AuthActionResult(
          success: true,
          message: decoded['message'] as String? ?? fallback,
        );
      }
      return AuthActionResult(
        success: false,
        message:
            decoded['error'] as String? ??
            decoded['message'] as String? ??
            'Yêu cầu không thành công. Vui lòng thử lại.',
      );
    } on Exception catch (e) {
      return AuthActionResult(success: false, message: _parseError(e));
    }
  }

  Future<void> _saveToken(String token) =>
      TokenStore.instance.write(token);

  /// Retrieves the saved JWT auth token, if any.
  Future<String?> getToken() => TokenStore.instance.read();

  /// Clears the saved JWT token to actively log the user out.
  Future<void> logout() async {
    // Gỡ FCM token khi JWT còn hiệu lực để thiết bị ngừng nhận thông báo.
    await PushNotificationsService.instance.unregister();
    await TokenStore.instance.clear();
    ApiListCache.clear();
    SessionCache.clear();
    BeBlogHttp.invalidateImageAuthHeaders();
  }

  /// Drops an expired/invalid local token without making an authenticated call.
  Future<void> clearLocalSession() async {
    await TokenStore.instance.clear();
    ApiListCache.clear();
    SessionCache.clear();
    BeBlogHttp.invalidateImageAuthHeaders();
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  String _parseError(Exception e) {
    if (e is NetworkException) {
      return 'Không kết nối được API (${ApiConstants.baseUrl}). '
          'Kiểm tra mạng trên thiết bị hoặc thử lại sau.';
    }
    final message = e.toString();
    if (message.contains('SocketException') ||
        message.contains('TimeoutException')) {
      return 'Không kết nối được API (${ApiConstants.baseUrl}). '
          'Kiểm tra mạng trên thiết bị hoặc thử lại sau.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}

class AuthActionResult {
  final bool success;
  final String message;

  const AuthActionResult({required this.success, required this.message});
}
