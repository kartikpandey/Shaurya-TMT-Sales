import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 password hashing for the offline credential store.
///
/// The real backend owns credential verification; this keeps locally cached
/// demo/seeded accounts from holding plaintext passwords in Hive.
class PasswordHasher {
  const PasswordHasher._();

  static String hash(String password, {String salt = 'shaurya-tmt'}) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  static bool matches(String password, String storedHash) =>
      storedHash.isNotEmpty && storedHash == hash(password);
}
