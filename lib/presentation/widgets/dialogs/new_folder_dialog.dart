import 'package:flutter/material.dart';

class NewFolderDialog extends StatefulWidget {
  final Function(String) onCreateFolder;

  const NewFolderDialog({super.key, required this.onCreateFolder});

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<NewFolderDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(188, 0, 0, 0),
      title: const Text('New Folder', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Folder name',
          hintStyle: TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF007AFF)),
          ),
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onCreateFolder(value);
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onCreateFolder(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Create', style: TextStyle(color: Color(0xFF007AFF))),
        ),
      ],
    );
  }
}