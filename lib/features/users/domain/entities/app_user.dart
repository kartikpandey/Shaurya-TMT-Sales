import '../../../../core/domain/geo_point.dart';
import '../../../../core/domain/sync_status.dart';
import '../../../../core/domain/user_role.dart';

/// One record that covers **both** hierarchies:
///
/// * internal  - `kind == internal`, `role` set, `reportsToId` links the
///   Manager -> Team Lead -> Sr. SE -> SE chain.
/// * external  - `kind == external`, `entityType` set, `parentEntityId` links
///   Distributor -> Dealer -> Customer (Sub-dealer).
class AppUser {
  const AppUser({
    required this.id,
    required this.kind,
    required this.name,
    required this.email,
    required this.phone,
    this.passwordHash = '',
    this.role,
    this.entityType,
    this.reportsToId,
    this.parentEntityId,
    this.companyName,
    this.address,
    this.homeLocation,
    this.profileImageUrl,
    this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final UserKind kind;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;

  final InternalRole? role;
  final ExternalEntityType? entityType;

  /// Internal hierarchy parent (their Team Lead / Manager / Sr. SE).
  final String? reportsToId;

  /// External hierarchy parent (dealer -> distributor, sub-dealer -> dealer).
  final String? parentEntityId;

  final String? companyName;
  final String? address;

  /// Registered office / home base. `null` means the user must be taken
  /// through the "Register Home Coordinates" gate after login.
  final GeoPoint? homeLocation;

  final String? profileImageUrl;

  /// Internal user that onboarded this account - powers the "user creations"
  /// feed in Team Activity.
  final String? createdBy;

  final DateTime createdAt;
  final bool isActive;
  final SyncStatus syncStatus;

  bool get isInternal => kind == UserKind.internal;
  bool get isExternal => kind == UserKind.external;
  bool get needsHomeCoordinates => homeLocation == null || homeLocation!.isZero;

  String get displayRole => isInternal
      ? (role?.label ?? 'Internal')
      : (entityType?.label ?? 'External');

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? id,
    UserKind? kind,
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    InternalRole? role,
    ExternalEntityType? entityType,
    String? reportsToId,
    String? parentEntityId,
    String? companyName,
    String? address,
    GeoPoint? homeLocation,
    String? profileImageUrl,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    SyncStatus? syncStatus,
    bool clearHomeLocation = false,
    bool clearReportsTo = false,
    bool clearParentEntity = false,
    bool clearCreatedBy = false,
  }) => AppUser(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    entityType: entityType ?? this.entityType,
    reportsToId: clearReportsTo ? null : (reportsToId ?? this.reportsToId),
    parentEntityId:
        clearParentEntity ? null : (parentEntityId ?? this.parentEntityId),
    companyName: companyName ?? this.companyName,
    address: address ?? this.address,
    homeLocation:
        clearHomeLocation ? null : (homeLocation ?? this.homeLocation),
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    createdBy: clearCreatedBy ? null : (createdBy ?? this.createdBy),
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'role': role?.name,
    'entityType': entityType?.name,
    'reportsToId': reportsToId,
    'parentEntityId': parentEntityId,
    'companyName': companyName,
    'address': address,
    'homeLocation': homeLocation?.toJson(),
    'profileImageUrl': profileImageUrl,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'syncStatus': syncStatus.name,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    kind: UserKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => UserKind.internal,
    ),
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    passwordHash: json['passwordHash'] as String? ?? '',
    role: json['role'] == null
        ? null
        : InternalRole.fromName(json['role'] as String),
    entityType: json['entityType'] == null
        ? null
        : ExternalEntityType.fromName(json['entityType'] as String),
    reportsToId: json['reportsToId'] as String?,
    parentEntityId: json['parentEntityId'] as String?,
    companyName: json['companyName'] as String?,
    address: json['address'] as String?,
    homeLocation: json['homeLocation'] == null
        ? null
        : GeoPoint.fromJson(json['homeLocation'] as Map<String, dynamic>),
    profileImageUrl: json['profileImageUrl'] as String?,
    createdBy: json['createdBy'] as String?,
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['createdAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
    syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
  );
}
