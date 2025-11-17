import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final String videoName;

  const VideoPlayerWidget({
    required this.videoPath,
    required this.videoName,
    super.key,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  Player? player;
  VideoController? controller;
  StreamSubscription<bool>? _completedSubscription;
  bool isRestarting = false;
  late AnimationController fadeController;


  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );


    _initPlayer();
  }



  Future<void> _initPlayer() async {
    try {

      print('Initializing player with hwdec=auto-safe');
      player = Player(
        configuration: PlayerConfiguration(
          bufferSize: 1024 * 1024, // 1MB for local playback
        ),
      );
      // -----------------------------------------------------------


      controller = VideoController(player!);

      // STEP 3: Configure playback
      await player!.setVolume(0); // Mute audio
      await player!.setPlaylistMode(PlaylistMode.none); // Manual loop control

      // STEP 4: Load and play (with timeout and fallback)
      try {
        // Give the open operation a reasonable timeout so it doesn't hang indefinitely
        await player!
            .open(Media(widget.videoPath), play: true)
            .timeout(const Duration(seconds: 10));
        
        fadeController.forward();

      } on TimeoutException catch (e) {
        print('player.open timed out for ${widget.videoName}: $e');
        try {
          await player!
              .open(Media(widget.videoPath), play: false)
              .timeout(const Duration(seconds: 10));
          await player!.play();
          
          fadeController.forward();

        } catch (e2) {
          print('Fallback open/play failed for ${widget.videoName}: $e2');
          await _hardRestart();
          return;
        }
      }

      // STEP 5: Setup loop trigger
      _completedSubscription = player!.stream.completed.listen((
        isCompleted,
      ) async {
        if (isCompleted && mounted && !isRestarting) {
          await _restartSmooth();
        }
      });

      // STEP 6: Render UI
      // (ملاحظة: fadeController.forward() تم نقله لأعلى)
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Smooth looping with fade transition
  Future<void> _restartSmooth() async {
    if (player == null || isRestarting) return;
    isRestarting = true;

    try {
      // STEP 1: Fade out (400ms)
      await fadeController.reverse();

      // STEP 2: Pause and seek
      await player!.pause();
      await player!.seek(const Duration(milliseconds: 100));

      // STEP 3: Resume and fade in (400ms)
      await player!.play();
      await fadeController.forward();
    } catch (e) {
      print('Error in smooth restart: $e');
      // Fallback to hard restart if smooth fails
      await _hardRestart();
    }

    isRestarting = false;
  }

  /// Hard restart as fallback
  Future<void> _hardRestart() async {
    try {
      // Complete cleanup
      await player?.dispose();
      player = null;
      controller = null;
      if (mounted) {
        setState(() {});
      }

      // Delay for system cleanup
      await Future.delayed(const Duration(milliseconds: 100));

      // Full reinitialization
      if (mounted) await _initPlayer();
    } catch (e) {
      print('Error in hard restart: $e');
      // Silent failure prevents cascading errors
    }
  }

  @override
  void dispose() {
    _completedSubscription?.cancel();
    fadeController.dispose();
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Can't render if player not ready
    if (player == null || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Render video with fade animation
    return FadeTransition(
      opacity: fadeController,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1280,
            height: 720,
            child: Video(
              controller: controller!,
              controls: AdaptiveVideoControls,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}