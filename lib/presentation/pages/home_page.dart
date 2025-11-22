import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/presentation/pages/venom_layout.dart';
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
    
    final actions = _focusedFile == null ? _generalActionConfigs() : _fileActionConfigs(_focusedFile!);
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

  List<_ActionButtonConfig> _fileActionConfigs(FileItem file) {
    final grid = _gridKey.currentState;
    final hasClipboardItems = ClipboardService.instance.hasItems;
    final configs = <_ActionButtonConfig>[];

    configs.add(_ActionButtonConfig(
      label: _labelForPrimaryAction(file),
      icon: _iconForPrimaryAction(file),
      onPressed: grid == null ? null : () => grid.openSelection(),
    ));

    if (file.isDirectory) {
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
    '.txt', '.text', '.md', '.rtf', '.c', '.cc', '.dart', '.py', '.sh', '.html', '.js', '.ts', '.json', '.yaml', '.yml'
  };

  static const Set<String> _mediaExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp',
    '.mp4', '.avi', '.mov', '.mkv', '.webm',
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.opus'
  };

  static const Set<String> _debExtensions = {'.deb'};
  static const Set<String> _desktopExtensions = {'.desktop'};

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