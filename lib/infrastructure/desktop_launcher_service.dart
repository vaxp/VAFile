import 'dart:io';
import 'desktop_file_parser.dart';

class DesktopLauncherService {
  /// Launch a .desktop file application directly
  static Future<void> launch(String desktopFilePath) async {
    try {
      final entry = await DesktopFileParser.parse(desktopFilePath);
      
      if (entry == null) {
        throw Exception('Invalid desktop file or missing required fields');
      }

      final command = DesktopFileParser.extractCommand(entry.exec ?? '');
      
      if (command.isEmpty) {
        throw Exception('No executable command found in desktop file');
      }

      // Parse the command (handle quotes and spaces properly)
      final parts = _parseCommand(command);
      final executable = parts[0];
      final args = parts.sublist(1);

      // Check if executable exists
      final result = await Process.run('which', [executable]);
      if (result.exitCode != 0) {
        throw Exception('Application executable not found: $executable');
      }

      // Launch the application
      await Process.start(
        executable,
        args,
        mode: ProcessStartMode.detached,
      );
    } catch (e) {
      rethrow;
    }
  }

  static List<String> _parseCommand(String command) {
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
}
