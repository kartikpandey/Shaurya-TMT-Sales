import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/user_role.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/entities/app_user.dart';
import '../../providers/users_providers.dart';
import '../screens/user_form_screen.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  bool _showCustomers = false;
  String _query = '';
  final _searchController = TextEditingController();

  void _onQuery(String value) =>
      setState(() => _query = value.trim().toLowerCase());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final all = ref.watch(allUsersProvider);
    final scope = ref.watch(userScopeProvider).toSet();
    final byId = ref.watch(usersByIdProvider);

    final actorRole = user?.role;
    final inScope = all.where((u) => scope.contains(u.id) || u.id == user?.id);

    final internal =
        inScope.where((u) => u.isInternal && u.id != user?.id).where((u) {
          if (actorRole == null) return false;
          return PermissionService.canObserve(actorRole, u.role!) &&
              u.role != null;
        }).toList();

    final customers = inScope.where((u) => u.isExternal).toList();

    final visible =
        (_showCustomers ? customers : internal).where((u) {
            if (_query.isEmpty) return true;
            return u.name.toLowerCase().contains(_query) ||
                (u.companyName ?? '').toLowerCase().contains(_query) ||
                u.email.toLowerCase().contains(_query);
          }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Users',
        showBackButton: false,
        actions: [
          IconButton(
            tooltip: 'Add user',
            onPressed: () => _showAddMenu(context, user),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      floatingActionButton:
          _showCustomers
              ? FloatingActionButton.extended(
                heroTag: 'users_fab',
                onPressed: () => _showAddMenu(context, user),
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                // label: Text(_showCustomers ? 'Add customer' : 'Add member'),
                label: Text('Add customer'),
              )
              : SizedBox(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: SearchField(
                controller: _searchController,
                hint: 'Search by name, company or email...',
                onChanged: _onQuery,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Team',
                      icon: Icons.badge_outlined,
                      selected: !_showCustomers,
                      onTap: () => setState(() => _showCustomers = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Customers',
                      icon: Icons.storefront_outlined,
                      selected: _showCustomers,
                      onTap: () => setState(() => _showCustomers = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  visible.isEmpty
                      ? EmptyState(
                        icon:
                            _showCustomers
                                ? Icons.storefront_outlined
                                : Icons.people_outline,
                        title:
                            _showCustomers
                                ? 'No customers found'
                                : 'No team members found',
                        subtitle:
                            _query.isEmpty
                                ? 'Tap the add button to create one.'
                                : 'No results for "$_query".',
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final target = visible[index];
                          return _UserTile(
                            user: target,
                            subtitle: _subtitle(target, byId),
                            isSelf: false,
                            onTap: () => _openEditor(context, user, target),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppUser target, Map<String, AppUser> byId) {
    if (target.isInternal) {
      final manager =
          target.reportsToId == null ? null : byId[target.reportsToId!];
      return [
        target.role?.label ?? 'Internal',
        if (manager != null) 'reports to ${manager.name}',
      ].join('  â€¢  ');
    }
    final parent =
        target.parentEntityId == null ? null : byId[target.parentEntityId!];
    return [
      target.entityType?.label ?? 'Customer',
      if (parent != null) 'under ${parent.name}',
    ].join('  â€¢  ');
  }

  Future<void> _showAddMenu(BuildContext context, AppUser? actor) async {
    final role = actor?.role;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddOption(
                  icon: Icons.storefront_outlined,
                  label: 'Distributor',
                  subtitle:
                      role == null
                          ? 'Not available for your account'
                          : 'Top of the customer hierarchy',
                  enabled:
                      role != null &&
                      PermissionService.canCreateExternalEntity(
                        role,
                        ExternalEntityType.distributor,
                      ),
                  onTap: () => Navigator.pop(context, 'distributor'),
                ),
                _AddOption(
                  icon: Icons.add_business_outlined,
                  label: 'Dealer',
                  subtitle:
                      role == null
                          ? 'Not available for your account'
                          : 'Create under an existing distributor',
                  enabled:
                      role != null &&
                      PermissionService.canCreateExternalEntity(
                        role,
                        ExternalEntityType.dealer,
                      ),
                  onTap: () => Navigator.pop(context, 'dealer'),
                ),
                _AddOption(
                  icon: Icons.add_business_outlined,
                  label: 'Sub-dealer',
                  subtitle:
                      role == null
                          ? 'Not available for your account'
                          : 'Create under an existing dealer',
                  enabled:
                      role != null &&
                      PermissionService.canCreateExternalEntity(
                        role,
                        ExternalEntityType.subDealer,
                      ),
                  onTap: () => Navigator.pop(context, 'subdealer'),
                ),
              ],
            ),
          ),
    );

    if (choice == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => UserFormScreen(
              initialType:
                  choice == 'internal'
                      ? UserFormMode.internal
                      : UserFormMode.external,
              presetEntityType:
                  choice == 'distributor'
                      ? ExternalEntityType.distributor
                      : choice == 'dealer'
                      ? ExternalEntityType.dealer
                      : choice == 'subdealer'
                      ? ExternalEntityType.subDealer
                      : null,
            ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppUser? actor,
    AppUser target,
  ) async {
    if (actor == null) return;
    if (target.isInternal) {
      if (actor.role == null ||
          !PermissionService.canEditInternalUser(actor.role!, target.role!)) {
        showAppSnack(
          context,
          'You can only edit users below your rank',
          isError: true,
        );
        return;
      }
    } else {
      if (actor.role == null ||
          !PermissionService.canEditExternalEntity(
            actor.role!,
            target.entityType!,
          )) {
        showAppSnack(
          context,
          'Your role cannot edit ${target.entityType!.label.toLowerCase()} records',
          isError: true,
        );
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserFormScreen(editing: target)));
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primaryOrange.withValues(alpha: 0.12)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? AppColors.primaryOrange.withValues(alpha: 0.5)
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryOrange : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: selected ? AppColors.primaryOrange : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.subtitle,
    required this.isSelf,
    required this.onTap,
  });

  final AppUser user;
  final String subtitle;
  final bool isSelf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelf
                    ? AppColors.primaryOrange.withValues(alpha: 0.4)
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              initials: user.initials,
              accent:
                  user.isInternal
                      ? AppColors.primaryOrange
                      : AppColors.infoBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (!user.isActive) const StatusBadgeInactive(),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadgeInactive extends StatelessWidget {
  const StatusBadgeInactive({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inactive',
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(color: AppColors.warningRed, fontSize: 10),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 20),
        ),
        title: Text(label, style: AppTextStyles.bodyMedium(context)),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: AppColors.textHint),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
