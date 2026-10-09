import 'dart:convert';

import 'package:hive/hive.dart';

/// Thin JSON-over-Hive wrapper.
///
/// Records are stored as JSON strings inside a `Box<String>` which keeps the
/// schema flexible (no `TypeAdapter` codegen / `build_runner` step) while
/// remaining fully offline-capable. Every box has the same tiny surface area,
/// so repositories stay uniform.
class JsonBox {
  JsonBox(this._box);

  final Box<String> _box;

  String get name => _box.name;

  bool contains(String key) => _box.containsKey(key);

  Future<void> put(String key, Map<String, dynamic> value) =>
      _box.put(key, jsonEncode(value));

  Map<String, dynamic>? get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();

  /// All records, decoded. [orderBy] lets repositories keep a stable order
  /// without leaking Hive specifics.
  List<Map<String, dynamic>> all({int Function(Map<String, dynamic> a, Map<String, dynamic> b)? orderBy}) {
    final items = _box.values
        .map((raw) {
          final decoded = jsonDecode(raw);
          return decoded is Map<String, dynamic> ? decoded : null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    if (orderBy != null) items.sort(orderBy);
    return items;
  }

  int get length => _box.length;
}
