import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/file_manager/file_manager_bloc.dart' as fm;
import '../../domain/vaxp.dart';

class MenuOptions {
  static void showMoreOptionsMenu(BuildContext context, {RelativeRect? position}) {
    showMenu<String>(
      context: context,
      position: position ?? const RelativeRect.fromLTRB(0, 40, 0, 0),
      color: const Color.fromARGB(100, 0, 0, 0),
      items: [
        const PopupMenuItem<String>(
          enabled: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'View Mode',
              style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'grid',
          child: Row(
            children: [
              Icon(Icons.grid_view, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('Grid View'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'list',
          child: Row(
            children: [
              Icon(Icons.list, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('List View'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('Gallery View'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'show_hidden',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('Show Hidden Files'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sort_by',
          child: Row(
            children: [
              Icon(Icons.sort, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('Sort By'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'view_options',
          child: Row(
            children: [
              Icon(Icons.settings, size: 18, color: Colors.white70),
              SizedBox(width: 12),
              Text('View Options'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'grid':
            context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.grid));
            break;
          case 'list':
            context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.list));
            break;
          case 'gallery':
            context.read<fm.FileManagerBloc>().add(fm.ChangeViewMode(ViewMode.gallery));
            break;
          case 'refresh':
            // ignore: use_build_context_synchronously
            context.read<fm.FileManagerBloc>().add(fm.RefreshFileManager());
            break;
          case 'show_hidden':
            // ignore: use_build_context_synchronously
            context.read<fm.FileManagerBloc>().add(fm.ToggleHiddenFiles(true));
            break;
          case 'sort_by':
            // ignore: use_build_context_synchronously
            _showSortOptions(context);
            break;
          case 'view_options':
            // ignore: use_build_context_synchronously
            _showViewOptions(context);
            break;
        }
      }
    });
  }

  static void _showSortOptions(BuildContext context, {RelativeRect? position}) {
    showMenu(
      context: context,
      position: position ?? const RelativeRect.fromLTRB(0, 40, 0, 0),
      color: const Color.fromARGB(120, 0, 0, 0),
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
        // ignore: use_build_context_synchronously
        context.read<fm.FileManagerBloc>().add(fm.ChangeSortBy(value));
      }
    });
  }

  static void _showViewOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
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
