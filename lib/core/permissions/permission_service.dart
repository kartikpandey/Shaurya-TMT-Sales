import '../domain/user_role.dart';

/// Central, testable authorisation matrix for the internal hierarchy and the
/// external customer hierarchy. Every screen goes through these rules so that
/// a Sales Executive never sees another user's data and heads see their full
/// downline.
class PermissionService {
  const PermissionService._();

  /// Only heads get the "Team Activity" tab.
  static bool canViewTeam(InternalRole role) =>
      role != InternalRole.salesExecutive;

  /// Roles the [actor] is allowed to observe (direct + indirect downline).
  static List<InternalRole> observableRoles(InternalRole actor) =>
      actor.subordinates;

  /// A head may observe any user whose role sits below theirs.
  static bool canObserve(InternalRole actor, InternalRole target) =>
      actor.outranks(target);

  /// Heads can create internal users one or more tiers below themselves.
  /// Sales Executives cannot create internal users.
  static bool canCreateInternalRole(InternalRole actor, InternalRole target) =>
      actor.outranks(target);

  /// Editing an internal peer/superior is never allowed.
  static bool canEditInternalUser(InternalRole actor, InternalRole target) =>
      actor.outranks(target);

  /// Distributors can only be onboarded by Manager / Team Lead.
  /// Dealers and Sub-dealers can be onboarded by anyone.
  static bool canCreateExternalEntity(
    InternalRole actor,
    ExternalEntityType type,
  ) {
    return switch (type) {
      ExternalEntityType.distributor => actor.rank <= 2,
      ExternalEntityType.dealer => true,
      ExternalEntityType.subDealer => true,
    };
  }

  static bool canEditExternalEntity(
    InternalRole actor,
    ExternalEntityType type,
  ) => canCreateExternalEntity(actor, type);

  /// Owners always edit their own orders; heads edit downline orders.
  /// [targetIsSelf] and [targetInDownline] are resolved by the caller using
  /// the downline closure.
  static bool canEditOrder({
    required bool targetIsSelf,
    required bool targetInDownline,
    required InternalRole actor,
  }) =>
      targetIsSelf || (canViewTeam(actor) && targetInDownline);

  /// Owners always edit their own records; heads edit downline records.
  static bool canEditUserRecord({
    required bool targetIsSelf,
    required bool targetInDownline,
    required InternalRole actor,
  }) =>
      targetIsSelf || (canViewTeam(actor) && targetInDownline);
}
