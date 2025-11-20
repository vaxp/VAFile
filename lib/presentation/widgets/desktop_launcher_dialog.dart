import 'package:flutter/material.dart';
import 'dart:io';
import '../../infrastructure/desktop_file_parser.dart';

class DesktopLauncherDialog extends StatefulWidget {
  final String desktopFilePath;
  final VoidCallback? onLaunchSuccess;
  final VoidCallback? onLaunchError;

  const DesktopLauncherDialog({
    super.key,
    required this.desktopFilePath,
    this.onLaunchSuccess,
    this.onLaunchError,
  });

  @override
  State<DesktopLauncherDialog> createState() => _DesktopLauncherDialogState();
}

class _DesktopLauncherDialogState extends State<DesktopLauncherDialog> {
  late Future<DesktopFileEntry?> _parseFuture;

  @override
  void initState() {
    super.initState();
    _parseFuture = DesktopFileParser.parse(widget.desktopFilePath);
  }

  Future<void> _launchApplication(DesktopFileEntry entry) async {
    try {
      final command = DesktopFileParser.extractCommand(entry.exec ?? '');
      
      if (command.isEmpty) {
        _showError('No executable command found in desktop file');
        return;
      }

      // Parse the command (handle quotes and spaces properly)
      final parts = _parseCommand(command);
      final executable = parts[0];
      final args = parts.sublist(1);

      // Check if executable exists
      final result = await Process.run('which', [executable]);
      if (result.exitCode != 0) {
        _showError('Application executable not found: $executable');
        return;
      }

      // Launch the application
      await Process.start(
        executable,
        args,
        mode: ProcessStartMode.detached,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onLaunchSuccess?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launched: ${entry.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to launch application: $e');
      widget.onLaunchError?.call();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  List<String> _parseCommand(String command) {
    final parts = <String>[];
    var current = '';
    bool inQuotes = false;

    for (int i = 0; i < command.length; i++) {
      final char = command[i];

      if (char == '"' || char == "'") {
        inQuotes = !inQuotes;
      } else if (char == ' ' && !inQuotes) {
        if (current.isNotEmpty) {
          parts.add(current);
          current = '';
        }
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      parts.add(current);
    }

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DesktopFileEntry?>(
      future: _parseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(100, 0, 0, 0),
            title: const Text(
              'Loading Application',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 16),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Reading application details...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(100, 0, 0, 0),
            title: const Text(
              'Invalid Application File',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              'Could not read the application file: ${snapshot.error ?? 'Unknown error'}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          );
        }

        final entry = snapshot.data!;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(100, 0, 0, 0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Launch Application?',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                entry.name,
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.comment != null && entry.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    entry.comment!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DesktopFileParser.extractCommand(entry.exec ?? ''),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Courier New',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (entry.categories != null && entry.categories!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Categories: ${entry.categories!.join(', ')}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
              if (entry.terminal) ...[
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.terminal, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Runs in terminal',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => _launchApplication(entry),
              child: const Text(
                'Launch',
                style: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
          ],
        );
      },
    );
  }
}
