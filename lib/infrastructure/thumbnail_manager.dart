import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailManager {
  static const double THUMBNAIL_SIZE = 128;
  static const int THUMBNAIL_QUALITY = 50;

  final Map<String, ImageProvider> cache = {};
  final Map<String, Future<void>> _loadingTasks = {};
  
  // Track failed video thumbnail attempts to avoid retry spam
  final Set<String> _failedVideoThumbnails = {};

  /// Load thumbnail for a file
  /// Call this during widget build to trigger async thumbnail generation
  Future<void> loadThumbnail(String path, String filename) async {
    // Skip if already cached or currently loading
    if (cache.containsKey(filename) || _loadingTasks.containsKey(filename)) {
      return;
    }

    // Start async generation task and track it
    _loadingTasks[filename] = _generate(path, filename).whenComplete(() {
      _loadingTasks.remove(filename);
    });
  }

  /// Generate thumbnail based on file type
  Future<void> _generate(String path, String filename) async {
    final ext = p.extension(path).toLowerCase();
    ImageProvider? provider;

    try {
      // Handle image files
      if (_isImageFile(ext)) {
        provider = _generateImageThumbnail(path);
      }
      // Handle video files
      else if (_isVideoFile(ext)) {
        // Skip if we already tried and failed for this video
        if (_failedVideoThumbnails.contains(filename)) {
          return;
        }
        provider = await _generateVideoThumbnail(path, filename);
      }

      // Update cache if successful
      if (provider != null) {
        cache[filename] = provider;
      }
    } catch (e) {
      // Silently fail - will fallback to icon
      print('Thumbnail generation failed for $filename: $e');
    }
  }

  /// Generate thumbnail for image file
  ImageProvider? _generateImageThumbnail(String path) {
    try {
      final file = File(path);
      
      // Check if file exists
      if (!file.existsSync()) {
        return null;
      }
      
      // Check if file is empty
      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        print('Image file is empty: $path');
        return null;
      }
      
      return ResizeImage(
        FileImage(file),
        width: THUMBNAIL_SIZE.toInt(),
        policy: ResizeImagePolicy.fit,
      );
    } catch (e) {
      print('Image thumbnail failed for $path: $e');
      return null;
    }
  }

  /// Generate thumbnail for video file with enhanced error handling
  Future<ImageProvider?> _generateVideoThumbnail(String path, String filename) async {
    try {
      // Check if file exists and is readable
      final file = File(path);
      if (!file.existsSync()) {
        _failedVideoThumbnails.add(filename);
        return null;
      }

      // Get file size to ensure it's a valid video file
      final fileSize = await file.length();
      if (fileSize < 1024) {  // Less than 1KB - likely invalid
        _failedVideoThumbnails.add(filename);
        return null;
      }

      try {
        // Attempt to extract thumbnail via plugin
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: THUMBNAIL_SIZE.toInt(),
          quality: THUMBNAIL_QUALITY,
          timeMs: 500, // 500ms into video
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Video thumbnail timeout for $filename');
            return null;
          },
        );

        if (thumbPath != null && thumbPath.isNotEmpty) {
          final thumbFile = File(thumbPath);
          if (thumbFile.existsSync()) {
            return ResizeImage(
              FileImage(thumbFile),
              width: THUMBNAIL_SIZE.toInt(),
              policy: ResizeImagePolicy.fit,
            );
          }
        }
      } on MissingPluginException catch (e) {
        // video_thumbnail plugin not available on this platform
        print('VideoThumbnail plugin not available: $e');
        // fall through to ffmpeg fallback below
      } catch (e) {
        // Any other error from the plugin - log and fall through to fallback
        print('video_thumbnail plugin error for $filename: $e');
      }

      // If plugin failed or unavailable, attempt ffmpeg / ffmpegthumbnailer fallback (Linux/desktop)
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        try {
          // Prefer ffmpeg (widely available). Build a safe temp path.
          final base = p.basenameWithoutExtension(filename).replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
          final tmpDir = Directory.systemTemp;
          final outName = '${base}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final outPath = p.join(tmpDir.path, outName);

          // Try ffmpeg first
          final ffmpegResult = await Process.run('ffmpeg', [
            '-ss', '00:00:00.500',
            '-i', path,
            '-frames:v', '1',
            '-q:v', '2',
            '-y',
            outPath,
          ]).timeout(const Duration(seconds: 8), onTimeout: () => ProcessResult(0, 1, '', 'timeout'));

          if (ffmpegResult.exitCode == 0 && File(outPath).existsSync()) {
            return ResizeImage(
              FileImage(File(outPath)),
              width: THUMBNAIL_SIZE.toInt(),
              policy: ResizeImagePolicy.fit,
            );
          }

          // If ffmpeg failed, try ffmpegthumbnailer (if installed)
          ProcessResult? ffthumb;
          try {
            ffthumb = await Process.run('ffmpegthumbnailer', ['-i', path, '-o', outPath, '-s', THUMBNAIL_SIZE.toInt().toString(), '-q', '10']).timeout(const Duration(seconds: 6));
          } catch (_) {
            ffthumb = null;
          }
          if (ffthumb != null && ffthumb.exitCode == 0 && File(outPath).existsSync()) {
            return ResizeImage(
              FileImage(File(outPath)),
              width: THUMBNAIL_SIZE.toInt(),
              policy: ResizeImagePolicy.fit,
            );
          }
        } catch (e) {
          print('ffmpeg/ffmpegthumbnailer fallback failed for $filename: $e');
        }
      }

      // Mark as failed to prevent retry
      _failedVideoThumbnails.add(filename);
      return null;
    } catch (e) {
      print('Video thumbnail error for $filename: $e');
      _failedVideoThumbnails.add(filename);
      return null;
    }
  }

  /// Check if file extension is an image format
  bool _isImageFile(String ext) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  /// Check if file extension is a video format
  bool _isVideoFile(String ext) {
    return ['.mp4', '.mkv', '.avi', '.mov', '.webm'].contains(ext);
  }

  /// Get cached thumbnail or null if not available
  ImageProvider? getThumbnail(String filename) {
    return cache[filename];
  }

  /// Clear all cached thumbnails
  void clearCache() {
    cache.clear();
    _failedVideoThumbnails.clear();
  }

  /// Check if a thumbnail is currently being loaded
  bool isLoading(String filename) {
    return _loadingTasks.containsKey(filename);
  }

  /// Get the number of cached thumbnails
  int getCacheSize() {
    return cache.length;
  }
}

