class AppUser {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String role; // customer | worker | admin
  final String? profileImage;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.profileImage,
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'User',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String? ?? 'customer',
        profileImage: json['profile_image'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  bool get isWorker => role == 'worker';
  bool get isCustomer => role == 'customer';
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String role;
  final int userId;
  final bool isNewUser;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
    required this.isNewUser,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String? ?? '',
        role: json['role'] as String,
        userId: json['user_id'] as int,
        isNewUser: json['is_new_user'] as bool? ?? false,
      );
}
