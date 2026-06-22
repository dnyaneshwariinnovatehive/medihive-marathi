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

  /// Normalize phone number to 10 digits before sending to native side.
  /// Strips non-digits, removes leading 0 or 91 country code.
  static String _normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.length == 10 ? cleaned : '';
  }
}
