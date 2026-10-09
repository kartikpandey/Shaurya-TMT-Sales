import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_service.dart';
import '../../../core/database/json_box.dart';
import '../../../core/network/remote_cache_service.dart';
import '../../../core/sync/offline_first_store.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../domain/entities/order.dart';
import '../domain/entities/product.dart';

/// Offline-first order booking. Local writes are visible immediately and the
/// mutation is queued for the sync engine.
class OrderRepository {
  OrderRepository({
    required this.store,
    required this.remote,
    JsonBox? productsBox,
  }) : _productsBox = productsBox ?? HiveService.products;

  final OfflineFirstStore store;
  final RemoteCacheService remote;
  final JsonBox _productsBox;

  List<Order> all() => store.box
      .all(
        orderBy: (a, b) => (b['createdAt'] as String? ?? '')
            .compareTo(a['createdAt'] as String? ?? ''),
      )
      .map(Order.fromJson)
      .toList();

  List<Order> forOwners(Set<String> ownerIds) =>
      all().where((o) => ownerIds.contains(o.ownerId)).toList();

  Order? getById(String id) {
    final json = store.box.get(id);
    return json == null ? null : Order.fromJson(json);
  }

  List<Product> products() =>
      _productsBox.all().map(Product.fromJson).toList()
        ..sort((a, b) => a.size.compareTo(b.size));

  Future<void> create(Order order) => store.save(
    id: order.id,
    data: order.toJson(),
    operation: SyncOperation.create,
    method: 'POST',
    endpoint: AppConstants.ordersEndpoint,
  );

  Future<void> update(Order order) => store.save(
    id: order.id,
    data: order.copyWith(updatedAt: DateTime.now()).toJson(),
    operation: SyncOperation.update,
    method: 'PUT',
    endpoint: '${AppConstants.ordersEndpoint}/${order.id}',
  );

  /// Pull downline orders from the backend into Hive. Silent no-op offline.
  Future<void> refresh() async {
    if (!await remote.isOnline) return;
    await remote.mergeCollection(
      AppConstants.ordersEndpoint,
      AppConstants.ordersBox,
    );
  }

  Future<void> refreshProducts() async {
    if (!await remote.isOnline) return;
    await remote.mergeCollection(
      AppConstants.productsEndpoint,
      AppConstants.productsBox,
    );
  }
}
