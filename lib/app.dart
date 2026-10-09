import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_home_coordinates_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/screens/home_shell.dart';
import 'core/theme/app_theme.dart';

class SalesApp extends ConsumerWidget {
  const SalesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(authStateProvider);

    // Keying by phase tears down the whole navigator stack whenever the
    // session changes (login, logout, home-coordinate registration).
    return MaterialApp(
      title: 'Shaurya TMT Sales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      key: ValueKey(phase),
      home: switch (phase) {
        AuthPhase.initial || AuthPhase.unauthenticated => const LoginScreen(),
        AuthPhase.needsHomeCoordinates => const RegisterHomeCoordinatesScreen(),
        AuthPhase.authenticated => const HomeShell(),
      },
    );
  }
}
