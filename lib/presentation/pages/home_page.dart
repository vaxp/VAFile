import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/file_manager/file_manager_bloc.dart' as fm;
import '../../domain/vaxp.dart';
import '../widgets/sidebar.dart';
import '../widgets/file_grid_view.dart';
import '../widgets/dialogs/new_folder_dialog.dart';

class FileManagerHomePage extends StatefulWidget {
  const FileManagerHomePage({super.key});

  @override
  State<FileManagerHomePage> createState() => _FileManagerHomePageState();
}

class _FileManagerHomePageState extends State<FileManagerHomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize file manager state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<fm.FileManagerBloc>().add(fm.InitializeFileManager());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTitleBar(context),
          _buildMainContent(),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: Color.fromARGB(188, 0, 0, 0),
        border: Border(
          bottom: BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildNavigationControls(),
          const SizedBox(width: 8),
          _buildCurrentPath(),
          const SizedBox(width: 16),
          _buildToolbar(context),
          const SizedBox(width: 16),
          _buildSearchBar(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
      builder: (context, state) {
        if (state is fm.FileManagerLoaded) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => context.read<fm.FileManagerBloc>().add(fm.LoadDirectory(state.currentPath)),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => context.read<fm.FileManagerBloc>().add(fm.LoadDirectory(state.currentPath)),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCurrentPath() {
    return Expanded(
      child: BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
        builder: (context, state) {
          if (state is fm.FileManagerLoaded) {
            return Text(
              state.currentPath,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
      builder: (context, state) {
        if (state is fm.FileManagerLoaded) {
          return Row(
            children: [
              _buildToolbarIcon(
                Icons.grid_view,
                'Icon View',
                state.viewMode == ViewMode.grid,
                () => context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.grid)),
              ),
              _buildToolbarIcon(
                Icons.list,
                'List View',
                state.viewMode == ViewMode.list,
                () => context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.list)),
              ),
              _buildToolbarIcon(
                Icons.view_column,
                'Column View',
                state.viewMode == ViewMode.column,
                () => context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.column)),
              ),
              _buildToolbarIcon(
                Icons.photo_library,
                'Gallery View',
                state.viewMode == ViewMode.gallery,
                () => context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.gallery)),
              ),
              const SizedBox(width: 8),
              _buildToolbarIcon(
                Icons.create_new_folder,
                'New Folder',
                false,
                () => _showNewFolderDialog(context),
              ),
              _buildToolbarIcon(
                Icons.more_horiz,
                'More Options',
                false,
                () => _showMoreOptionsMenu(context),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      flex: 2,
      child: Container(
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(188, 0, 0, 0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.search, size: 16, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onChanged: (value) {
            context.read<fm.FileManagerBloc>().add(fm.SearchFiles(value));
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 200,
            decoration: const BoxDecoration(
              color: Color.fromARGB(188, 0, 0, 0),
            ),
            child: const Sidebar(),
          ),
          Expanded(
            child: Container(
              color: const Color.fromARGB(188, 0, 0, 0),
              child: const FileGridView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: Color.fromARGB(188, 0, 0, 0),
        border: Border(
          top: BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      child: BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
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
    );
  }

  Widget _buildToolbarIcon(IconData icon, String tooltip, bool isSelected, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        icon, 
        size: 18,
        color: isSelected ? const Color(0xFF007AFF) : Colors.white70,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
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

  void _showMoreOptionsMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'refresh',
          child: Text('Refresh'),
        ),
        const PopupMenuItem(
          value: 'show_hidden',
          child: Text('Show Hidden Files'),
        ),
        const PopupMenuItem(
          value: 'sort_by',
          child: Text('Sort By'),
        ),
        const PopupMenuItem(
          value: 'view_options',
          child: Text('View Options'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'refresh':
            context.read<fm.FileManagerBloc>().add(fm.RefreshFileManager());
            break;
          case 'show_hidden':
            context.read<fm.FileManagerBloc>().add(fm.ToggleHiddenFiles(true));
            break;
          case 'sort_by':
            _showSortOptions(context);
            break;
          case 'view_options':
            _showViewOptions(context);
            break;
        }
      }
    });
  }

  void _showSortOptions(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'name',
          child: Text('Name'),
        ),
        const PopupMenuItem(
          value: 'size',
          child: Text('Size'),
        ),
        const PopupMenuItem(
          value: 'date',
          child: Text('Date Modified'),
        ),
        const PopupMenuItem(
          value: 'type',
          child: Text('Type'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        context.read<fm.FileManagerBloc>().add(fm.ChangeSortBy(value));
      }
    });
  }

  void _showViewOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        title: const Text('View Options', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
              builder: (context, state) {
                if (state is fm.FileManagerLoaded) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show Hidden Files', style: TextStyle(color: Colors.white70)),
                        value: state.showHiddenFiles,
                        onChanged: (value) => context.read<fm.FileManagerBloc>().add(fm.ToggleHiddenFiles(value)),
                      ),
                      SwitchListTile(
                        title: const Text('Show File Extensions', style: TextStyle(color: Colors.white70)),
                        value: state.showFileExtensions,
                        onChanged: (value) => context.read<fm.FileManagerBloc>().add(fm.ToggleFileExtensions(value)),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
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
}