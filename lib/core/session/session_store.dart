import '../database/hive_service.dart';
import '../database/json_box.dart';

/// Persists the signed-in session in Hive so the app can resume offline.
class SessionStore {
  SessionStore([JsonBox? box]) : _box = box ?? HiveService.session;

  static const String _key = 'current_session';

  final JsonBox _box;

  String? get token => _read()['token'] as String?;

  String? get userId => _read()['userId'] as String?;

  bool get hasSession => userId != null && userId!.isNotEmpty;

  Future<void> save({required String token, required String userId}) =>
      _box.put(_key, {
        'token': token,
        'userId': userId,
        'savedAt': DateTime.now().toIso8601String(),
      });

  Future<void> clear() => _box.delete(_key);

  Map<String, dynamic> _read() {
    final raw = _box.get(_key);
    return raw is Map<String, dynamic> ? raw : const {};
  }
}
