import 'dart:io';
import 'package:flutter/services.dart';
import 'clipboard_platform_service.dart';

enum ClipboardOperation { copy, cut }

class ClipboardService {
  ClipboardService._privateConstructor();
  static final ClipboardService instance = ClipboardService._privateConstructor();

  List<String> _paths = [];
  ClipboardOperation? _operation;

  /// Set copy operation - stores in both internal state and system clipboard
  Future<void> setCopy(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    
    _paths = List.from(paths);
    _operation = ClipboardOperation.copy;
    
    // Store in system clipboard as text/uri-list for external applications
    if (Platform.isLinux && paths.isNotEmpty) {
      try {
        await ClipboardPlatformService.setFileUris(paths);
      } catch (e) {
        // Silently fail - internal state is still set for app-internal paste
      }
    }
  }

  /// Set cut operation - stores in both internal state and system clipboard
  Future<void> setCut(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    
    _paths = List.from(paths);
    _operation = ClipboardOperation.cut;
    
    // Store in system clipboard as text/uri-list for external applications
    if (Platform.isLinux && paths.isNotEmpty) {
      try {
        await ClipboardPlatformService.setFileUris(paths);
      } catch (e) {
        // Silently fail - internal state is still set for app-internal paste
      }
    }
  }

  void clear() {
    _paths = [];
    _operation = null;
    // Note: We don't clear system clipboard here as other apps might be using it
  }

  bool get hasItems => _paths.isNotEmpty && _operation != null;

  ClipboardOperation? get operation => _operation;

  List<String> get paths => List.unmodifiable(_paths);
  
  /// Check if system clipboard contains file URIs
  Future<bool> hasSystemClipboardFiles() async {
    if (!Platform.isLinux) return false;
    
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        return false;
      }
      
      // Check if clipboard contains file:// URIs
      final text = data.text!;
      return text.contains('file://') || text.startsWith('/');
    } catch (e) {
      return false;
    }
  }
  
  /// Get file paths from system clipboard (if available)
  Future<List<String>?> getSystemClipboardPaths() async {
    if (!Platform.isLinux) return null;
    
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        return null;
      }
      
      final text = data.text!;
      final paths = <String>[];
      
      // Parse text/uri-list format (file:// URIs, one per line)
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        try {
          if (trimmed.startsWith('file://')) {
            // Parse file:// URI
            final uri = Uri.parse(trimmed);
            final path = uri.toFilePath();
            if (File(path).existsSync() || Directory(path).existsSync()) {
              paths.add(path);
            }
          } else if (trimmed.startsWith('/')) {
            // Direct absolute path
            if (File(trimmed).existsSync() || Directory(trimmed).existsSync()) {
              paths.add(trimmed);
            }
          }
        } catch (e) {
          // Skip invalid lines
          continue;
        }
      }
      
      return paths.isNotEmpty ? paths : null;
    } catch (e) {
      return null;
    }
  }
}
