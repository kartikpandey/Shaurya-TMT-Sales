import '../../../../core/domain/sync_status.dart';

enum OrderStatus { draft, placed, accepted, rejected }

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.size,
    required this.grade,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final String size;
  final String grade;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  OrderItem copyWith({int? quantity, double? unitPrice}) => OrderItem(
    productId: productId,
    name: name,
    size: size,
    grade: grade,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'size': size,
    'grade': grade,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as String,
    name: json['name'] as String? ?? '',
    size: json['size'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
  );
}

/// An order booked for any external entity (Distributor / Dealer / Customer).
class Order {
  const Order({
    required this.id,
    required this.ownerId,
    required this.entityId,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.placed,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.remarks,
  });

  final String id;

  /// The internal user who booked the order.
  final String ownerId;

  /// Distributor / dealer / sub-dealer the order is for.
  final String entityId;

  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  /// Optional short reference - not a visit note, just an order reference.
  final String? remarks;

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    List<OrderItem>? items,
    OrderStatus? status,
    String? entityId,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? remarks,
    bool clearRemarks = false,
  }) => Order(
    id: id,
    ownerId: ownerId,
    entityId: entityId ?? this.entityId,
    items: items ?? this.items,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    remarks: clearRemarks ? null : (remarks ?? this.remarks),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'entityId': entityId,
    'items': items.map((i) => i.toJson()).toList(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'syncStatus': syncStatus.name,
    'remarks': remarks,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String,
    entityId: json['entityId'] as String,
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    status: OrderStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => OrderStatus.placed,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
    remarks: json['remarks'] as String?,
  );
}
