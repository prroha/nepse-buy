import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/core/security/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('hash is deterministic for same (pin, salt)', () {
      const salt = 'fixedsaltforthistest';
      expect(PinHasher.hash('1234', salt), PinHasher.hash('1234', salt));
    });

    test('different salts produce different hashes for same pin', () {
      final a = PinHasher.hash('1234', 'salt-a');
      final b = PinHasher.hash('1234', 'salt-b');
      expect(a, isNot(equals(b)));
    });

    test('different pins produce different hashes for same salt', () {
      const salt = 'shared';
      expect(PinHasher.hash('1234', salt),
          isNot(equals(PinHasher.hash('5678', salt))));
    });

    test('generateSalt returns 16 random bytes (base64)', () {
      final a = PinHasher.generateSalt();
      final b = PinHasher.generateSalt();
      expect(a, isNot(equals(b)));
      // base64 of 16 bytes = 24 chars (with =-padding).
      expect(a.length, 24);
    });

    test('constantTimeEquals matches identical strings, rejects others', () {
      expect(PinHasher.constantTimeEquals('abc', 'abc'), isTrue);
      expect(PinHasher.constantTimeEquals('abc', 'abd'), isFalse);
      expect(PinHasher.constantTimeEquals('abc', 'abcd'), isFalse);
    });
  });
}
