import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BackupCodeService {
  static const _storage = FlutterSecureStorage();
  static const _codesKey = 'backup_codes';
  static const _enabledKey = 'backup_enabled';

  /// Generates 10 random backup codes (format: ABCD-1234)
  static List<String> generateCodes() {
    final random = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(10, (_) {
      final part1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
      final part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
      return '$part1-$part2';
    });
  }

  static Future<void> enable2FA(List<String> codes) async {
    await _storage.write(key: _codesKey, value: jsonEncode(codes));
    await _storage.write(key: _enabledKey, value: 'true');
  }

  static Future<void> disable2FA() async {
    await _storage.delete(key: _codesKey);
    await _storage.delete(key: _enabledKey);
  }

  static Future<bool> is2FAEnabled() async {
    final val = await _storage.read(key: _enabledKey);
    return val == 'true';
  }

  static Future<List<String>?> getCodes() async {
    final raw = await _storage.read(key: _codesKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<String>();
  }

  /// Verifies [input] against stored codes. If valid, the used code is removed.
  /// Returns true if the code was valid and consumed.
  static Future<bool> verifyAndConsumeCode(String input) async {
    final codes = await getCodes();
    if (codes == null || codes.isEmpty) return false;

    final normalized = input.trim().toUpperCase();
    final matchIndex = codes.indexWhere((c) => c == normalized);
    if (matchIndex == -1) return false;

    codes.removeAt(matchIndex);
    if (codes.isEmpty) {
      await disable2FA();
    } else {
      await _storage.write(key: _codesKey, value: jsonEncode(codes));
    }
    return true;
  }

  /// Returns how many unused backup codes remain
  static Future<int> getRemainingCount() async {
    final codes = await getCodes();
    return codes?.length ?? 0;
  }
}
