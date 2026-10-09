import 'package:dio/dio.dart';

import '../../features/users/domain/entities/password_hasher.dart';

/// In-memory stand-in for the backend.
///
/// It serves the exact same endpoints the real API exposes, so flipping
/// `AppConstants.useMockApi` to `false` swaps this out with zero changes to
/// repository code. Writes performed by the sync engine land here, which is
/// why downline monitoring feeds update as soon as a device comes back
/// online.
class MockServerStore {
  MockServerStore({Map<String, List<Map<String, dynamic>>>? seed})
    : _collections = {
        'users': List.of(seed?['users'] ?? const []),
        'products': List.of(seed?['products'] ?? const []),
        'punches': List.of(seed?['punches'] ?? const []),
        'visits': List.of(seed?['visits'] ?? const []),
        'orders': List.of(seed?['orders'] ?? const []),
      };

  final Map<String, List<Map<String, dynamic>>> _collections;

  List<Map<String, dynamic>> collection(String name) =>
      _collections[name] ?? const [];

  void replaceCollection(String name, List<Map<String, dynamic>> items) {
    _collections[name] = List.of(items);
  }

  /// Returns `null` when the request is not handled (it is then forwarded to
  /// the network as usual). [path] is relative to `AppConstants.baseUrl`.
  MockResponse? handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String> query,
  ) {
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) return null;

    switch (segments.first) {
      case 'auth':
        return _handleAuth(method, segments, body);
      case 'users':
        return _handleUsers(method, segments, body);
      case 'punches':
        return _handleSimple('punches', method, segments, body);
      case 'visits':
        return _handleSimple('visits', method, segments, body);
      case 'orders':
        return _handleSimple('orders', method, segments, body);
      case 'products':
        if (method == 'GET') return MockResponse.ok(collection('products'));
        return null;
      case 'team':
        return _handleTeam(query);
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------- auth --
  MockResponse? _handleAuth(
    String method,
    List<String> segments,
    Map<String, dynamic>? body,
  ) {
    if (segments.length < 2 || segments[1] != 'login' || method != 'POST') {
      return null;
    }
    final identifier = (body?['identifier'] as String? ?? '').trim();
    final password = body?['password'] as String? ?? '';
    final users = collection('users');
    final user = users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final phone = u['phone'] as String? ?? '';
      final id = identifier.toLowerCase();
      return email == id || phone == identifier || phone.endsWith(identifier);
    }).toList();

    if (user.isEmpty) return MockResponse.error(401, 'Invalid credentials.');
    final storedHash = user.first['passwordHash'] as String? ?? '';
    if (!PasswordHasher.matches(password, storedHash)) {
      return MockResponse.error(401, 'Invalid credentials.');
    }
    return MockResponse.ok({
      'token': 'mock-token-${user.first['id']}',
      'user': user.first,
    });
  }

  // --------------------------------------------------------------- users --
  MockResponse? _handleUsers(
    String method,
    List<String> segments,
    Map<String, dynamic>? body,
  ) {
    if (segments.length == 1) {
      if (method == 'GET') return MockResponse.ok(collection('users'));
      if (method == 'POST' && body != null) {
        _upsert('users', body);
        return MockResponse.ok(body);
      }
      return null;
    }

    final id = segments[1];
    if (segments.length >= 4 &&
        segments[2] == 'home-coordinates' &&
        method == 'PUT') {
      final user = _findById('users', id);
      if (user == null) return MockResponse.error(404, 'User not found.');
      user['homeLocation'] = body?['homeLocation'];
      return MockResponse.ok(user);
    }

    if (method == 'GET') {
      final user = _findById('users', id);
      return user == null ? MockResponse.error(404, 'User not found.') : MockResponse.ok(user);
    }
    if (method == 'PUT' && body != null) {
      _upsert('users', body);
      return MockResponse.ok(body);
    }
    if (method == 'DELETE') {
      _collections['users']?.removeWhere((u) => u['id'] == id);
      return MockResponse.ok({'id': id});
    }
    return null;
  }

  // -------------------------------------------------------------- simple --
  MockResponse? _handleSimple(
    String collectionName,
    String method,
    List<String> segments,
    Map<String, dynamic>? body,
  ) {
    if (segments.length == 1) {
      if (method == 'GET') return MockResponse.ok(collection(collectionName));
      if (method == 'POST' && body != null) {
        _upsert(collectionName, body);
        return MockResponse.ok(body);
      }
      return null;
    }
    if (segments.length >= 2) {
      final id = segments[1];
      if (method == 'GET') {
        final record = _findById(collectionName, id);
        return record == null
            ? MockResponse.error(404, 'Not found.')
            : MockResponse.ok(record);
      }
      if (method == 'PUT' && body != null) {
        _upsert(collectionName, body);
        return MockResponse.ok(body);
      }
      if (method == 'DELETE') {
        _collections[collectionName]?.removeWhere((r) => r['id'] == id);
        return MockResponse.ok({'id': id});
      }
    }
    return null;
  }

  // --------------------------------------------------------------- team --
  MockResponse _handleTeam(Map<String, String> query) {
    final rawIds = query['ids'] ?? '';
    final ids = rawIds
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    List<Map<String, dynamic>> filter(String name) => collection(
      name,
    ).where((r) => ids.contains(r['userId'] ?? r['ownerId'])).toList();

    return MockResponse.ok({
      'punches': filter('punches'),
      'visits': filter('visits'),
      'orders': filter('orders'),
      'users': collection('users')
          .where((u) => ids.contains(u['reportsToId']))
          .toList(),
      'allUsers': collection('users'),
    });
  }

  // ------------------------------------------------------------ helpers ---
  Map<String, dynamic>? _findById(String name, String id) {
    final list = _collections[name];
    if (list == null) return null;
    for (final item in list) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  void _upsert(String name, Map<String, dynamic> item) {
    final list = _collections[name];
    if (list == null) return;
    final id = item['id'];
    list.removeWhere((existing) => existing['id'] == id);
    list.add(item);
  }
}

class MockResponse {
  MockResponse(this.statusCode, this.data);
  final int statusCode;
  final dynamic data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  MockResponse.ok(dynamic data) : this(200, data);
  MockResponse.error(int code, String message) : this(code, {'detail': message});

  Response toResponse(RequestOptions options) => Response(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}
