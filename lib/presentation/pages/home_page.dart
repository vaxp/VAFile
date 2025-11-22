import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/presentation/pages/venom_layout.dart';
import 'dart:io' show Platform;
import '../../application/file_manager/file_manager_bloc.dart' as fm;
import '../../domain/vaxp.dart';
import '../widgets/sidebar.dart';
import '../widgets/file_grid_view.dart';
import '../widgets/dialogs/new_folder_dialog.dart';
import '../../infrastructure/clipboard_service.dart';

class FileManagerHomePage extends StatefulWidget {
  const FileManagerHomePage({super.key});

  @override
  State<FileManagerHomePage> createState() => _FileManagerHomePageState();
}

class _FileManagerHomePageState extends State<FileManagerHomePage> {
  final GlobalKey<FileGridViewState> _gridKey = GlobalKey<FileGridViewState>();
  FileItem? _focusedFile;
  List<_ActionButtonConfig>? _cachedActionConfigs;
  FileItem? _cachedFocusedFile;

  @override
  void initState() {
    super.initState();
    // Initialize file manager state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<fm.FileManagerBloc>().add(fm.InitializeFileManager());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VenomScaffold(
      body: Column(
        children: [
          // _buildTitleBar(context),
          _buildActionBar(),
          _buildMainContent(),
          buildStatusBar(),
        ],
      ),
    );
  }



  Widget _buildMainContent() {
    return Expanded(
      child: Row(
        children: [
          RepaintBoundary(
            child: Container(
              width: 200,
              decoration: const BoxDecoration(
                color: Color.fromARGB(100, 0, 0, 0),
              ),
              child: const Sidebar(),
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              child: Container(
                color: const Color.fromARGB(100, 0, 0, 0),
                child: FileGridView(
                  key: _gridKey,
                  onSelectionChanged: _handleSelectionChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSelectionChanged(FileItem? file) {
    if (_focusedFile != file) {
      setState(() {
        _focusedFile = file;
        _cachedActionConfigs = null; // Invalidate cache
        _cachedFocusedFile = file;
      });
    }
  }

  Widget _buildActionBar() {
    // Use cached configs if available and focused file hasn't changed
    if (_cachedActionConfigs != null && _cachedFocusedFile == _focusedFile) {
      return _buildActionBarFromConfigs(_cachedActionConfigs!);
    }
    
    final isTrash = _isCurrentPathTrash();
    final actions = _focusedFile == null 
        ? (isTrash ? _trashGeneralActionConfigs() : _generalActionConfigs())
        : _fileActionConfigs(_focusedFile!);
    _cachedActionConfigs = actions;
    _cachedFocusedFile = _focusedFile;
    return _buildActionBarFromConfigs(actions);
  }

  Widget _buildActionBarFromConfigs(List<_ActionButtonConfig> actions) {

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color.fromARGB(100, 0, 0, 0),
        border: Border(
          // bottom: BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: actions.map(_buildActionButton, ).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton(_ActionButtonConfig config) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: config.onPressed == null ? Colors.white30 : Colors.white,
          backgroundColor: config.onPressed == null ? Colors.white10 : Colors.white12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: config.onPressed,
        icon: Icon(config.icon, size: 16),
        label: Text(
          config.label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  List<_ActionButtonConfig> _generalActionConfigs() {
    final grid = _gridKey.currentState;
    final hasClipboardItems = ClipboardService.instance.hasItems;

    return[
      _ActionButtonConfig(
        label: 'New Folder',
        icon: Icons.create_new_folder_outlined,
        onPressed: () => _showNewFolderDialog(context),
      ),
      _ActionButtonConfig(
        label: 'New Document',
        icon: Icons.note_add_outlined,
        onPressed: grid == null ? null : () => grid.createNewDocumentFromToolbar(),
      ),
      _ActionButtonConfig(
        label: 'Open Terminal',
        icon: Icons.terminal,
        onPressed: grid == null ? null : () => grid.openTerminalInCurrentDirectory(),
      ),
      _ActionButtonConfig(
        label: 'Paste',
        icon: Icons.paste_outlined,
        onPressed: hasClipboardItems && grid != null ? () => grid.pasteFromClipboard() : null,
      ),
      _ActionButtonConfig(
        label: 'Select All',
        icon: Icons.select_all,
        onPressed: grid == null ? null : () => grid.selectAllEntries(),
      ),
    ];
  }

  List<_ActionButtonConfig> _trashGeneralActionConfigs() {
    final grid = _gridKey.currentState;
    return [
      _ActionButtonConfig(
        label: 'Restore All',
        icon: Icons.restore,
        onPressed: grid == null ? null : () => _showRestoreAllDialog(context),
      ),
      _ActionButtonConfig(
        label: 'Empty Trash',
        icon: Icons.delete_forever,
        onPressed: grid == null ? null : () => _showEmptyTrashDialog(context),
      ),
      _ActionButtonConfig(
        label: 'Select All',
        icon: Icons.select_all,
        onPressed: grid == null ? null : () => grid.selectAllEntries(),
      ),
    ];
  }

  bool _isCurrentPathTrash() {
    final state = context.read<fm.FileManagerBloc>().state;
    if (state is fm.FileManagerLoaded) {
      final home = Platform.environment['HOME'] ?? '';
      final trashPath = '$home/.local/share/Trash/files';
      return state.currentPath == trashPath;
    }
    return false;
  }

  List<_ActionButtonConfig> _fileActionConfigs(FileItem file) {
    final grid = _gridKey.currentState;
    final hasClipboardItems = ClipboardService.instance.hasItems;
    final isArchive = _isArchiveFile(file);
    final isTrash = _isCurrentPathTrash();
    final configs = <_ActionButtonConfig>[];

    // If in Trash, only show Restore and Permanently Delete
    if (isTrash) {
      return [
        _ActionButtonConfig(
          label: 'Restore',
          icon: Icons.restore,
          onPressed: grid == null ? null : () => _showRestoreDialog(context, file),
        ),
        _ActionButtonConfig(
          label: 'Delete',
          icon: Icons.delete_forever,
          onPressed: grid == null ? null : () => _showPermanentDeleteDialog(context, file),
        ),
      ];
    }

    // Only show Open button if it's not an archive file
    if (!isArchive) {
      configs.add(_ActionButtonConfig(
        label: _labelForPrimaryAction(file),
        icon: _iconForPrimaryAction(file),
        onPressed: grid == null ? null : () => grid.openSelection(),
      ));
    }

    if (file.isDirectory && !isArchive) {
      configs.add(_ActionButtonConfig(
        label: 'Open Terminal Here',
        icon: Icons.code,
        onPressed: grid == null ? null : () => grid.openTerminalInCurrentDirectory(),
      ));
    }

    configs.addAll([
      _ActionButtonConfig(
        label: 'Rename',
        icon: Icons.drive_file_rename_outline,
        onPressed: grid == null ? null : () => grid.renameSelection(),
      ),
      _ActionButtonConfig(
        label: 'Copy',
        icon: Icons.copy,
        onPressed: grid == null ? null : () => grid.copySelection(),
      ),
      _ActionButtonConfig(
        label: 'Cut',
        icon: Icons.cut,
        onPressed: grid == null ? null : () => grid.cutSelection(),
      ),
      // Only show Compress button if it's not an archive file
      if (!isArchive)
        _ActionButtonConfig(
          label: 'Compress',
          icon: Icons.folder_zip,
          onPressed: grid == null ? null : () => _showCompressDialog(context, file),
        ),
      if (isArchive)
        _ActionButtonConfig(
          label: 'Extract',
          icon: Icons.unarchive,
          onPressed: grid == null ? null : () => _showExtractDialog(context, file),
        ),
      _ActionButtonConfig(
        label: 'Delete',
        icon: Icons.delete_outline,
        onPressed: grid == null ? null : () => _showDeleteConfirmDialog(context, file),
      ),
      _ActionButtonConfig(
        label: 'Paste',
        icon: Icons.paste_outlined,
        onPressed: hasClipboardItems && grid != null ? () => grid.pasteFromClipboard() : null,
      ),
      _ActionButtonConfig(
        label: 'Details',
        icon: Icons.info_outline,
        onPressed: grid == null ? null : () => grid.showSelectionDetails(),
      ),
    ]);

    return configs;
  }

  String _labelForPrimaryAction(FileItem file) {
    if (file.isDirectory) return 'Open Folder';
    final ext = file.extension.toLowerCase();
    if (_debExtensions.contains(ext)) return 'Install Package';
    if (_desktopExtensions.contains(ext)) return 'Launch App';
    if (_textExtensions.contains(ext)) return 'Edit Document';
    if (_mediaExtensions.contains(ext)) return 'Preview';
    return 'Open';
  }

  IconData _iconForPrimaryAction(FileItem file) {
    if (file.isDirectory) return Icons.folder_open;
    final ext = file.extension.toLowerCase();
    if (_debExtensions.contains(ext)) return Icons.install_desktop;
    if (_desktopExtensions.contains(ext)) return Icons.rocket_launch;
    if (_textExtensions.contains(ext)) return Icons.edit_note;
    if (_mediaExtensions.contains(ext)) return Icons.slideshow;
    return Icons.open_in_new;
  }

  static const Set<String> _textExtensions = {
    '.txt', '.text', '.md', '.rtf', '.c', '.cc', '.dart', '.py', '.sh', '.html', '.conf','.config','.js', '.ts', '.json', '.yaml', '.yml', '.xml'
  };

  static const Set<String> _mediaExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp',
    '.mp4', '.avi', '.mov', '.mkv', '.webm',
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.opus'
  };

  static const Set<String> _debExtensions = {'.deb'};
  static const Set<String> _desktopExtensions = {'.desktop'};
  static const Set<String> _archiveExtensions = {'.zip', '.tar', '.tar.gz', '.tar.bz2', '.7z', '.gz', '.bz2'};

  bool _isArchiveFile(FileItem file) {
    final name = file.name.toLowerCase();
    // Check for exact extensions including compound ones
    if (name.endsWith('.tar.gz') || name.endsWith('.tar.bz2')) return true;
    // Check for single extensions
    return _archiveExtensions.contains(file.extension.toLowerCase());
  }

  Widget buildStatusBar() {
    return RepaintBoundary(
      child: Container(
        height: 24,
        decoration: const BoxDecoration(
          color: Color.fromARGB(100, 0, 0, 0),
          border: Border(
            top: BorderSide(color: Color(0xFF404040), width: 1),
          ),
        ),
        child: BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
          buildWhen: (previous, current) {
            // Only rebuild if filteredFiles length or availableSpace changed
            if (previous is fm.FileManagerLoaded && current is fm.FileManagerLoaded) {
              return previous.filteredFiles.length != current.filteredFiles.length ||
                     previous.availableSpace != current.availableSpace;
            }
            return previous != current;
          },
          builder: (context, state) {
            if (state is fm.FileManagerLoaded) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${state.filteredFiles.length} items',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      '${state.availableSpace} GB available',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NewFolderDialog(
        onCreateFolder: (name) {
          context.read<fm.FileManagerBloc>().add(fm.CreateNewFolderEvent(name));
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Delete File',
          style: TextStyle(color: Colors.white),
        ),
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
              context.read<fm.FileManagerBloc>().add(fm.DeleteFile(file));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Moved ${file.name} to trash')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF5F57))),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Restore File',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Restore "${file.name}" to its original location?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              // For now, we'll just show a message
              // In a real app, you'd need to track original paths
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Restoring ${file.name}...')),
              );
            },
            child: const Text('Restore', style: TextStyle(color: Color(0xFF34C759))),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteDialog(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Permanently Delete',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${file.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<fm.FileManagerBloc>().add(fm.PermanentlyDeleteFile(file));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permanently deleted ${file.name}')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF5F57))),
          ),
        ],
      ),
    );
  }

  void _showRestoreAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Restore All Files',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Restore all files from trash to their original locations?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              // Note: This will restore all files that exist in trash
              // For simplicity, we'll show a message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restoring files from trash...')),
              );
            },
            child: const Text('Restore All', style: TextStyle(color: Color(0xFF34C759))),
          ),
        ],
      ),
    );
  }

  void _showEmptyTrashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Empty Trash',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to permanently delete all files in trash? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<fm.FileManagerBloc>().add(fm.EmptyTrash());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trash emptied')),
              );
            },
            child: const Text('Empty', style: TextStyle(color: Color(0xFFFF5F57))),
          ),
        ],
      ),
    );
  }

  void _showExtractDialog(BuildContext context, FileItem file) {
    final state = context.read<fm.FileManagerBloc>().state;
    final currentPath = state is fm.FileManagerLoaded ? state.currentPath : '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Extract Archive',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Extract "${file.name}" to current directory?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<fm.FileManagerBloc>().add(
                fm.ExtractArchive(file, currentPath),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Extracting ${file.name}...')),
              );
            },
            child: const Text('Extract', style: TextStyle(color: Color(0xFF34C759))),
          ),
        ],
      ),
    );
  }

  void _showCompressDialog(BuildContext context, FileItem file) {
    final controller = TextEditingController(text: file.name);
    String selectedFormat = 'zip';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Compress File',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archive name:',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1F1F1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF404040)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Archive Format:',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  border: Border.all(color: const Color(0xFF404040)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: selectedFormat,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedFormat = value);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'zip',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.folder_zip, color: Color(0xFF007AFF), size: 18),
                            SizedBox(width: 8),
                            Text('ZIP (.zip)'),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tar',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.folder_zip, color: Color(0xFF34C759), size: 18),
                            SizedBox(width: 8),
                            Text('TAR (.tar)'),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tar.gz',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.folder_zip, color: Color(0xFFFF9500), size: 18),
                            SizedBox(width: 8),
                            Text('TAR.GZ (.tar.gz)'),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'tar.bz2',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.folder_zip, color: Color(0xFFFF3B30), size: 18),
                            SizedBox(width: 8),
                            Text('TAR.BZ2 (.tar.bz2)'),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '7z',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.folder_zip, color: Color(0xFFA2845E), size: 18),
                            SizedBox(width: 8),
                            Text('7Z (.7z)'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final archiveName = controller.text;
                if (archiveName.isNotEmpty) {
                  final state = context.read<fm.FileManagerBloc>().state;
                  if (state is fm.FileManagerLoaded) {
                    context.read<fm.FileManagerBloc>().add(
                      fm.CompressFiles([file], state.currentPath, archiveFormat: selectedFormat),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Compressing ${file.name} as $selectedFormat')),
                    );
                  }
                }
              },
              child: const Text('Compress', style: TextStyle(color: Color(0xFF007AFF))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonConfig {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButtonConfig({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}