import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_app/core/constants/app_constants.dart';
import 'package:sales_app/core/database/hive_service.dart';
import 'package:sales_app/core/database/seed_data.dart';
import 'package:sales_app/core/domain/geo_point.dart';
import 'package:sales_app/core/network/network_info.dart';
import 'package:sales_app/core/providers/core_providers.dart';
import 'package:sales_app/core/session/session_store.dart';
import 'package:sales_app/features/auth/providers/auth_providers.dart';

/// Forces every login in these tests down the offline path - no platform
/// channels, no sockets.
class _OfflineNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('sales_auth_test');
    await HiveService.initForTest(tempDir.path);
    await Seeder.ensureSeeded();
  });

  setUp(() async {
    await SessionStore().clear();
  });

  tearDownAll(() async {
    await HiveService.wipe();
    await Hive.close();
    try { tempDir.deleteSync(recursive: true); } catch (_) {}
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        networkInfoProvider.overrideWithValue(_OfflineNetwork()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a fresh install starts on the login screen', () {
    final container = buildContainer();
    expect(container.read(authStateProvider), AuthPhase.unauthenticated);
  });

  test('bad credentials are rejected without changing the phase', () async {
    final container = buildContainer();

    final error = await container
        .read(authStateProvider.notifier)
        .login('exec@shaurya.com', 'wrong-password');

    expect(error, isNotNull);
    expect(container.read(authStateProvider), AuthPhase.unauthenticated);
  });

  test('unknown accounts are rejected', () async {
    final container = buildContainer();

    final error = await container
        .read(authStateProvider.notifier)
        .login('nobody@shaurya.com', AppConstants.demoPassword);

    expect(error, isNotNull);
    expect(container.read(authStateProvider), AuthPhase.unauthenticated);
  });

  test('a manager without home coordinates is forced through the gate', () async {
    final container = buildContainer();
    final auth = container.read(authStateProvider.notifier);

    final error = await auth.login('manager@shaurya.com', AppConstants.demoPassword);

    expect(error, isNull);
    expect(container.read(authStateProvider), AuthPhase.needsHomeCoordinates);
  });

  test('saving home coordinates completes onboarding', () async {
    final container = buildContainer();
    final auth = container.read(authStateProvider.notifier);

    await auth.login('manager@shaurya.com', AppConstants.demoPassword);
    expect(container.read(authStateProvider), AuthPhase.needsHomeCoordinates);

    await auth.saveHomeCoordinates(const GeoPoint(lat: 18.5204, lng: 73.8567));
    expect(container.read(authStateProvider), AuthPhase.authenticated);

    final manager = await HiveService.users.get('u_mgr');
    expect(manager, isNotNull);
  });

  test('an executive with home coordinates reaches the dashboard directly',
      () async {
    final container = buildContainer();

    final error = await container
        .read(authStateProvider.notifier)
        .login('exec@shaurya.com', AppConstants.demoPassword);

    expect(error, isNull);
    expect(container.read(authStateProvider), AuthPhase.authenticated);
  });

  test('the session survives an app restart', () async {
    final first = buildContainer();
    await first
        .read(authStateProvider.notifier)
        .login('exec@shaurya.com', AppConstants.demoPassword);
    expect(first.read(authStateProvider), AuthPhase.authenticated);

    // Simulate a cold start: a brand new container over the same Hive store.
    final second = buildContainer();
    expect(second.read(authStateProvider), AuthPhase.authenticated);
  });

  test('logout clears the session', () async {
    final container = buildContainer();
    final auth = container.read(authStateProvider.notifier);

    await auth.login('exec@shaurya.com', AppConstants.demoPassword);
    expect(container.read(authStateProvider), AuthPhase.authenticated);

    await auth.logout();
    expect(container.read(authStateProvider), AuthPhase.unauthenticated);
  });
}
