import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WhatsAppShareHelper {
  static const _channel = MethodChannel('com.innovatehive.medihive/share');

  static Future<bool> shareToWhatsApp(File file, {String? phoneNumber}) async {
    try {
      final normalized = _normalizePhone(phoneNumber ?? '');
      debugPrint('WhatsAppShare: file=${file.path}, phone=$normalized');

      await _channel.invokeMethod('shareToWhatsApp', {
        'filePath': file.path,
        if (normalized.isNotEmpty) 'phoneNumber': normalized,
      });
      return true;
    } on MissingPluginException catch (e) {
      debugPrint('WhatsAppShare: MissingPluginException - $e');
      return false;
    } catch (e) {
      debugPrint('WhatsAppShare: Error - $e');
      return false;
    }
  }

  /// Normalize phone number to include country code before sending to native side.
  /// Strips non-digits, ensures "91" prefix for 10-digit numbers.
  /// Passes through numbers that already have country codes intact.
  static String _normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '91$cleaned';
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      return cleaned;
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '91${cleaned.substring(1)}';
    } else if (cleaned.length > 10 && cleaned.length <= 15) {
      return cleaned;
    }
    return cleaned;
  }
}
