import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../providers/dashboard_providers.dart';
import 'dashboard_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../team_monitoring/presentation/screens/team_activity_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';
import '../../../visits/presentation/screens/visits_screen.dart';

/// Bottom navigation shell. The Team tab is hidden for Sales Executives,
/// who only ever see their own data.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final canViewTeam = ref.watch(
      dashboardStatsProvider.select((s) => s.canViewTeam),
    );

    final tabs = <Widget>[
      const DashboardScreen(),
      const VisitsScreen(),
      const OrdersScreen(),
      if (canViewTeam) const TeamActivityScreen(),
      const UsersScreen(),
    ];

    final items = <BottomNavItem>[
      BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      BottomNavItem(icon: Icons.place_outlined, label: 'Visits'),
      BottomNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
      if (canViewTeam)
        BottomNavItem(icon: Icons.groups_outlined, label: 'Team'),
      BottomNavItem(icon: Icons.people_alt_outlined, label: 'Users'),
    ];

    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: index,
        onTap: (i) => setState(() => _index = i),
        items: items,
      ),
    );
  }
}

/// Gradient greeting card used on the dashboard.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.premiumGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.headlineSmall(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
