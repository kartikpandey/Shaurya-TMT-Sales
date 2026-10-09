import 'entities/app_user.dart';

/// Resolves the direct + indirect downline of an internal user.
///
/// Rule: walk up `reportsToId` from every candidate until you either hit the
/// root user (candidate is a descendant) or the starting user (candidate is
/// not).
class UserHierarchy {
  const UserHierarchy._();

  /// All descendants of [userId] (any depth).
  static List<AppUser> downlineOf(List<AppUser> all, String userId) {
    if (userId.isEmpty) return const [];

    final byId = <String, AppUser>{for (final u in all) u.id: u};
    final result = <AppUser>[];
    final visited = <String>{};

    // Breadth-first over children instead of walking up per candidate -
    // O(n) regardless of hierarchy depth.
    var frontier = <String>[userId];
    while (frontier.isNotEmpty) {
      final next = <String>[];
      for (final parent in frontier) {
        for (final user in all) {
          if (user.reportsToId == parent &&
              user.id != userId &&
              !visited.contains(user.id)) {
            visited.add(user.id);
            result.add(user);
            next.add(user.id);
          }
        }
      }
      frontier = next;
    }

    // Keep the map alive for callers that pass partial lists.
    assert(byId.length == all.length);
    return result;
  }

  /// `[userId, ...downline]` - the full scope a head is allowed to observe.
  static List<String> scopeIds(List<AppUser> all, String userId) =>
      [userId, ...downlineOf(all, userId).map((u) => u.id)];

  static bool isInDownline(List<AppUser> all, String headId, String candidateId) =>
      downlineOf(all, headId).any((u) => u.id == candidateId);
}
