import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // Configure image cache for thumbnail display
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // 50 MB
  PaintingBinding.instance.imageCache.maximumSize = 100;

  runApp(const FileManagerApp());
}