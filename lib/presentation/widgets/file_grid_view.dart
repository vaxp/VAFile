import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/clipboard_service.dart';
import '../../infrastructure/file_manager_repository_impl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../application/file_manager/file_manager_bloc.dart';
import '../../domain/vaxp.dart';
import 'context_menu.dart';
import 'dialogs/new_folder_dialog.dart';
import 'media_viewer.dart';
import 'deb_installer_dialog.dart';

class FileGridView extends StatefulWidget {
  const FileGridView({super.key});

  @override
  State<FileGridView> createState() => _FileGridViewState();
}

class _FileGridViewState extends State<FileGridView> {
  final ScrollController _scrollController = ScrollController();
  FileItem? _selectedFile;
  List<FileItem> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    // Set up keyboard shortcuts
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        _deleteSelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        _renameSelectedFile();
      } else if (event.logicalKey == LogicalKeyboardKey.keyC && 
                 event.isControlPressed) {
        _copySelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyX && 
                 event.isControlPressed) {
        _cutSelectedFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyV && 
                 event.isControlPressed) {
        _pasteFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.keyA && 
                 event.isControlPressed) {
        _selectAllFiles();
      } else if (event.logicalKey == LogicalKeyboardKey.enter && 
                 event.isAltPressed) {
        _showPropertiesForSelectedFile();
      }
    }
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileManagerBloc, FileManagerState>(
      builder: (context, state) {
        if (state is FileManagerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FileManagerError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is FileManagerLoaded) {
          switch (state.viewMode) {
            case ViewMode.grid:
              return _buildGridView(state);
            case ViewMode.list:
              return _buildListView(state);
            case ViewMode.column:
              return _buildColumnView(state);
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
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final local = overlay.globalToLocal(details.globalPosition);
        _showAdaptiveContextMenu(local);
      },
      child: GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: state.filteredFiles.length,
      itemBuilder: (context, index) {
        final file = state.filteredFiles[index];
        final isSelected = _selectedFiles.contains(file);
        
        return _buildFileItem(file, isSelected);
      },
      ),
    );
  }

  Widget _buildListView(FileManagerLoaded state) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final local = overlay.globalToLocal(details.globalPosition);
        _showAdaptiveContextMenu(local);
      },
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

  Widget _buildColumnView(FileManagerLoaded state) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final local = overlay.globalToLocal(details.globalPosition);
        _showAdaptiveContextMenu(local);
      },
      child: ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      itemCount: state.filteredFiles.length,
      itemBuilder: (context, index) {
        final file = state.filteredFiles[index];
        final isSelected = _selectedFiles.contains(file);
        
        return _buildColumnItem(file, isSelected);
      },
      ),
    );
  }

  Widget _buildGalleryView(FileManagerLoaded state) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final local = overlay.globalToLocal(details.globalPosition);
        _showAdaptiveContextMenu(local);
      },
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

  void _showEmptyContextMenu(Offset position) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: EmptyContextMenu(
              onNewFolder: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => NewFolderDialog(
                    onCreateFolder: (name) {
                      final state = this.context.read<FileManagerBloc>().state;
                      if (state is FileManagerLoaded) {
                        context.read<FileManagerBloc>().add(CreateNewFolderEvent(name));
                      }
                    },
                  ),
                );
              },
              onNewDocument: () {
                Navigator.pop(context);
                _showNewDocumentDialog();
              },
              onOpenWith: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open With not implemented')));
              },
              onOpenInConsole: () {
                Navigator.pop(context);
                _openTerminalAtCurrentPath();
              },
              onPaste: ClipboardService.instance.hasItems ? () {
                Navigator.pop(context);
                _pasteFiles();
              } : null,
              onSelectAll: () {
                Navigator.pop(context);
                _selectAllFiles();
              },
              onProperties: () {
                Navigator.pop(context);
                _showPropertiesForSelectedFile();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewDocumentDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFF2D2D2D),
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

  Widget _buildFileItem(FileItem file, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onFileTap(file),
      onDoubleTap: () => _openFile(file),
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final local = overlay.globalToLocal(details.globalPosition);
        _showAdaptiveContextMenu(local, file: file);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF007AFF), width: 2) : null,
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
                    color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
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
      ),
    );
  }

  Widget _buildFileIcon(FileItem file) {
    IconData iconData;
    Color iconColor;

    if (file.isDirectory) {
      iconData = Icons.folder;
      iconColor = const Color(0xFF007AFF);
    } else {
      // Determine icon based on file extension
      switch (file.extension.toLowerCase()) {
        case '.txt':
        case '.md':
        case '.rtf':
          iconData = Icons.description;
          iconColor = Colors.white70;
          break;
        case '.pdf':
          iconData = Icons.picture_as_pdf;
          iconColor = Colors.red;
          break;
        case '.jpg':
        case '.jpeg':
        case '.png':
        case '.gif':
        case '.bmp':
        case '.svg':
          iconData = Icons.image;
          iconColor = Colors.green;
          break;
        case '.mp4':
        case '.avi':
        case '.mov':
        case '.mkv':
          iconData = Icons.videocam;
          iconColor = Colors.purple;
          break;
        case '.mp3':
        case '.wav':
        case '.flac':
        case '.aac':
          iconData = Icons.music_note;
          iconColor = Colors.orange;
          break;
        case '.zip':
        case '.rar':
        case '.tar':
        case '.gz':
          iconData = Icons.archive;
          iconColor = Colors.brown;
          break;
        case '.exe':
        case '.app':
        case '.deb':
          iconData = Icons.apps;
          iconColor = Colors.blue;
          break;
        default:
          iconData = Icons.insert_drive_file;
          iconColor = Colors.white70;
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ignore: deprecated_member_use
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        size: 32,
        color: iconColor,
      ),
    );
  }

  Widget _buildListItem(FileItem file, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isSelected ? Border.all(color: const Color(0xFF007AFF), width: 1) : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFileTap(file),
        onDoubleTap: () => _openFile(file),
        onSecondaryTapDown: (details) {
          final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
          final local = overlay.globalToLocal(details.globalPosition);
          _showAdaptiveContextMenu(local, file: file);
        },
        child: ListTile(
          leading: _buildFileIcon(file),
          title: Text(
            file.name,
            style: TextStyle(
              color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
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

  Widget _buildColumnItem(FileItem file, bool isSelected) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFF007AFF), width: 2) : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFileTap(file),
        onDoubleTap: () => _openFile(file),
        onSecondaryTapDown: (details) {
          final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
          final local = overlay.globalToLocal(details.globalPosition);
          _showAdaptiveContextMenu(local, file: file);
        },
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
                    color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
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
      ),
    );
    
  }

  Widget _buildGalleryItem(FileItem file, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFF007AFF), width: 2) : null,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFileTap(file),
        onDoubleTap: () => _openFile(file),
        onSecondaryTapDown: (details) {
          final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
          final local = overlay.globalToLocal(details.globalPosition);
          _showAdaptiveContextMenu(local, file: file);
        },
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(188, 0, 0, 0),
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
                  color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
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
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
      _selectedFile = file;
    });
  }

  void _showAdaptiveContextMenu(Offset position, {FileItem? file}) {
    // If file is provided, it's a file context menu
    if (file != null) {
      setState(() {
        _selectedFile = file;
        if (!_selectedFiles.contains(file)) {
          _selectedFiles = [file];
        }
      });
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: CombinedContextMenu(
              file: file,
              onNewFolder: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => NewFolderDialog(
                    onCreateFolder: (name) {
                      final state = this.context.read<FileManagerBloc>().state;
                      if (state is FileManagerLoaded) {
                        context.read<FileManagerBloc>().add(CreateNewFolderEvent(name));
                      }
                    },
                  ),
                );
              },
              onNewDocument: () {
                Navigator.pop(context);
                _showNewDocumentDialog();
              },
              onOpenWith: file != null ? () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open With not implemented')));
              } : null,
              onOpenInConsole: () {
                Navigator.pop(context);
                _openTerminalAtCurrentPath();
              },
              onPaste: ClipboardService.instance.hasItems ? () {
                Navigator.pop(context);
                _pasteFiles();
              } : null,
              onSelectAll: () {
                Navigator.pop(context);
                _selectAllFiles();
              },
              onProperties: () {
                Navigator.pop(context);
                _showPropertiesForSelectedFile();
              },

              // File callbacks (may be null when file == null)
              onOpen: file != null ? () => _openFile(file) : null,
              onCut: file != null ? () => _cutFile(file) : null,
              onCopy: file != null ? () => _copyFile(file) : null,
              onMoveTo: file != null ? () => _moveToFile(file) : null,
              onCopyTo: file != null ? () => _copyToFile(file) : null,
              onRename: file != null ? () => _renameFile(file) : null,
              onCompress: file != null ? () => _compressFile(file) : null,
              onDelete: file != null ? () => _deleteFile(file) : null,
              onDetails: file != null ? () => _showFileDetails(file) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _renameFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    
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

  void _deleteFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${file.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FileManagerBloc>().add(DeleteFile(file));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    ClipboardService.instance.setCopy([file.path]);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _cutFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    ClipboardService.instance.setCut([file.path]);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cut to clipboard')));
  }

  void _showFileDetails(FileItem file) {
    Navigator.pop(context); // Close context menu
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
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
      ClipboardService.instance.setCopy(_selectedFiles.map((f) => f.path).toList());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied selection to clipboard')));
    }
  }

  void _cutSelectedFiles() {
    if (_selectedFiles.isNotEmpty) {
      ClipboardService.instance.setCut(_selectedFiles.map((f) => f.path).toList());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cut selection to clipboard')));
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
      final isDeb = extension == '.deb';

      if (isDeb) {
        showDialog(
          context: context,
          builder: (context) => DebInstallerDialog(debFilePath: file.path),
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

  void _moveToFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        title: const Text('Move to...', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Select destination folder',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Move to functionality not implemented yet')),
              );
            },
            child: const Text('Move', style: TextStyle(color: Color(0xFF007AFF))),
          ),
        ],
      ),
    );
  }

  void _copyToFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        title: const Text('Copy to...', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Select destination folder',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copy to functionality not implemented yet')),
              );
            },
            child: const Text('Copy', style: TextStyle(color: Color(0xFF007AFF))),
          ),
        ],
      ),
    );
  }

  void _compressFile(FileItem file) {
    Navigator.pop(context); // Close context menu
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        title: const Text('Compress...', style: TextStyle(color: Colors.white)),
        content: Text(
          'Compress "${file.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compress functionality not implemented yet')),
              );
            },
            child: const Text('Compress', style: TextStyle(color: Color(0xFF007AFF))),
          ),
        ],
      ),
    );
  }

  void _selectAllFiles() {
    final state = context.read<FileManagerBloc>().state;
    if (state is FileManagerLoaded) {
      setState(() {
        _selectedFiles = List.from(state.filteredFiles);
      });
    }
  }

  void _showPropertiesForSelectedFile() {
    if (_selectedFile != null) {
      _showFileDetails(_selectedFile!);
    }
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
      backgroundColor: const Color.fromARGB(188, 0, 0, 0),
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
