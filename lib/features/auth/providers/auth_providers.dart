import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/geo_point.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../../users/domain/entities/app_user.dart';
import '../../users/providers/users_providers.dart';

enum AuthPhase {
  /// Session restored, deciding where to route.
  initial,

  /// No valid session -> Login screen.
  unauthenticated,

  /// Signed in but the account has no home coordinates yet -> mandatory gate.
  needsHomeCoordinates,

  /// Signed in and fully onboarded -> Dashboard.
  authenticated,
}

class AuthNotifier extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return AuthPhase.unauthenticated;
    return user.needsHomeCoordinates
        ? AuthPhase.needsHomeCoordinates
        : AuthPhase.authenticated;
  }

  Future<String?> login(String identifier, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(identifier, password);
    if (!ref.mounted) return result.failure;
    if (!result.isSuccess) return result.failure;

    final user = result.user!;
    state = user.needsHomeCoordinates
        ? AuthPhase.needsHomeCoordinates
        : AuthPhase.authenticated;
    return null;
  }

  Future<void> saveHomeCoordinates(GeoPoint point) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    await ref
        .read(usersRepositoryProvider)
        .saveHomeLocation(user.id, point);
    if (ref.mounted) state = AuthPhase.authenticated;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (ref.mounted) state = AuthPhase.unauthenticated;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    users: ref.watch(usersRepositoryProvider),
    session: ref.watch(sessionStoreProvider),
    dio: ref.watch(dioProvider),
    isOnline: () => ref.read(networkInfoProvider).isConnected,
  );
});

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthPhase>(AuthNotifier.new);

/// The signed-in account, re-read after every user write or sync.
final currentUserProvider = Provider<AppUser?>((ref) {
  final phase = ref.watch(authStateProvider);
  if (phase == AuthPhase.unauthenticated) return null;
  ref.watch(dataVersionProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

/// The current user, guaranteed non-null inside the authenticated shell.
final currentUserRequiredProvider = Provider<AppUser>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('currentUserRequiredProvider read while signed out.');
  }
  return user;
});

/// Ids the signed-in user is allowed to observe (self + downline).
final userScopeProvider = Provider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(usersRepositoryProvider).scopeIdsFor(user.id);
});

/// Downline members of the signed-in user (excludes self).
final downlineUsersProvider = Provider<List<AppUser>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(usersRepositoryProvider).downlineOf(user.id);
});
