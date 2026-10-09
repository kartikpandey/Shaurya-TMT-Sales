import '../../../../core/domain/geo_point.dart';
import '../../../../core/domain/sync_status.dart';

/// A check-in / check-out pair at a customer or dealer premises.
///
/// Per spec: GPS + duration only. No visit notes/comments are captured.
class Visit {
  const Visit({
    required this.id,
    required this.userId,
    required this.entityId,
    required this.checkInAt,
    this.checkOutAt,
    this.checkInLocation,
    this.checkOutLocation,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String userId;

  /// The distributor / dealer / sub-dealer that was visited.
  final String entityId;

  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final GeoPoint? checkInLocation;
  final GeoPoint? checkOutLocation;
  final SyncStatus syncStatus;

  bool get isActive => checkOutAt == null;

  Duration get duration {
    final end = checkOutAt ?? DateTime.now();
    final d = end.difference(checkInAt);
    return d.isNegative ? Duration.zero : d;
  }

  Visit copyWith({
    DateTime? checkOutAt,
    GeoPoint? checkOutLocation,
    SyncStatus? syncStatus,
  }) => Visit(
    id: id,
    userId: userId,
    entityId: entityId,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt ?? this.checkOutAt,
    checkInLocation: checkInLocation,
    checkOutLocation: checkOutLocation ?? this.checkOutLocation,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'entityId': entityId,
    'checkInAt': checkInAt.toIso8601String(),
    'checkOutAt': checkOutAt?.toIso8601String(),
    'checkInLocation': checkInLocation?.toJson(),
    'checkOutLocation': checkOutLocation?.toJson(),
    'syncStatus': syncStatus.name,
  };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: json['id'] as String,
    userId: json['userId'] as String,
    entityId: json['entityId'] as String,
    checkInAt: DateTime.parse(json['checkInAt'] as String),
    checkOutAt: json['checkOutAt'] == null
        ? null
        : DateTime.parse(json['checkOutAt'] as String),
    checkInLocation: json['checkInLocation'] == null
        ? null
        : GeoPoint.fromJson(json['checkInLocation'] as Map<String, dynamic>),
    checkOutLocation: json['checkOutLocation'] == null
        ? null
        : GeoPoint.fromJson(json['checkOutLocation'] as Map<String, dynamic>),
    syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
  );
}
