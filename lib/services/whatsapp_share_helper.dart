import 'dart:io';
import 'package:flutter/services.dart';

class WhatsAppShareHelper {
  static const _channel = MethodChannel('com.innovatehive.medihive/share');

  static Future<bool> shareToWhatsApp(File file, {String? phoneNumber}) async {
    try {
      await _channel.invokeMethod('shareToWhatsApp', {
        'filePath': file.path,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      });
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
