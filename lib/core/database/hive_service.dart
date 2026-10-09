import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import 'json_box.dart';

/// Owns Hive initialisation and exposes every box the app writes to.
class HiveService {
  HiveService._();

  static late Box<String> _session;
  static late Box<String> _users;
  static late Box<String> _punches;
  static late Box<String> _visits;
  static late Box<String> _orders;
  static late Box<String> _products;
  static late Box<String> _syncQueue;
  static late Box<String> _teamCache;
  static late Box<String> _meta;

  static Future<void> init() async {
    await Hive.initFlutter();
    _session = await Hive.openBox<String>(AppConstants.sessionBox);
    _users = await Hive.openBox<String>(AppConstants.usersBox);
    _punches = await Hive.openBox<String>(AppConstants.punchesBox);
    _visits = await Hive.openBox<String>(AppConstants.visitsBox);
    _orders = await Hive.openBox<String>(AppConstants.ordersBox);
    _products = await Hive.openBox<String>(AppConstants.productsBox);
    _syncQueue = await Hive.openBox<String>(AppConstants.syncQueueBox);
    _teamCache = await Hive.openBox<String>(AppConstants.teamCacheBox);
    _meta = await Hive.openBox<String>(AppConstants.metaBox);
  }

  static JsonBox get session => JsonBox(_session);
  static JsonBox get users => JsonBox(_users);
  static JsonBox get punches => JsonBox(_punches);
  static JsonBox get visits => JsonBox(_visits);
  static JsonBox get orders => JsonBox(_orders);
  static JsonBox get products => JsonBox(_products);
  static JsonBox get syncQueue => JsonBox(_syncQueue);
  static JsonBox get teamCache => JsonBox(_teamCache);
  static JsonBox get meta => JsonBox(_meta);

  /// Resolve a box by its [AppConstants] box-name - used by the sync engine to
  /// flip a queued record's `syncStatus` without knowing about each feature.
  static JsonBox byName(String name) => switch (name) {
    AppConstants.sessionBox => session,
    AppConstants.usersBox => users,
    AppConstants.punchesBox => punches,
    AppConstants.visitsBox => visits,
    AppConstants.ordersBox => orders,
    AppConstants.productsBox => products,
    AppConstants.syncQueueBox => syncQueue,
    AppConstants.teamCacheBox => teamCache,
    AppConstants.metaBox => meta,
    _ => throw ArgumentError('Unknown Hive box: $name'),
  };

  /// Test hook - lets unit tests run against a temporary directory.
  static Future<void> initForTest(String path) async {
    Hive.init(path);
    _session = await Hive.openBox<String>(AppConstants.sessionBox);
    _users = await Hive.openBox<String>(AppConstants.usersBox);
    _punches = await Hive.openBox<String>(AppConstants.punchesBox);
    _visits = await Hive.openBox<String>(AppConstants.visitsBox);
    _orders = await Hive.openBox<String>(AppConstants.ordersBox);
    _products = await Hive.openBox<String>(AppConstants.productsBox);
    _syncQueue = await Hive.openBox<String>(AppConstants.syncQueueBox);
    _teamCache = await Hive.openBox<String>(AppConstants.teamCacheBox);
    _meta = await Hive.openBox<String>(AppConstants.metaBox);
  }

  static Future<void> wipe() async {
    await Future.wait([
      _session.clear(),
      _users.clear(),
      _punches.clear(),
      _visits.clear(),
      _orders.clear(),
      _products.clear(),
      _syncQueue.clear(),
      _teamCache.clear(),
      _meta.clear(),
    ]);
  }
}
