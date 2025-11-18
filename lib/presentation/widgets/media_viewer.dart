import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'video_player_widget.dart';

class MediaViewer extends StatelessWidget {
  final String filePath;

  const MediaViewer({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final String? mimeType = lookupMimeType(filePath);

    if (mimeType?.startsWith('image/') ?? false) {
      return ImageViewer(filePath: filePath);
    } else if (mimeType?.startsWith('video/') ?? false) {
      return VideoViewer(filePath: filePath);
    } else if (mimeType?.startsWith('audio/') ?? false) {
      return AudioViewer(filePath: filePath);
    } else {
      return const Center(child: Text('Unsupported media type'));
    }
  }
}

class ImageViewer extends StatelessWidget {
  final String filePath;

  const ImageViewer({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    
    // Check if file exists and is not empty
    if (!file.existsSync()) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // ignore: deprecated_member_use
          backgroundColor: Colors.black.withOpacity(0.7),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'File not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // ignore: deprecated_member_use
          backgroundColor: Colors.black.withOpacity(0.7),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Image file is empty and cannot be displayed',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ignore: deprecated_member_use
        backgroundColor: Colors.black.withOpacity(0.7),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: FileImage(file),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
        loadingBuilder: (context, event) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}

class VideoViewer extends StatelessWidget {
  final String filePath;

  const VideoViewer({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final videoName = p.basename(filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ignore: deprecated_member_use
        backgroundColor: Colors.black.withOpacity(0.7),
        title: Text(videoName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VideoPlayerWidget(
        videoPath: filePath,
        videoName: videoName,
      ),
    );
  }
}

class AudioViewer extends StatelessWidget {
  final String filePath;

  const AudioViewer({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final audioName = p.basename(filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ignore: deprecated_member_use
        backgroundColor: Colors.black.withOpacity(0.7),
        title: Text(audioName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VideoPlayerWidget(
        
        videoPath: filePath,
        videoName: audioName,
      ),
    );
  }
}