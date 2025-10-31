import 'dart:io';
import 'package:flutter/material.dart';

class DebInstallerDialog extends StatefulWidget {
  final String debFilePath;

  const DebInstallerDialog({super.key, required this.debFilePath});

  @override
  State<DebInstallerDialog> createState() => _DebInstallerDialogState();
}

class _DebInstallerDialogState extends State<DebInstallerDialog> {
  bool _installing = false;
  String _output = '';
  bool _done = false;
  bool _error = false;

  Future<void> _installDeb() async {
    setState(() {
      _installing = true;
      _output = 'Installing...';
      _done = false;
      _error = false;
    });
    try {
      // Install the .deb file
      final install = await Process.run('pkexec', ['apt', 'install', '-y', widget.debFilePath]);
      String result = install.stdout.toString() + install.stderr.toString();
      if (install.exitCode != 0 && result.contains('dependency')) {
        // Try to fix dependencies
        final fix = await Process.run('pkexec', ['apt-get', '-f', 'install', '-y']);
        result += '\n${fix.stdout}${fix.stderr}';
        if (fix.exitCode == 0) {
          setState(() {
            _output = '$result\nDependencies resolved.';
            _done = true;
            _error = false;
          });
          return;
        }
      }
      setState(() {
        _output = result;
        _done = install.exitCode == 0;
        _error = install.exitCode != 0;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
        _done = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: const Text('Install .deb Package', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to install this application?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Text(widget.debFilePath, style: const TextStyle(color: Colors.white54)),
            if (_installing || _done || _error) ...[
              const SizedBox(height: 16),
              Text(_output, style: TextStyle(color: _error ? Colors.red : Colors.green, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        if (!_installing && !_done)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        if (!_installing && !_done)
          TextButton(
            onPressed: _installDeb,
            child: const Text('Install', style: TextStyle(color: Color(0xFF007AFF))),
          ),
        if (_done || _error)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }
}
