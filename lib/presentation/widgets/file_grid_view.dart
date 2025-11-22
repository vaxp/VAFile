import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unnecessary_import
import 'package:flutter/gestures.dart';
// ignore: unnecessary_import
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../infrastructure/clipboard_service.dart';
import '../../infrastructure/file_manager_repository_impl.dart';
import '../../infrastructure/desktop_launcher_service.dart';
import '../../infrastructure/thumbnail_manager.dart';
import '../../infrastructure/external_drag_service.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../application/file_manager/file_manager_bloc.dart';
import '../../domain/vaxp.dart';
import 'media_viewer.dart';
import 'deb_installer_dialog.dart';
import 'text_editor.dart';

class FileGridView extends StatefulWidget {
  final ValueChanged<FileItem?>? onSelectionChanged;

  const FileGridView({super.key, this.onSelectionChanged});

  @override
  State<FileGridView> createState() => FileGridViewState();
}

class FileGridViewState extends State<FileGridView> {
  final ScrollController _scrollController = ScrollController();
  FileItem? _selectedFile;
  List<FileItem> _selectedFiles = [];
  late final ThumbnailManager _thumbnailManager;
  
  // Drag-to-select state
  Offset? _selectionStart;
  Offset? _selectionEnd;
  bool _isDragging = false;
  final Map<FileItem, GlobalKey> _fileItemKeys = {};
  static const double _dragThreshold = 5.0; // Minimum distance to start drag selection
  
  // Drag and drop state
  List<FileItem>? _draggedFiles; // Files currently being dragged

  @override
  void initState() {
    super.initState();
    _thumbnailManager = ThumbnailManager();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    // Set up keyboard shortcuts
    // ignore: deprecated_member_use
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  // ignore: deprecated_member_use
  void _handleKeyEvent(RawKeyEvent event) {
    // ignore: deprecated_member_use
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        _deleteSelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        _renameSelectedFile();
      } else if (event.logicalKey == LogicalKeyboardKey.keyC && 
                 // ignore: deprecated_member_use
                 event.isControlPressed) {
        _copySelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyX && 
                 // ignore: deprecated_member_use
                 event.isControlPressed) {
        _cutSelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyV && 
                 // ignore: deprecated_member_use
                 event.isControlPressed) {
        _pasteFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyA && 
                 // ignore: deprecated_member_use
                 event.isControlPressed) {
        _selectAllFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.enter && 
                 // ignore: deprecated_member_use
                 event.isAltPressed) {
        _showPropertiesForSelectedFile();
      }
    }
  }

  @override
  void dispose() {
    // ignore: deprecated_member_use
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _scrollController.dispose();
    _thumbnailManager.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileManagerBloc, FileManagerState>(
      buildWhen: (previous, current) {
        // Only rebuild if:
        // 1. State type changed (Loading -> Loaded, etc.)
        // 2. Files list length changed (indicates files were added/removed)
        // 3. View mode changed
        // 4. Current path changed (navigation occurred)
        if (previous is FileManagerLoaded && current is FileManagerLoaded) {
          return previous.filteredFiles.length != current.filteredFiles.length ||
                 previous.viewMode != current.viewMode ||
                 previous.currentPath != current.currentPath;
        }
        return previous != current;
      },
      builder: (context, state) {
        if (state is FileManagerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FileManagerError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is FileManagerLoaded) {
          // Clean up keys for files that no longer exist
          _fileItemKeys.removeWhere((file, _) => !state.filteredFiles.contains(file));
          
          switch (state.viewMode) {
            case ViewMode.grid:
              return _buildGridView(state);
            case ViewMode.list:
              return _buildListView(state);
            case ViewMode.gallery:
              return _buildGalleryView(state);
          }
        }
        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildGridView(FileManagerLoaded state) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isDragging) {
            _clearSelection();
          }
        },
      onPanStart: (details) {
        // Store the start position but don't start dragging yet
        _selectionStart = details.localPosition;
        _selectionEnd = details.localPosition;
      },
      onPanUpdate: (details) {
        if (_selectionStart != null) {
          final distance = (details.localPosition - _selectionStart!).distance;
          
          // Only start dragging if moved beyond threshold
          if (!_isDragging && distance > _dragThreshold) {
            setState(() {
              _isDragging = true;
              _selectionEnd = details.localPosition;
            });
          }
          
          if (_isDragging) {
            setState(() {
              _selectionEnd = details.localPosition;
              _updateSelectionFromRectangle(state);
            });
          }
        }
      },
      onPanEnd: (details) {
        // If we were dragging, keep the selection; otherwise clear it
        if (!_isDragging && _selectionStart != null) {
          // This was just a tap, clear selection
          _clearSelection();
        }
        setState(() {
          _isDragging = false;
          _selectionStart = null;
          _selectionEnd = null;
        });
      },
      onPanCancel: () {
        setState(() {
          _isDragging = false;
          _selectionStart = null;
          _selectionEnd = null;
        });
      },
      onSecondaryTapDown: (_) {
        if (!_isDragging) {
          _clearSelection();
        }
      },
      child: Stack(
        children: [
          GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 65,
              mainAxisSpacing: 65,
              childAspectRatio: 1.0,
            ),
            itemCount: state.filteredFiles.length,
            itemBuilder: (context, index) {
              final file = state.filteredFiles[index];
              final isSelected = _selectedFiles.contains(file);
              
              // Create or get key for this file item
              if (!_fileItemKeys.containsKey(file)) {
                _fileItemKeys[file] = GlobalKey();
              }
              
              return _buildFileItem(file, isSelected, key: _fileItemKeys[file]);
            },
          ),
          if (_isDragging && _selectionStart != null && _selectionEnd != null)
            _buildSelectionRectangle(),
        ],
      ),
    );
  }

  Widget _buildListView(FileManagerLoaded state) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _clearSelection(),
      onSecondaryTapDown: (_) => _clearSelection(),
      child: ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredFiles.length,
      itemBuilder: (context, index) {
        final file = state.filteredFiles[index];
        final isSelected = _selectedFiles.contains(file);
        
        return _buildListItem(file, isSelected);
      },
      ),
    );
  }



  Widget _buildGalleryView(FileManagerLoaded state) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _clearSelection(),
      onSecondaryTapDown: (_) => _clearSelection(),
      child: GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: state.filteredFiles.length,
      itemBuilder: (context, index) {
        final file = state.filteredFiles[index];
        final isSelected = _selectedFiles.contains(file);
        
        return _buildGalleryItem(file, isSelected);
      },
      ),
    );
  }



  void _showNewDocumentDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color.fromARGB(99, 0, 0, 0),
          title: const Text('New Document', style: TextStyle(color: Colors.white)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.c');
              },
              child: const Text('C Source (.c)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.cc');
              },
              child: const Text('C++ Source (.cc)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.py');
              },
              child: const Text('Python (.py)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.html');
              },
              child: const Text('HTML (.html)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.text');
              },
              child: const Text('Text (.text)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.pdf');
              },
              child: const Text('PDF (.pdf)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.md');
              },
              child: const Text('Markdown (.md)', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _createNewDocument('.dart');
              },
              child: const Text('Dart (.dart)', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewDocument(String extension) async {
    final state = context.read<FileManagerBloc>().state;
    if (state is! FileManagerLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to create file: directory not loaded')));
      return;
    }

    final dir = state.currentPath;
    final baseName = 'New Document';
    String filename = '$baseName$extension';
    int counter = 1;
    while (File(p.join(dir, filename)).existsSync()) {
      filename = '$baseName ($counter)$extension';
      counter++;
    }

    final templates = <String, String>{
      '.c': '''#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
''',
      '.cc': '''#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
''',
      '.py': '''#!/usr/bin/env python3

def main():
    print("Hello, World!")

if __name__ == '__main__':
    main()
''',
      '.html': '''<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New Document</title>
  </head>
  <body>
    <h1>Hello, World!</h1>
    <p>This is a new HTML document.</p>
  </body>
</html>
''',
      '.text': 'New text document\n',
      '.md': '# New Document\n\nCreate your content here.\n',
      '.dart': '''void main() {
  print('Hello, World!');
}
''',
      '.pdf': '%PDF-1.4\n%PDF placeholder generated by VAFile\n',
    };

    final content = templates[extension] ?? '';

    try {
      final filePath = p.join(dir, filename);
      final file = File(filePath);

      if (extension == '.pdf') {
        // Generate a real PDF using the pdf package
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build: (pw.Context ctx) => pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('New Document', style: pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 12),
                  pw.Text('This PDF was created by VAFile.'),
                ],
              ),
            ),
          ),
        );
        final bytes = await doc.save();
        await file.writeAsBytes(bytes, flush: true);
      } else {
        await file.writeAsString(content);
      }

      // Refresh the file list
      // ignore: use_build_context_synchronously
      context.read<FileManagerBloc>().add(RefreshFileManager());

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created $filename')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating file: $e')));
    }
  }

  void _openTerminalAtCurrentPath() {
    final state = context.read<FileManagerBloc>().state;
    if (state is! FileManagerLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Directory not loaded')));
      return;
    }
    _openTerminalAt(state.currentPath);
  }

  void _openTerminalAt(String path) async {
    final terminals = {
      'gnome-terminal': (String p) => ['--', 'bash', '-c', 'cd "${p.replaceAll("\"", '\\"')}"; exec bash'],
      'konsole': (String p) => ['--workdir', p],
      'xfce4-terminal': (String p) => ['--working-directory', p],
      'alacritty': (String p) => ['--working-directory', p],
      'kitty': (String p) => ['--directory', p],
      'xterm': (String p) => ['-e', 'bash', '-c', 'cd "${p.replaceAll("\"", '\\"')}"; exec bash'],
      'terminator': (String p) => ['--working-directory', p],
      'lxterminal': (String p) => ['-e', 'bash', '-c', 'cd "${p.replaceAll("\"", '\\"')}"; exec bash'],
    };

    String? found;
    List<String>? args;
    for (final cmd in terminals.keys) {
      try {
        final which = await Process.run('which', [cmd]);
        if (which.exitCode == 0 && which.stdout.toString().trim().isNotEmpty) {
          found = cmd;
          args = terminals[cmd]!(path);
          break;
        }
      } catch (_) {}
    }

    if (found == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No terminal emulator found')));
      return;
    }

    try {
      await Process.start(found, args ?? [], mode: ProcessStartMode.detached);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open terminal: $e')));
    }
  }

  Future<void> _launchDesktopFile(FileItem file) async {
    try {
      await DesktopLauncherService.launch(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Launched: ${file.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to launch: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Widget _buildFileItem(FileItem file, bool isSelected, {Key? key}) {
    // Determine which files to drag (selected files if this one is selected, otherwise just this file)
    final filesToDrag = isSelected && _selectedFiles.isNotEmpty 
        ? _selectedFiles 
        : [file];
    
    // Check if this file is being dragged
    final isBeingDragged = _draggedFiles != null && _draggedFiles!.contains(file);
    
    // If it's a folder, make it a drop target; otherwise make it draggable
    if (file.isDirectory) {
      return _buildFolderItem(file, isSelected, filesToDrag, isBeingDragged, key: key);
    } else {
      return _buildDraggableFileItem(file, isSelected, filesToDrag, isBeingDragged, key: key);
    }
  }
  
  Widget _buildDraggableFileItem(FileItem file, bool isSelected, List<FileItem> filesToDrag, bool isBeingDragged, {Key? key}) {
    return Draggable<List<FileItem>>(
      key: key,
      data: filesToDrag,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF007AFF), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filesToDrag.length > 1 ? Icons.folder : Icons.insert_drive_file,
                  color: const Color(0xFF007AFF),
                  size: 32,
                ),
                if (filesToDrag.length > 1)
                  Text(
                    '${filesToDrag.length} items',
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFileItemContent(file, isSelected),
      ),
      onDragStarted: () {
        setState(() {
          _draggedFiles = filesToDrag;
        });
        // Also start external drag for system-level drag-and-drop
        final paths = filesToDrag.map((f) => f.path).toList();
        ExternalDragService.startDrag(paths);
      },
      onDragEnd: (details) {
        setState(() {
          _draggedFiles = null;
        });
        // Notify native code that Flutter drag has ended
        ExternalDragService.endDrag();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_isDragging && !isBeingDragged) {
            _onFileTap(file);
          }
        },
        onDoubleTap: () {
          if (!_isDragging && !isBeingDragged) {
            _openFile(file);
          }
        },
        onSecondaryTapDown: (_) {
          if (!_isDragging && !isBeingDragged) {
            _onFileTap(file);
          }
        },
        child: _buildFileItemContent(file, isSelected),
      ),
    );
  }
  
  Widget _buildFolderItem(FileItem folder, bool isSelected, List<FileItem> filesToDrag, bool isBeingDragged, {Key? key}) {
    final canAcceptDrop = _draggedFiles != null && 
                         _draggedFiles!.isNotEmpty &&
                         !_draggedFiles!.any((f) => f.path == folder.path || f.path.startsWith('${folder.path}/'));
    
    // Wrap folder in Draggable so it can be dragged into other folders
    return Draggable<List<FileItem>>(
      key: key,
      data: filesToDrag,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF007AFF), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder,
                  color: Color(0xFF007AFF),
                  size: 32,
                ),
                if (filesToDrag.length > 1)
                  Text(
                    '${filesToDrag.length} items',
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFolderDropTarget(folder, isSelected, canAcceptDrop),
      ),
      onDragStarted: () {
        setState(() {
          _draggedFiles = filesToDrag;
        });
        // Also start external drag for system-level drag-and-drop
        final paths = filesToDrag.map((f) => f.path).toList();
        ExternalDragService.startDrag(paths);
      },
      onDragEnd: (details) {
        setState(() {
          _draggedFiles = null;
        });
        // Notify native code that Flutter drag has ended
        ExternalDragService.endDrag();
      },
      child: _buildFolderDropTarget(folder, isSelected, canAcceptDrop),
    );
  }
  
  Widget _buildFolderDropTarget(FileItem folder, bool isSelected, bool canAcceptDrop) {
    final isBeingDragged = _draggedFiles != null && _draggedFiles!.contains(folder);
    
    // Recalculate canAcceptDrop based on current state
    final canAccept = _draggedFiles != null && 
                     _draggedFiles!.isNotEmpty &&
                     !_draggedFiles!.any((f) => f.path == folder.path || f.path.startsWith('${folder.path}/'));
    
    return DragTarget<List<FileItem>>(
      onWillAcceptWithDetails: (data) {
        // ignore: dead_code, unnecessary_null_comparison
        if (data == null) return false;
        // Don't allow dropping into the same folder or into a subfolder of dragged items
        return !data.data.any((f) => f.path == folder.path || f.path.startsWith('${folder.path}/'));
      },
      onAcceptWithDetails: (data) {
        _handleDrop(data.data, folder);
      },
      onLeave: (data) {
        // Folder is no longer a drop target
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty && canAccept;
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_isDragging && !isBeingDragged) {
              _onFileTap(folder);
            }
          },
          onDoubleTap: () {
            if (!_isDragging && !isBeingDragged) {
              _openFile(folder);
            }
          },
          onSecondaryTapDown: (_) {
            if (!_isDragging && !isBeingDragged) {
              _onFileTap(folder);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: isHighlighted 
                  ? const Color.fromARGB(255, 0, 255, 170).withOpacity(0.4)
                  : isSelected 
                      ? const Color.fromARGB(255, 0, 255, 170).withOpacity(0.2) 
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isHighlighted
                  ? Border.all(color: const Color.fromARGB(255, 0, 255, 170), width: 3)
                  : isSelected 
                      ? Border.all(color: const Color.fromARGB(255, 0, 255, 170), width: 2) 
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildFileIcon(folder),
                      if (isHighlighted)
                        const Icon(
                          Icons.file_download,
                          color: Color(0xFF007AFF),
                          size: 48,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isHighlighted || isSelected 
                            ? const Color.fromARGB(255, 0, 255, 170)
                            : Colors.white70,
                        fontWeight: isHighlighted || isSelected 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFileItemContent(FileItem file, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color.fromARGB(255, 0, 255, 170).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color.fromARGB(255, 0, 255, 170), width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _buildFileIcon(file),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                file.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color.fromARGB(255, 0, 255, 170) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleDrop(List<FileItem> files, FileItem targetFolder) {
    setState(() {
      _draggedFiles = null;
    });
    
    // Move each file to the target folder
    for (final file in files) {
      context.read<FileManagerBloc>().add(MoveFile(file, targetFolder.path));
    }
    
    // Clear selection after drop
    setState(() {
      _selectedFiles.clear();
      _selectedFile = null;
      widget.onSelectionChanged?.call(null);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved ${files.length} item${files.length > 1 ? 's' : ''} to ${targetFolder.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Gets the icon path for a folder based on its name
  /// Returns the matching icon path or 'icons/folder.svg' as default
  String _getFolderIconPath(String folderName) {
    final normalizedName = folderName.toLowerCase();
    return 'icons/cyan-folder-$normalizedName.svg';
  }

  /// Widget that tries to load a folder icon and falls back to default if not found
  Widget _buildFolderIcon(String folderName) {
    final iconPath = _getFolderIconPath(folderName);
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: _FolderIconWidget(
        iconPath: iconPath,
        fallbackPath: 'icons/folder.svg',
      ),
    );
  }

  Widget _buildFileIcon(FileItem file) {
    if (file.isDirectory) {
      // Use SVG icon for folders
      return _buildFolderIcon(file.name);
    }
    
    // Trigger thumbnail loading
    _thumbnailManager.loadThumbnail(file.path, file.name);
    
    // Get thumbnail if available
    final thumbnail = _thumbnailManager.getThumbnail(file.name);
    
    // For files, use Material icons as fallback
    IconData iconData;
    // Color iconColor;
    
    // Determine icon based on file extension
    switch (file.extension.toLowerCase()) {
      case '.txt':
      case '.text':
      case '.md':
      case '.rtf':
      case '.c':
      case '.cc':
      case '.dart':
      case '.py':
      case '.sh':
      case '.html':
      case '.js':
      case '.ts':
      case '.json':
      case '.yaml':
      case '.yml':
        iconData = Icons.description;
        // iconColor = Colors.white70;
        break;
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        // iconColor = Colors.red;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.svg':
      case '.webp':
        iconData = Icons.image;
        // iconColor = Colors.green;
        break;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
      case '.webm':
        iconData = Icons.videocam;
        // iconColor = Colors.purple;
        break;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
        iconData = Icons.music_note;
        // iconColor = Colors.orange;
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        // iconColor = Colors.brown;
        break;
      case '.exe':
      case '.app':
      case '.deb':
      case '.desktop':
        iconData = Icons.apps;
        // iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        // iconColor = Colors.white70;
    }

    return Container(
      width: 64,
      height: 64,
      // decoration: BoxDecoration(
      //   // ignore: deprecated_member_use
      //   // color: iconColor.withOpacity(0.1),
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(
      //     // ignore: deprecated_member_use
      //     // color: iconColor.withOpacity(0.3),
      //     width: 0,
      //   ),
      // ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: thumbnail != null
            ? Image(
                key: ValueKey('thumb-${file.name}'),
                image: thumbnail,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  // If image fails to load (e.g., empty or corrupted file), fallback to icon
                  return Icon(
                    iconData,
                    size: 32,
                    // color: iconColor,
                  );
                },
              )
            : Icon(
                key: ValueKey('icon-${file.name}'),
                iconData,
                size: 32,
                // color: iconColor,
              ),
      ),
    );
  }

  Widget _buildListItem(FileItem file, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color.fromARGB(255, 0, 255, 170).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isSelected ? Border.all(color: const Color.fromARGB(255, 0, 255, 170), width: 1) : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFileTap(file),
        onDoubleTap: () => _openFile(file),
        onSecondaryTapDown: (_) => _onFileTap(file),
        child: ListTile(
          leading: _buildFileIcon(file),
          title: Text(
            file.name,
            style: TextStyle(
              color: isSelected ? const Color.fromARGB(255, 0, 255, 170) : Colors.white70,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${_formatFileSize(file.size)} • ${file.modified.toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ),
    );
  }

 

  Widget _buildGalleryItem(FileItem file, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color.fromARGB(255, 0, 255, 170).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color.fromARGB(255, 0, 255, 170), width: 2) : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFileTap(file),
        onDoubleTap: () => _openFile(file),
        onSecondaryTapDown: (_) => _onFileTap(file),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(100, 0, 0, 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: file.isDirectory
                  ? _buildFileIcon(file)
                  : _buildPreviewThumbnail(file),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                file.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color.fromARGB(255, 0, 255, 170): Colors.white70,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),),
    );
  }

  Widget _buildPreviewThumbnail(FileItem file) {
    // For now, just show the file icon
    // In a real implementation, you would generate thumbnails for images/videos
    return _buildFileIcon(file);
  }

  void _onFileTap(FileItem file) {
    setState(() {
      _selectedFiles = [file];
      _selectedFile = file;
    });
    widget.onSelectionChanged?.call(file);
  }

  void _clearSelection() {
    setState(() {
      _selectedFiles.clear();
      _selectedFile = null;
    });
    widget.onSelectionChanged?.call(null);
  }

  void _renameFile(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => _RenameDialog(
        currentName: file.name,
        onRename: (newName) {
          context.read<FileManagerBloc>().add(RenameFile(file, newName));
        },
      ),
    );
  }

  void _showFileDetails(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(100, 0, 0, 0),
        title: Text('File Details', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file.name}', style: const TextStyle(color: Colors.white70)),
            Text('Path: ${file.path}', style: const TextStyle(color: Colors.white70)),
            Text('Type: ${file.isDirectory ? 'Folder' : 'File'}', style: const TextStyle(color: Colors.white70)),
            Text('Size: ${_formatFileSize(file.size)}', style: const TextStyle(color: Colors.white70)),
            Text('Modified: ${file.modified.toString().split('.')[0]}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Keyboard shortcut methods
  void _deleteSelectedFiles() {
    if (_selectedFiles.isNotEmpty) {
      for (final file in _selectedFiles) {
        context.read<FileManagerBloc>().add(DeleteFile(file));
      }
      _selectedFiles.clear();
    }
  }

  void _renameSelectedFile() {
    if (_selectedFile != null) {
      _renameFile(_selectedFile!);
    }
  }

  void _copySelectedFiles() {
    if (_selectedFiles.isNotEmpty) {
      ClipboardService.instance.setCopy(_selectedFiles.map((f) => f.path).toList()).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied selection to clipboard')));
        }
      });
    }
  }

  void _cutSelectedFiles() {
    if (_selectedFiles.isNotEmpty) {
      ClipboardService.instance.setCut(_selectedFiles.map((f) => f.path).toList()).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cut selection to clipboard')));
        }
      });
    }
  }

  void _pasteFiles() {
    final clip = ClipboardService.instance;
    if (!clip.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to paste')));
      return;
    }

    final state = context.read<FileManagerBloc>().state;
    if (state is! FileManagerLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Directory not loaded')));
      return;
    }

    final repo = FileManagerRepositoryImpl();
    final destination = state.currentPath;

    Future<void> doPaste() async {
      for (final pth in clip.paths) {
        try {
          final entity = FileSystemEntity.typeSync(pth);
          final stat = FileStat.statSync(pth);
          final isDir = entity == FileSystemEntityType.directory;
          final fileItem = FileItem(
            name: p.basename(pth),
            path: pth,
            isDirectory: isDir,
            size: stat.size,
            modified: stat.modified,
            extension: p.extension(pth),
          );

          if (clip.operation == ClipboardOperation.copy) {
            await repo.copyFile(fileItem, destination);
          } else if (clip.operation == ClipboardOperation.cut) {
            await repo.moveFile(fileItem, destination);
          }
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during paste: $e')));
        }
      }

      // If it was a cut, clear clipboard
      if (clip.operation == ClipboardOperation.cut) {
        clip.clear();
      }

      // ignore: use_build_context_synchronously
      context.read<FileManagerBloc>().add(RefreshFileManager());
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste completed')));
    }

    doPaste();
  }

  void _openFile(FileItem file) {
    // If called from context menu, close it
    if (ModalRoute.of(context)?.isCurrent == false) {
      Navigator.pop(context);
    }

    if (file.isDirectory) {
      context.read<FileManagerBloc>().add(LoadDirectory(file.path));
    } else {
      final extension = file.extension.toLowerCase();
      final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
      final isVideo = ['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(extension);
      final isAudio = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.opus'].contains(extension);
      final isText = ['.text', '.md', '.c', '.cc', '.dart', '.py', '.sh', '.txt', '.rtf', '.html', '.js', '.ts', '.json', '.yaml', '.yml'].contains(extension);
      final isDeb = extension == '.deb';
      final isDesktop = extension == '.desktop';

      if (isDeb) {
        showDialog(
          context: context,
          builder: (context) => DebInstallerDialog(debFilePath: file.path),
        );
      } else if (isDesktop) {
        _launchDesktopFile(file);
      } else if (isText) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextEditorPage(filePath: file.path),
          ),
        );
      } else if (isImage || isVideo || isAudio) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaViewer(filePath: file.path),
          ),
        );
      } else {
        // For other files, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${file.name}')),
        );
      }
    }
  }

  void _selectAllFiles() {
    final state = context.read<FileManagerBloc>().state;
    if (state is FileManagerLoaded) {
      setState(() {
        _selectedFiles = List.from(state.filteredFiles);
        if (_selectedFiles.isNotEmpty) {
          _selectedFile = _selectedFiles.first;
          widget.onSelectionChanged?.call(_selectedFile);
        } else {
          _selectedFile = null;
          widget.onSelectionChanged?.call(null);
        }
      });
    }
  }

  void _showPropertiesForSelectedFile() {
    if (_selectedFile != null) {
      _showFileDetails(_selectedFile!);
    }
  }

  Widget _buildSelectionRectangle() {
    if (_selectionStart == null || _selectionEnd == null) {
      return const SizedBox.shrink();
    }

    final left = _selectionStart!.dx < _selectionEnd!.dx ? _selectionStart!.dx : _selectionEnd!.dx;
    final top = _selectionStart!.dy < _selectionEnd!.dy ? _selectionStart!.dy : _selectionEnd!.dy;
    final right = _selectionStart!.dx > _selectionEnd!.dx ? _selectionStart!.dx : _selectionEnd!.dx;
    final bottom = _selectionStart!.dy > _selectionEnd!.dy ? _selectionStart!.dy : _selectionEnd!.dy;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: right - left,
        height: bottom - top,
        decoration: BoxDecoration(
          color: const Color.fromARGB(51, 0, 122, 255), // 0xFF007AFF with 20% opacity
          border: Border.all(
            color: const Color(0xFF007AFF),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void _updateSelectionFromRectangle(FileManagerLoaded state) {
    if (_selectionStart == null || _selectionEnd == null) {
      return;
    }

    final selectionRect = Rect.fromPoints(_selectionStart!, _selectionEnd!);
    final selectedFiles = <FileItem>[];

    // Calculate grid layout parameters
    final crossAxisCount = 4;
    final padding = 16.0;
    final crossAxisSpacing = 16.0;
    final mainAxisSpacing = 16.0;
    final childAspectRatio = 1.2;
    
    // Get available width (accounting for sidebar if needed)
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 200; // Subtract sidebar width
    
    // Calculate item dimensions
    final itemWidth = (availableWidth - padding * 2 - crossAxisSpacing * (crossAxisCount - 1)) / crossAxisCount;
    final itemHeight = itemWidth * childAspectRatio;
    
    // Get the GestureDetector's RenderBox for coordinate conversion
    final RenderBox? gestureBox = context.findRenderObject() as RenderBox?;
    if (gestureBox == null) return;
    
    for (int index = 0; index < state.filteredFiles.length; index++) {
      final file = state.filteredFiles[index];
      final key = _fileItemKeys[file];
      
      Rect? itemRect;
      
      // Try to get actual position from render box
      if (key?.currentContext != null) {
        final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          try {
            final globalPosition = renderBox.localToGlobal(Offset.zero);
            final localPosition = gestureBox.globalToLocal(globalPosition);
            final size = renderBox.size;
            
            itemRect = Rect.fromLTWH(
              localPosition.dx,
              localPosition.dy,
              size.width,
              size.height,
            );
          } catch (e) {
            // Fall through to calculated position
          }
        }
      }
      
      // Fallback: calculate position based on grid layout
      if (itemRect == null) {
        final row = index ~/ crossAxisCount;
        final col = index % crossAxisCount;
        
        final itemLeft = padding + col * (itemWidth + crossAxisSpacing);
        final itemTop = padding + row * (itemHeight + mainAxisSpacing) - _scrollController.offset;
        
        itemRect = Rect.fromLTWH(
          itemLeft,
          itemTop,
          itemWidth,
          itemHeight,
        );
      }
      
      // Check if selection rectangle intersects with item
      if (selectionRect.overlaps(itemRect) || 
          selectionRect.contains(itemRect.center) ||
          itemRect.overlaps(selectionRect)) {
        selectedFiles.add(file);
      }
    }

    setState(() {
      _selectedFiles = selectedFiles;
      if (selectedFiles.isNotEmpty) {
        _selectedFile = selectedFiles.first;
        widget.onSelectionChanged?.call(_selectedFile);
      } else {
        _selectedFile = null;
        widget.onSelectionChanged?.call(null);
      }
    });
  }

  FileItem? get selectedFile => _selectedFile;

  void renameSelection() => _renameSelectedFile();

  void copySelection() => _copySelectedFiles();

  void cutSelection() => _cutSelectedFiles();

  void pasteFromClipboard() => _pasteFiles();

  void showSelectionDetails() => _showPropertiesForSelectedFile();

  void openSelection() {
    if (_selectedFile != null) {
      _openFile(_selectedFile!);
    }
  }

  void deleteSelection() => _deleteSelectedFiles();

  void selectAllEntries() => _selectAllFiles();

  void openTerminalInCurrentDirectory() => _openTerminalAtCurrentPath();

  void createNewDocumentFromToolbar() => _showNewDocumentDialog();
}

/// Widget that loads a folder icon with fallback to default
class _FolderIconWidget extends StatefulWidget {
  final String iconPath;
  final String fallbackPath;

  const _FolderIconWidget({
    required this.iconPath,
    required this.fallbackPath,
  });

  @override
  State<_FolderIconWidget> createState() => _FolderIconWidgetState();
}

class _FolderIconWidgetState extends State<_FolderIconWidget> {
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.fallbackPath;
    _checkAssetExists();
  }

  Future<void> _checkAssetExists() async {
    try {
      // Try to load the asset to see if it exists
      await DefaultAssetBundle.of(context).load(widget.iconPath);
      if (mounted) {
        setState(() {
          _currentPath = widget.iconPath;
        });
      }
    } catch (e) {
      // Asset doesn't exist, use fallback
      if (mounted) {
        setState(() {
          _currentPath = widget.fallbackPath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _currentPath ?? widget.fallbackPath,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      semanticsLabel: 'Folder icon',
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onRename;

  const _RenameDialog({
    required this.currentName,
    required this.onRename,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(100, 0, 0, 0),
      title: const Text('Rename', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Enter new name',
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
            widget.onRename(value);
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
              widget.onRename(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Rename', style: TextStyle(color: Color(0xFF007AFF))),
        ),
      ],
    );
  }
}
