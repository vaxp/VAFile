import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:mime/mime.dart';

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
        imageProvider: FileImage(File(filePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

class VideoViewer extends StatefulWidget {
  final String filePath;

  const VideoViewer({super.key, required this.filePath});

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  Process? _process;

  @override
  void initState() {
    super.initState();
    _playVideo();
  }

  Future<void> _playVideo() async {
    try {
      _process = await Process.start('mpv', [widget.filePath]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _process?.kill();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // ignore: deprecated_member_use
          backgroundColor: Colors.black.withOpacity(0.7),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _process?.kill();
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            'Video is playing in MPV...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _process?.kill();
    super.dispose();
  }
}

class AudioViewer extends StatefulWidget {
  final String filePath;

  const AudioViewer({super.key, required this.filePath});

  @override
  State<AudioViewer> createState() => _AudioViewerState();
}

class _AudioViewerState extends State<AudioViewer> {
  Process? _process;

  @override
  void initState() {
    super.initState();
    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      _process = await Process.start('mpv', [widget.filePath]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _process?.kill();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // ignore: deprecated_member_use
          backgroundColor: Colors.black.withOpacity(0.7),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _process?.kill();
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            'Audio is playing in MPV...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _process?.kill();
    super.dispose();
  }
}