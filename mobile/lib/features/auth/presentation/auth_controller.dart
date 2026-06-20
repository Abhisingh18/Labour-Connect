import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({this.status = AuthStatus.unknown, this.user});

  AuthState copyWith({AuthStatus? status, AppUser? user, bool clearUser = false}) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
    );
  }

  String? get role => user?.role;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Wire global 401 handling to force logout.
    ref.read(dioClientProvider).onUnauthorized = () {
      // ignore: discarded_futures
      logout();
    };
    return const AuthState();
  }

  /// Restore session on app start.
  Future<void> bootstrap() async {
    final token = await ref.read(tokenStorageProvider).readToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
    }
  }

  Future<String?> sendOtp(String phone) => _repo.sendOtp(phone);

  /// Verifies OTP, persists the session and loads the user.
  Future<void> verifyOtp({
    required String phone,
    required String otp,
    required String role,
    String? name,
  }) async {
    final result = await _repo.verifyOtp(
      phone: phone,
      otp: otp,
      role: role,
      name: name,
    );
    await ref.read(tokenStorageProvider).save(
          token: result.accessToken,
          refreshToken: result.refreshToken,
          role: result.role,
          userId: result.userId,
        );
    final user = await _repo.me();
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void setUser(AppUser user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    final refresh = await ref.read(tokenStorageProvider).readRefresh();
    if (refresh != null && refresh.isNotEmpty) {
      await _repo.logout(refresh); // best-effort server revoke
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
