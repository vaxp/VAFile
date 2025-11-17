import 'dart:io';

class DesktopFileEntry {
  final String name;
  final String? exec;
  final String? icon;
  final String? comment;
  final String? type;
  final List<String>? categories;
  final bool terminal;
  final bool noDisplay;

  DesktopFileEntry({
    required this.name,
    this.exec,
    this.icon,
    this.comment,
    this.type,
    this.categories,
    this.terminal = false,
    this.noDisplay = false,
  });
}

class DesktopFileParser {
  /// Parse a .desktop file and extract relevant information
  static Future<DesktopFileEntry?> parse(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final lines = contents.split('\n');

      String? name;
      String? exec;
      String? icon;
      String? comment;
      String? type;
      List<String>? categories;
      bool terminal = false;
      bool noDisplay = false;

      bool inDesktopEntrySection = false;

      for (final line in lines) {
        final trimmed = line.trim();

        // Skip empty lines and comments
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }

        // Check for [Desktop Entry] section
        if (trimmed == '[Desktop Entry]') {
          inDesktopEntrySection = true;
          continue;
        }

        // Stop parsing if we reach another section
        if (trimmed.startsWith('[') && trimmed != '[Desktop Entry]') {
          break;
        }

        // Only parse lines in the Desktop Entry section
        if (!inDesktopEntrySection) {
          continue;
        }

        if (trimmed.contains('=')) {
          final parts = trimmed.split('=');
          if (parts.length < 2) continue;

          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();

          switch (key) {
            case 'Name':
              name = value;
              break;
            case 'Exec':
              exec = value;
              break;
            case 'Icon':
              icon = value;
              break;
            case 'Comment':
              comment = value;
              break;
            case 'Type':
              type = value;
              break;
            case 'Categories':
              categories = value.split(';').where((c) => c.isNotEmpty).toList();
              break;
            case 'Terminal':
              terminal = value.toLowerCase() == 'true';
              break;
            case 'NoDisplay':
              noDisplay = value.toLowerCase() == 'true';
              break;
          }
        }
      }

      // Return null if no name or exec is found
      if (name == null || exec == null) {
        return null;
      }

      return DesktopFileEntry(
        name: name,
        exec: exec,
        icon: icon,
        comment: comment,
        type: type,
        categories: categories,
        terminal: terminal,
        noDisplay: noDisplay,
      );
    } catch (e) {
      print('Error parsing desktop file: $e');
      return null;
    }
  }

  /// Extract command from Exec field (removes %f, %u, %F, %U placeholders)
  static String extractCommand(String exec) {
    // Remove common placeholders used in .desktop files
    String command = exec.replaceAll(RegExp(r'%[fFuUdDnN]'), '').trim();
    
    // Remove trailing quotes if any
    if (command.startsWith('"') && command.endsWith('"')) {
      command = command.substring(1, command.length - 1);
    }
    
    return command;
  }
}
