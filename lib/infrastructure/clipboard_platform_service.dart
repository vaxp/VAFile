import 'dart:io';
import 'package:flutter/services.dart';

/// Platform service for setting clipboard with file URIs on Linux
/// Uses GTK clipboard with text/uri-list MIME type
class ClipboardPlatformService {
  static const MethodChannel _channel = MethodChannel('vafile/clipboard');

  /// Set file URIs in system clipboard (text/uri-list format)
  static Future<void> setFileUris(List<String> filePaths) async {
    if (!Platform.isLinux) {
      return;
    }

    try {
      await _channel.invokeMethod('setFileUris', {'paths': filePaths});
    } catch (e) {
      print('Error setting clipboard file URIs: $e');
      rethrow;
    }
  }
}

