import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/providers/users_providers.dart';
import '../../domain/entities/order.dart';
import '../../providers/orders_providers.dart';
import 'order_form_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _ownerFilter;
  String? _entityFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final downline = ref.watch(downlineUsersProvider);
    final byId = ref.watch(usersByIdProvider);
    final canSeeTeam = user?.role != null &&
        PermissionService.canViewTeam(user!.role!);

    final orders = ref.watch(
      filteredOrdersProvider(
        OrderFilter(
          entityId: _entityFilter,
          ownerId: _ownerFilter,
          query: _query.isEmpty ? null : _query,
        ),
      ),
    );

    final totalValue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Orders',
        showBackButton: false,
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => _openFilterSheet(context, canSeeTeam, downline),
            icon: Badge(
              isLabelVisible: _ownerFilter != null || _entityFilter != null,
              label: const Icon(Icons.filter_alt, size: 12, color: Colors.white),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OrderFormScreen())),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('New order'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: SearchField(
                controller: _searchController,
                hint: 'Search order id, product or size...',
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const SyncBanner(compact: true),
            if (_ownerFilter != null || _entityFilter != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    if (_ownerFilter != null)
                      _ActiveFilter(
                        label: byId[_ownerFilter]?.name ?? 'Team member',
                        onClear: () => setState(() => _ownerFilter = null),
                      ),
                    if (_entityFilter != null) ...[
                      const SizedBox(width: 8),
                      _ActiveFilter(
                        label: byId[_entityFilter]?.name ?? 'Customer',
                        onClear: () => setState(() => _entityFilter = null),
                      ),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${orders.length} order${orders.length == 1 ? '' : 's'}',
                    style: AppTextStyles.labelMedium(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.formatCurrency(totalValue),
                    style: AppTextStyles.titleMedium(
                      context,
                    ).copyWith(color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders found',
                      subtitle:
                          'Book an order from the field and it will show up '
                          'here, even while offline.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: orders.length,
                      itemBuilder: (context, index) => _OrderCard(
                        order: orders[index],
                        entity: byId[orders[index].entityId],
                        owner: byId[orders[index].ownerId],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderFormScreen(editing: orders[index]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    bool canSeeTeam,
    List<AppUser> downline,
  ) async {
    final result = await showModalBottomSheet<({String? owner, String? entity})>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        ownerId: _ownerFilter,
        entityId: _entityFilter,
        team: canSeeTeam ? downline : const [],
      ),
    );
    if (result != null) {
      setState(() {
        _ownerFilter = result.owner;
        _entityFilter = result.entity;
      });
    }
  }
}

class _ActiveFilter extends StatelessWidget {
  const _ActiveFilter({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha:0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall(
              context,
            ).copyWith(color: AppColors.primaryOrange),
          ),
          InkWell(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.entity,
    required this.owner,
    required this.onTap,
  });

  final Order order;
  final AppUser? entity;
  final AppUser? owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id.length > 8
                      ? 'ORD-${order.id.substring(0, 8).toUpperCase()}'
                      : order.id.toUpperCase(),
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textDark),
                ),
              ),
              _StatusChip(status: order.status),
              const SizedBox(width: 8),
              SyncBadge(status: order.syncStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entity?.name ?? 'Unknown customer',
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (owner != null) 'By ${owner!.name}',
              AppFormatters.formatDate(order.createdAt),
              '${order.totalUnits} units',
              '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
            ].join('  â€¢  '),
            style: AppTextStyles.labelSmall(
              context,
            ).copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.items
                      .take(2)
                      .map((i) => '${i.name} ${i.size} x${i.quantity}')
                      .join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ),
              Text(
                AppFormatters.formatCurrency(order.totalAmount),
                style: AppTextStyles.titleMedium(
                  context,
                ).copyWith(color: AppColors.primaryOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      OrderStatus.draft => ('Draft', StatusTone.neutral),
      OrderStatus.placed => ('Placed', StatusTone.info),
      OrderStatus.accepted => ('Accepted', StatusTone.success),
      OrderStatus.rejected => ('Rejected', StatusTone.error),
    };
    return StatusChip(label: label, tone: tone, dense: true);
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.ownerId,
    required this.entityId,
    required this.team,
  });

  final String? ownerId;
  final String? entityId;
  final List<AppUser> team;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _owner;
  String? _entity;

  @override
  void initState() {
    super.initState();
    _owner = widget.ownerId;
    _entity = widget.entityId;
  }

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(externalEntitiesProvider);
    final me = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter orders', style: AppTextStyles.titleLarge(context)),
            const SizedBox(height: 16),
            if (widget.team.isNotEmpty) ...[
              Text('Team member', style: AppTextStyles.labelMedium(context)),
              const SizedBox(height: 8),
              _RadioOption(
                label: 'Everyone in my scope',
                selected: _owner == null,
                onTap: () => setState(() => _owner = null),
              ),
              if (me != null)
                _RadioOption(
                  label: 'Only my orders (${me.name})',
                  selected: _owner == me.id,
                  onTap: () => setState(() => _owner = me.id),
                ),
              ...widget.team.map(
                (member) => _RadioOption(
                  label: member.name,
                  selected: _owner == member.id,
                  onTap: () => setState(() => _owner = member.id),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('Customer', style: AppTextStyles.labelMedium(context)),
            const SizedBox(height: 8),
            _RadioOption(
              label: 'All customers',
              selected: _entity == null,
              onTap: () => setState(() => _entity = null),
            ),
            ...entities.map(
              (entity) => _RadioOption(
                label: '${entity.entityType!.label} - ${entity.name}',
                selected: _entity == entity.id,
                onTap: () => setState(() => _entity = entity.id),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _owner = null;
                      _entity = null;
                    }),
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      (owner: _owner, entity: _entity),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primaryOrange : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: selected ? AppColors.primaryOrange : AppColors.textDark,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
