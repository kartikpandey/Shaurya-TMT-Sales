/// Offline/online lifecycle of a locally persisted record.
enum SyncStatus {
  /// Created or edited while offline - not yet acknowledged by the server.
  pending,

  /// Acknowledged by the server.
  synced,

  /// Permanently rejected (4xx). Requires user attention.
  failed;

  static SyncStatus fromName(String? name) =>
      SyncStatus.values.firstWhere((s) => s.name == name, orElse: () => pending);

  String get label => switch (this) {
    SyncStatus.pending => 'Pending sync',
    SyncStatus.synced => 'Synced',
    SyncStatus.failed => 'Sync failed',
  };
}
