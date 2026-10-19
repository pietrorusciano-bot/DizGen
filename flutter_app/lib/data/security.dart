import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String generateSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64Url.encode(bytes);
}

String _digest(String salt, String password) {
  final bytes = utf8.encode('$salt:$password');
  return sha256.convert(bytes).toString();
}

String hashPassword(String password) {
  final salt = generateSalt();
  return '$salt:${_digest(salt, password)}';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split(':');
  if (parts.length != 2) return false;
  return _digest(parts[0], password) == parts[1];
}
