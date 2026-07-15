class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final UserData? user;

  const LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final hasToken = json['accessToken'] != null;
    return LoginResponse(
      success: hasToken || (json['success'] as bool? ?? false),
      message: json['error'] as String? ?? json['message'] as String?,
      token: json['accessToken'] as String? ?? json['token'] as String?,
      user: json['user'] != null
          ? UserData.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserData {
  final int? id;
  final String? name;
  final String? email;

  const UserData({this.id, this.name, this.email});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
