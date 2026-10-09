import '../../../../core/domain/geo_point.dart';
import '../../../../core/domain/sync_status.dart';

enum PunchType { punchIn, punchOut }

/// A single ON DUTY / OFF DUTY transition. Punching is allowed from anywhere
/// (no geofencing) - coordinates are captured opportunistically for audit only.
class PunchRecord {
  const PunchRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.location,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String userId;
  final PunchType type;
  final DateTime createdAt;
  final GeoPoint? location;
  final SyncStatus syncStatus;

  bool get isIn => type == PunchType.punchIn;

  PunchRecord copyWith({GeoPoint? location, SyncStatus? syncStatus}) =>
      PunchRecord(
        id: id,
        userId: userId,
        type: type,
        createdAt: createdAt,
        location: location ?? this.location,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'location': location?.toJson(),
    'syncStatus': syncStatus.name,
  };

  factory PunchRecord.fromJson(Map<String, dynamic> json) => PunchRecord(
    id: json['id'] as String,
    userId: json['userId'] as String,
    type: PunchType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => PunchType.punchIn,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    location: json['location'] == null
        ? null
        : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
    syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
  );
}
