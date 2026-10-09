/// Whether a user belongs to the internal sales organisation or is an
/// external trading party in the customer hierarchy.
enum UserKind { internal, external }

/// Internal hierarchy. Lower [rank] == higher authority.
///
/// Manager (1) views Team Leads, Sr. SEs and SEs.
/// Team Lead (2) views Sr. SEs and SEs.
/// Sr. Sales Executive (3) views SEs.
/// Sales Executive (4) views only their own data.
enum InternalRole {
  salesManager(rank: 1, label: 'Sales Manager', shortLabel: 'Manager'),
  teamLead(rank: 2, label: 'Team Lead', shortLabel: 'Team Lead'),
  seniorSalesExecutive(
    rank: 3,
    label: 'Senior Sales Executive',
    shortLabel: 'Sr. SE',
  ),
  salesExecutive(rank: 4, label: 'Sales Executive', shortLabel: 'Sales Exec');

  final int rank;
  final String label;
  final String shortLabel;

  const InternalRole({
    required this.rank,
    required this.label,
    required this.shortLabel,
  });

  /// Roles that sit strictly below this role in the hierarchy.
  List<InternalRole> get subordinates =>
      InternalRole.values.where((r) => r.rank > rank).toList();

  bool outranks(InternalRole other) => rank < other.rank;

  static InternalRole fromName(String? name) => InternalRole.values
      .firstWhere((r) => r.name == name, orElse: () => salesExecutive);
}

/// External customer hierarchy:
/// Distributor -> Dealer -> Customer (Sub-dealer).
enum ExternalEntityType {
  distributor(label: 'Distributor', level: 1),
  dealer(label: 'Dealer', level: 2),
  subDealer(label: 'Customer (Sub-dealer)', level: 3);

  final String label;
  final int level;

  const ExternalEntityType({required this.label, required this.level});

  /// The parent type in the hierarchy, `null` for the top of the tree.
  ExternalEntityType? get parentType => switch (this) {
    distributor => null,
    dealer => distributor,
    subDealer => dealer,
  };

  static ExternalEntityType fromName(String? name) => ExternalEntityType.values
      .firstWhere((e) => e.name == name, orElse: () => dealer);
}

extension UserRoleX on UserKind {
  String get label => switch (this) {
    UserKind.internal => 'Internal',
    UserKind.external => 'External',
  };
}
