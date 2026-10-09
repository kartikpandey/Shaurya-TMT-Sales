import 'package:uuid/uuid.dart';

/// What kind of record a queued mutation belongs to.
enum SyncResource {
  punch,
  visit,
  order,
  user,
  homeCoordinates,
}

enum SyncOperation { create, update, delete }

/// A single offline mutation waiting to reach the server.
///
/// The repository stamps everything the engine needs (HTTP verb + path +
/// payload) so the engine stays free of business logic, and it also records
/// `recordBox`/`recordId` so the stored record's `syncStatus` can be flipped
/// to `synced` once the server acknowledges it.
class SyncQueueItem {
  SyncQueueItem({
    String? id,
    required this.resource,
    required this.operation,
    required this.recordId,
    required this.recordBox,
    required this.method,
    required this.endpoint,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    this.retries = 0,
    this.lastError,
  }) : id = id ?? const Uuid().v4(),
       payload = payload ?? {},
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final SyncResource resource;
  final SyncOperation operation;
  final String recordId;
  final String recordBox;
  final String method;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retries;
  String? lastError;

  bool get canRetry => retries < 5;

  Map<String, dynamic> toJson() => {
    'id': id,
    'resource': resource.name,
    'operation': operation.name,
    'recordId': recordId,
    'recordBox': recordBox,
    'method': method,
    'endpoint': endpoint,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retries': retries,
    'lastError': lastError,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'] as String?,
    resource: SyncResource.values.firstWhere(
      (r) => r.name == json['resource'],
      orElse: () => SyncResource.order,
    ),
    operation: SyncOperation.values.firstWhere(
      (o) => o.name == json['operation'],
      orElse: () => SyncOperation.create,
    ),
    recordId: json['recordId'] as String? ?? '',
    recordBox: json['recordBox'] as String? ?? '',
    method: json['method'] as String? ?? 'POST',
    endpoint: json['endpoint'] as String? ?? '',
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['createdAt'] as String),
    retries: (json['retries'] as num?)?.toInt() ?? 0,
    lastError: json['lastError'] as String?,
  );
}
