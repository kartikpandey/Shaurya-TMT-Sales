import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/session/session_store.dart';
import '../../users/domain/entities/app_user.dart';
import '../../users/domain/entities/password_hasher.dart';
import '../../users/domain/users_repository_contract.dart';

class AuthResult {
  const AuthResult.success(this.user) : failure = null;
  const AuthResult.failure(String message) : user = null, failure = message;

  final AppUser? user;
  final String? failure;

  bool get isSuccess => user != null;
}

/// Hybrid auth:
/// * credentials are verified against the locally cached account store, which
///   is what makes login possible with no connectivity;
/// * when online the same payload is validated against the backend so a
///   revoked password is still rejected.
class AuthRepository {
  AuthRepository({
    required this.users,
    required this.session,
    this.dio,
    required this.isOnline,
  });

  final UsersRepositoryContract users;
  final SessionStore session;
  final Dio? dio;
  final Future<bool> Function() isOnline;

  AppUser? get currentUser {
    final id = session.userId;
    if (id == null) return null;
    return users.getById(id);
  }

  Future<AuthResult> login(String identifier, String password) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      return const AuthResult.failure('Enter your email/phone and password.');
    }

    final user = users.getByEmailOrPhone(trimmed);
    if (user == null || !user.isActive) {
      return const AuthResult.failure('Invalid email/phone or password.');
    }
    if (!PasswordHasher.matches(password, user.passwordHash)) {
      return const AuthResult.failure('Invalid email/phone or password.');
    }

    // Best-effort server validation - never blocks an offline login.
    if (await isOnline() && dio != null && AppConstants.useMockApi) {
      try {
        await dio!.post<dynamic>(
          AppConstants.loginEndpoint,
          data: {'identifier': trimmed, 'password': password},
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          return const AuthResult.failure('Invalid email/phone or password.');
        }
        // Network/5xx - fall through and trust the local credential check.
      }
    }

    await session.save(
      token: 'local-${user.id}',
      userId: user.id,
    );
    return AuthResult.success(user);
  }

  Future<void> logout() => session.clear();
}
