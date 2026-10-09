import 'package:uuid/uuid.dart';

import '../../features/users/domain/entities/password_hasher.dart';
import '../constants/app_constants.dart';
import 'hive_service.dart';

/// Demo dataset: internal org tree, external customer hierarchy, product
/// catalog and a few days of field activity.
///
/// The exact same data seeds Hive (local cache) and `MockServerStore` (the
/// fake backend) so the app is fully populated on first launch.
class SeedData {
  SeedData._();

  static const String managerId = 'u_mgr';
  static const String leadId = 'u_tl1';
  static const String execId = 'u_se1';

  static String passwordHash() =>
      PasswordHasher.hash(AppConstants.demoPassword);

  static Map<String, List<Map<String, dynamic>>> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime at(int dayOffset, int hour, int minute) => today
        .subtract(Duration(days: dayOffset))
        .add(Duration(hours: hour, minutes: minute));

    final users = _users();
    final products = _products();
    final punches = _punches(at);
    final visits = _visits(at);
    final orders = _orders(at);

    return {
      'users': users,
      'products': products,
      'punches': punches,
      'visits': visits,
      'orders': orders,
    };
  }

  // ------------------------------------------------------------- users ---
  static List<Map<String, dynamic>> _users() {
    final created = DateTime.now().subtract(const Duration(days: 180));

    Map<String, dynamic> internal({
      required String id,
      required String name,
      required String email,
      required String phone,
      required String role,
      String? reportsTo,
      GeoPointSeed? home,
    }) => {
      'id': id,
      'kind': 'internal',
      'name': name,
      'email': email,
      'phone': phone,
      'passwordHash': passwordHash(),
      'role': role,
      'reportsToId': reportsTo,
      'companyName': 'Shaurya TMT',
      'address': 'Pune, Maharashtra',
      'homeLocation': home?.toJson(),
      'createdAt': created.toIso8601String(),
      'isActive': true,
      'syncStatus': 'synced',
    };

    Map<String, dynamic> external({
      required String id,
      required String name,
      required String type,
      String? parent,
      required String phone,
      String? address,
    }) => {
      'id': id,
      'kind': 'external',
      'name': name,
      'email': '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@example.com',
      'phone': phone,
      'passwordHash': '',
      'entityType': type,
      'parentEntityId': parent,
      'companyName': name,
      'address': address ?? 'Maharashtra, India',
      'createdAt': created.toIso8601String(),
      'isActive': true,
      'syncStatus': 'synced',
    };

    return [
      // --- Internal hierarchy ---
      internal(
        id: managerId,
        name: 'Ravi Sharma',
        email: 'manager@shaurya.com',
        phone: '9000000001',
        role: 'salesManager',
        // Intentionally missing home coordinates so the mandatory
        // "Register Home Coordinates" gate is demonstrated on first login.
      ),
      internal(
        id: 'u_tl1',
        name: 'Anita Verma',
        email: 'lead@shaurya.com',
        phone: '9000000002',
        role: 'teamLead',
        reportsTo: managerId,
        home: const GeoPointSeed(18.5204, 73.8567),
      ),
      internal(
        id: 'u_tl2',
        name: 'Deepak Rao',
        email: 'lead2@shaurya.com',
        phone: '9000000003',
        role: 'teamLead',
        reportsTo: managerId,
        home: const GeoPointSeed(19.076, 72.8777),
      ),
      internal(
        id: 'u_sr1',
        name: 'Sunil Patil',
        email: 'sr1@shaurya.com',
        phone: '9000000004',
        role: 'seniorSalesExecutive',
        reportsTo: 'u_tl1',
        home: const GeoPointSeed(18.6414, 73.7747),
      ),
      internal(
        id: 'u_sr2',
        name: 'Priya Nair',
        email: 'sr2@shaurya.com',
        phone: '9000000005',
        role: 'seniorSalesExecutive',
        reportsTo: 'u_tl1',
        home: const GeoPointSeed(18.4529, 73.8586),
      ),
      internal(
        id: 'u_sr3',
        name: 'Sneha Iyer',
        email: 'sr3@shaurya.com',
        phone: '9000000006',
        role: 'seniorSalesExecutive',
        reportsTo: 'u_tl2',
        home: const GeoPointSeed(18.9894, 72.8354),
      ),
      internal(
        id: execId,
        name: 'Rahul Mehta',
        email: 'exec@shaurya.com',
        phone: '9000000007',
        role: 'salesExecutive',
        reportsTo: 'u_sr1',
        home: const GeoPointSeed(18.7, 73.8),
      ),
      internal(
        id: 'u_se2',
        name: 'Karan Joshi',
        email: 'exec2@shaurya.com',
        phone: '9000000008',
        role: 'salesExecutive',
        reportsTo: 'u_sr1',
        home: const GeoPointSeed(18.6298, 73.7997),
      ),
      internal(
        id: 'u_se3',
        name: 'Amit Kumar',
        email: 'exec3@shaurya.com',
        phone: '9000000009',
        role: 'salesExecutive',
        reportsTo: 'u_sr2',
        home: const GeoPointSeed(18.4082, 73.7626),
      ),
      internal(
        id: 'u_se4',
        name: 'Vikram Singh',
        email: 'exec4@shaurya.com',
        phone: '9000000010',
        role: 'salesExecutive',
        reportsTo: 'u_sr3',
        home: const GeoPointSeed(19.033, 73.0297),
      ),
      internal(
        id: 'u_se5',
        name: 'Neha Gupta',
        email: 'exec5@shaurya.com',
        phone: '9000000011',
        role: 'salesExecutive',
        reportsTo: 'u_sr3',
        home: const GeoPointSeed(19.1136, 72.8697),
      ),

      // --- External hierarchy: Distributor -> Dealer -> Sub-dealer ---
      external(
        id: 'e_d1',
        name: 'SteelEdge Distributors',
        type: 'distributor',
        phone: '9800000001',
        address: 'Chakan, Pune',
      ),
      external(
        id: 'e_d2',
        name: 'Metro Iron Traders',
        type: 'distributor',
        phone: '9800000002',
        address: 'Taloja, Navi Mumbai',
      ),
      external(
        id: 'e_de1',
        name: 'Shree Ganesh Steels',
        type: 'dealer',
        parent: 'e_d1',
        phone: '9800000003',
        address: 'Wakad, Pune',
      ),
      external(
        id: 'e_de2',
        name: 'Balaji Hardware',
        type: 'dealer',
        parent: 'e_d1',
        phone: '9800000004',
        address: 'Hinjawadi, Pune',
      ),
      external(
        id: 'e_de3',
        name: 'Sharma Steel Depot',
        type: 'dealer',
        parent: 'e_d2',
        phone: '9800000005',
        address: 'Vashi, Navi Mumbai',
      ),
      external(
        id: 'e_de4',
        name: 'Maruthi Hardware',
        type: 'dealer',
        parent: 'e_d2',
        phone: '9800000006',
        address: 'Kharghar, Navi Mumbai',
      ),
      external(
        id: 'e_c1',
        name: 'Jain Mining Co.',
        type: 'subDealer',
        parent: 'e_de1',
        phone: '9800000007',
        address: 'Rajgurunagar, Pune',
      ),
      external(
        id: 'e_c2',
        name: 'Sudama Traders',
        type: 'subDealer',
        parent: 'e_de2',
        phone: '9800000008',
        address: 'Pimpri, Pune',
      ),
      external(
        id: 'e_c3',
        name: 'Rahul Traders Inc.',
        type: 'subDealer',
        parent: 'e_de3',
        phone: '9800000009',
        address: 'Airoli, Navi Mumbai',
      ),
      external(
        id: 'e_c4',
        name: 'Kumar Distribution Center',
        type: 'subDealer',
        parent: 'e_de4',
        phone: '9800000010',
        address: 'Panvel, Navi Mumbai',
      ),
    ];
  }

  // ---------------------------------------------------------- products ---
  static List<Map<String, dynamic>> _products() {
    const prices = <String, double>{
      '6': 435,
      '8': 560,
      '10': 690,
      '12': 820,
      '16': 1450,
      '20': 2250,
    };
    final stock = <String, int>{
      '6': 1240,
      '8': 980,
      '10': 1560,
      '12': 870,
      '16': 540,
      '20': 320,
    };

    final items = <Map<String, dynamic>>[];
    for (final entry in prices.entries) {
      for (final grade in const ['Grade A', 'Grade B']) {
        final isB = grade == 'Grade B';
        items.add({
          'id': 'p_${entry.key}_${isB ? 'b' : 'a'}',
          'name': 'Shaurya TMT ${entry.key}mm',
          'size': '${entry.key}mm',
          'grade': grade,
          'unitPrice': isB ? entry.value - 15 : entry.value,
          'unit': 'pcs',
          'stock': (stock[entry.key] ?? 500) + (isB ? -120 : 0),
          'imageUrl': null,
        });
      }
    }
    return items;
  }

  // ------------------------------------------------------------ punches ---
  static List<Map<String, dynamic>> _punches(
    DateTime Function(int, int, int) at,
  ) {
    final items = <Map<String, dynamic>>[];
    const uuid = Uuid();

    void add(String userId, DateTime ts, String type) {
      items.add({
        'id': uuid.v4(),
        'userId': userId,
        'type': type,
        'createdAt': ts.toIso8601String(),
        'location': {
          'lat': 18.52 + (items.length % 7) * 0.01,
          'lng': 73.85 + (items.length % 5) * 0.01,
        },
        'syncStatus': 'synced',
      });
    }

    // Today - a few team members are already on duty / off duty.
    add('u_tl1', at(0, 9, 2), 'punchIn');
    add('u_sr1', at(0, 9, 11), 'punchIn');
    add(execId, at(0, 9, 24), 'punchIn');
    add(execId, at(0, 13, 45), 'punchOut');
    add(execId, at(0, 14, 20), 'punchIn');
    add('u_se2', at(0, 9, 5), 'punchIn');
    add('u_sr2', at(0, 9, 30), 'punchIn');
    add('u_se3', at(0, 9, 41), 'punchIn');
    add('u_tl2', at(0, 8, 55), 'punchIn');
    add('u_se5', at(0, 9, 50), 'punchIn');

    // Yesterday
    for (final userId in const [
      'u_tl1',
      'u_tl2',
      'u_sr1',
      'u_sr2',
      'u_sr3',
      execId,
      'u_se2',
      'u_se3',
      'u_se4',
      'u_se5',
    ]) {
      add(userId, at(1, 9, 5), 'punchIn');
      add(userId, at(1, 18, 10), 'punchOut');
    }

    // Day before
    for (final userId in const ['u_sr1', execId, 'u_se3']) {
      add(userId, at(2, 9, 15), 'punchIn');
      add(userId, at(2, 18, 0), 'punchOut');
    }

    return items;
  }

  // ------------------------------------------------------------ visits ----
  static List<Map<String, dynamic>> _visits(
    DateTime Function(int, int, int) at,
  ) {
    final items = <Map<String, dynamic>>[];
    const uuid = Uuid();

    void add({
      required String userId,
      required String entityId,
      required DateTime checkIn,
      DateTime? checkOut,
    }) {
      items.add({
        'id': uuid.v4(),
        'userId': userId,
        'entityId': entityId,
        'checkInAt': checkIn.toIso8601String(),
        'checkOutAt': checkOut?.toIso8601String(),
        'checkInLocation': {
          'lat': 18.5 + items.length * 0.02,
          'lng': 73.8 + items.length * 0.015,
        },
        'checkOutLocation': checkOut == null
            ? null
            : {
                'lat': 18.51 + items.length * 0.02,
                'lng': 73.81 + items.length * 0.015,
              },
        'syncStatus': 'synced',
      });
    }

    // Today - one active visit for the demo sales executive (started 45m ago
    // so the live duration counter always looks sensible).
    add(
      userId: execId,
      entityId: 'e_de1',
      checkIn: DateTime.now().subtract(const Duration(minutes: 45)),
    );
    add(userId: 'u_se2', entityId: 'e_c1', checkIn: at(0, 11, 5));
    add(userId: 'u_sr1', entityId: 'e_d1', checkIn: at(0, 12, 15));
    add(
      userId: 'u_se3',
      entityId: 'e_de3',
      checkIn: at(0, 9, 55),
      checkOut: at(0, 11, 20),
    );

    // Yesterday - all completed.
    add(
      userId: execId,
      entityId: 'e_de2',
      checkIn: at(1, 10, 0),
      checkOut: at(1, 11, 15),
    );
    add(
      userId: execId,
      entityId: 'e_c2',
      checkIn: at(1, 15, 30),
      checkOut: at(1, 16, 40),
    );
    add(
      userId: 'u_se2',
      entityId: 'e_de4',
      checkIn: at(1, 10, 45),
      checkOut: at(1, 12, 0),
    );
    add(
      userId: 'u_se4',
      entityId: 'e_c3',
      checkIn: at(1, 14, 10),
      checkOut: at(1, 15, 5),
    );
    add(
      userId: 'u_sr2',
      entityId: 'e_d2',
      checkIn: at(1, 11, 0),
      checkOut: at(1, 12, 30),
    );

    // Day before
    add(
      userId: execId,
      entityId: 'e_c1',
      checkIn: at(2, 10, 20),
      checkOut: at(2, 11, 40),
    );
    add(
      userId: 'u_se3',
      entityId: 'e_de1',
      checkIn: at(2, 9, 45),
      checkOut: at(2, 10, 55),
    );

    return items;
  }

  // ------------------------------------------------------------ orders ----
  static List<Map<String, dynamic>> _orders(
    DateTime Function(int, int, int) at,
  ) {
    Map<String, dynamic> item(
      String productId,
      String name,
      String size,
      String grade,
      int qty,
      double price,
    ) => {
      'productId': productId,
      'name': name,
      'size': size,
      'grade': grade,
      'quantity': qty,
      'unitPrice': price,
    };

    return [
      {
        'id': 'o_seed_1',
        'ownerId': execId,
        'entityId': 'e_de1',
        'items': [
          item('p_10_a', 'Shaurya TMT 10mm', '10mm', 'Grade A', 120, 690),
          item('p_12_a', 'Shaurya TMT 12mm', '12mm', 'Grade A', 80, 820),
        ],
        'status': 'accepted',
        'createdAt': at(0, 11, 40).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': 'PO-4521',
      },
      {
        'id': 'o_seed_2',
        'ownerId': 'u_se2',
        'entityId': 'e_c1',
        'items': [
          item('p_8_a', 'Shaurya TMT 8mm', '8mm', 'Grade A', 200, 560),
          item('p_8_b', 'Shaurya TMT 8mm', '8mm', 'Grade B', 100, 545),
        ],
        'status': 'placed',
        'createdAt': at(0, 12, 10).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': null,
      },
      {
        'id': 'o_seed_3',
        'ownerId': 'u_sr1',
        'entityId': 'e_d1',
        'items': [
          item('p_16_a', 'Shaurya TMT 16mm', '16mm', 'Grade A', 60, 1450),
          item('p_20_a', 'Shaurya TMT 20mm', '20mm', 'Grade A', 30, 2250),
        ],
        'status': 'accepted',
        'createdAt': at(0, 13, 5).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': 'Monthly stock refill',
      },
      {
        'id': 'o_seed_4',
        'ownerId': execId,
        'entityId': 'e_c2',
        'items': [
          item('p_6_a', 'Shaurya TMT 6mm', '6mm', 'Grade A', 150, 435),
          item('p_12_b', 'Shaurya TMT 12mm', '12mm', 'Grade B', 70, 800),
        ],
        'status': 'placed',
        'createdAt': at(1, 16, 20).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': null,
      },
      {
        'id': 'o_seed_5',
        'ownerId': 'u_se3',
        'entityId': 'e_de3',
        'items': [
          item('p_10_b', 'Shaurya TMT 10mm', '10mm', 'Grade B', 180, 675),
        ],
        'status': 'accepted',
        'createdAt': at(1, 10, 30).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': null,
      },
      {
        'id': 'o_seed_6',
        'ownerId': 'u_se4',
        'entityId': 'e_de4',
        'items': [
          item('p_20_b', 'Shaurya TMT 20mm', '20mm', 'Grade B', 25, 2210),
          item('p_16_b', 'Shaurya TMT 16mm', '16mm', 'Grade B', 45, 1420),
        ],
        'status': 'placed',
        'createdAt': at(2, 15, 0).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': 'Site delivery',
      },
      {
        'id': 'o_seed_7',
        'ownerId': 'u_sr2',
        'entityId': 'e_d2',
        'items': [
          item('p_12_a', 'Shaurya TMT 12mm', '12mm', 'Grade A', 300, 820),
        ],
        'status': 'accepted',
        'createdAt': at(2, 11, 25).toIso8601String(),
        'syncStatus': 'synced',
        'remarks': null,
      },
    ];
  }
}

/// Small value type used while building seed coordinates.
class GeoPointSeed {
  const GeoPointSeed(this.lat, this.lng);
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// Writes [SeedData] into Hive exactly once.
class Seeder {
  Seeder._();

  static Future<void> ensureSeeded() async {
    if (HiveService.meta.contains(AppConstants.seededFlagKey)) return;

    final data = SeedData.build();
    for (final record in data['users'] ?? const []) {
      await HiveService.users.put(record['id'] as String, record);
    }
    for (final record in data['products'] ?? const []) {
      await HiveService.products.put(record['id'] as String, record);
    }
    for (final record in data['punches'] ?? const []) {
      await HiveService.punches.put(record['id'] as String, record);
    }
    for (final record in data['visits'] ?? const []) {
      await HiveService.visits.put(record['id'] as String, record);
    }
    for (final record in data['orders'] ?? const []) {
      await HiveService.orders.put(record['id'] as String, record);
    }
    await HiveService.meta.put(AppConstants.seededFlagKey, {'seeded': true});
  }
}
