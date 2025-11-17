import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class TextEditorPage extends StatefulWidget {
  final String filePath;

  const TextEditorPage({
    super.key,
    required this.filePath,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late TextEditingController _controller;
  late File _file;
  bool _isModified = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _file = File(widget.filePath);
    _controller = TextEditingController();
    _loadFile();
    _controller.addListener(_onContentChanged);
  }

  Future<void> _loadFile() async {
    try {
      final content = await _file.readAsString();
      setState(() {
        _controller.text = content;
        _isModified = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading file: $e')),
        );
      }
    }
  }

  void _onContentChanged() {
    setState(() {
      _isModified = true;
    });
  }

  Future<void> _saveFile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _file.writeAsString(_controller.text);
      setState(() {
        _isModified = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.filePath);

    return WillPopScope(
      onWillPop: () async {
        if (_isModified) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(188, 0, 0, 0),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.filePath,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isModified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: Text(
                    'Modified',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                _isSaving ? Icons.hourglass_bottom : Icons.save,
                color: _isSaving ? Colors.white54 : Colors.white70,
              ),
              tooltip: 'Save',
              onPressed: _isSaving ? null : (_isModified ? _saveFile : null),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: 'Close',
              onPressed: () async {
                if (_isModified) {
                  final shouldClose = await _showUnsavedChangesDialog();
                  if (shouldClose && mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF404040),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Line ${_getLineNumber()}, Column ${_getColumnNumber()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getFileSize(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Courier New',
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF404040),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF404040),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(188, 0, 0, 0),
                    hintText: 'Start typing...',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getLineNumber() {
    final text = _controller.text;
    final cursorPosition = _controller.selection.start;
    int lineNumber = 1;
    for (int i = 0; i < cursorPosition && i < text.length; i++) {
      if (text[i] == '\n') {
        lineNumber++;
      }
    }
    return lineNumber;
  }

  int _getColumnNumber() {
    final text = _controller.text;
    final cursorPosition = _controller.selection.start;
    int columnNumber = 1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '\n') {
        break;
      }
      columnNumber++;
    }
    return columnNumber;
  }

  String _getFileSize() {
    final bytes = _controller.text.length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(188, 0, 0, 0),
            title: const Text(
              'Unsaved Changes',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Do you want to save changes to ${p.basename(widget.filePath)}?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _saveFile();
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
