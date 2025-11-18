import 'package:flutter/services.dart';
import 'dart:io';

/// Service to handle external drag-and-drop (dragging files to desktop/other apps)
class ExternalDragService {
  static const MethodChannel _channel = MethodChannel('vafile/external_drag');

  /// Prepare file paths for external drag operation
  /// This stores the paths so GTK can provide them when drag-data-get is called
  /// GTK will detect when drag approaches window edge and take over
  static Future<void> startDrag(List<String> filePaths) async {
    if (!Platform.isLinux) {
      // Only supported on Linux for now
      return;
    }

    try {
      // Store the paths - GTK will retrieve them via drag-data-get callback
      await _channel.invokeMethod('startDrag', {'paths': filePaths});
    } catch (e) {
      print('Error preparing external drag: $e');
      // Silently fail - internal drag will still work
    }
  }

  /// Notify native code that Flutter drag has ended
  static Future<void> endDrag() async {
    if (!Platform.isLinux) {
      return;
    }

    try {
      await _channel.invokeMethod('endDrag');
    } catch (e) {
      // Silently fail
    }
  }
}

