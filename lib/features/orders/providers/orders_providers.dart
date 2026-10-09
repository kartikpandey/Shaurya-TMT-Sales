import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../../users/domain/entities/app_user.dart';
import '../data/order_repository.dart';
import '../domain/entities/order.dart';
import '../domain/entities/product.dart';

final ordersRepositoryProvider = Provider<OrderRepository>((ref) {
  final factory = ref.watch(offlineStoreFactoryProvider);
  return OrderRepository(
    store: factory(
      boxName: AppConstants.ordersBox,
      resource: SyncResource.order,
    ),
    remote: ref.watch(remoteCacheServiceProvider),
  );
});

final productsProvider = Provider<List<Product>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(ordersRepositoryProvider).products();
});

/// Orders booked by the signed-in user.
final myOrdersProvider = Provider<List<Order>>((ref) {
  ref.watch(dataVersionProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(ordersRepositoryProvider).forOwners({user.id});
});

/// Orders across the observable scope (own + downline), for heads.
final scopedOrdersProvider = Provider<List<Order>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(userScopeProvider).toSet();
  if (scope.isEmpty) return const [];
  return ref.watch(ordersRepositoryProvider).forOwners(scope);
});

/// Orders across the observable scope, restricted to a single external entity
/// or a single team member when a filter is active.
final filteredOrdersProvider = Provider.family<List<Order>, OrderFilter>((
  ref,
  filter,
) {
  final base = ref.watch(scopedOrdersProvider);
  return base.where((order) {
    if (filter.entityId != null && order.entityId != filter.entityId) {
      return false;
    }
    if (filter.ownerId != null && order.ownerId != filter.ownerId) {
      return false;
    }
    if (filter.query != null && filter.query!.isNotEmpty) {
      final q = filter.query!.toLowerCase();
      final matchesId = order.id.toLowerCase().contains(q);
      final matchesItems = order.items.any(
        (i) => i.name.toLowerCase().contains(q) || i.size.contains(q),
      );
      if (!matchesId && !matchesItems) return false;
    }
    return true;
  }).toList();
});

class OrderFilter {
  const OrderFilter({this.entityId, this.ownerId, this.query});

  final String? entityId;
  final String? ownerId;
  final String? query;

  bool get isActive => entityId != null || ownerId != null || (query?.isNotEmpty ?? false);

  @override
  bool operator ==(Object other) =>
      other is OrderFilter &&
      other.entityId == entityId &&
      other.ownerId == ownerId &&
      other.query == query;

  @override
  int get hashCode => Object.hash(entityId, ownerId, query);
}

/// Builds a draft order ready to be persisted.
Order newDraftOrder({
  required AppUser owner,
  required String entityId,
  required List<OrderItem> items,
  String? remarks,
}) => Order(
  id: const Uuid().v4(),
  ownerId: owner.id,
  entityId: entityId,
  items: items,
  createdAt: DateTime.now(),
  remarks: remarks,
);
