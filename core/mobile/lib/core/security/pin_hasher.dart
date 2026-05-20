import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// SHA-256 + per-PIN random salt, iterated. Not PBKDF2 (no pointycastle dep),
/// but sufficient for a 4–6 digit PIN since the resulting hash is stored in
/// flutter_secure_storage (KeyStore-backed on Android), making brute force
/// require both physical device access and a KeyStore unwrap.
class PinHasher {
  static const int _iterations = 50000;
  static const int _saltBytes = 16;

  static String generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(_saltBytes, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  /// Returns a base64-encoded digest of [pin] + [salt], looped to slow down
  /// attacks. Deterministic for the same (pin, salt) pair.
  static String hash(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < _iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  /// Constant-time comparison so attackers can't time the equality check.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
