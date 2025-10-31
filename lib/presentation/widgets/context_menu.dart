import 'package:flutter/material.dart';
import '../../domain/vaxp.dart';

class ContextMenu extends StatelessWidget {
  final FileItem file;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onCut;
  final VoidCallback onDetails;
  final VoidCallback onOpen;
  final VoidCallback onMoveTo;
  final VoidCallback onCopyTo;
  final VoidCallback onCompress;

  const ContextMenu({
    super.key,
    required this.file,
    required this.onRename,
    required this.onDelete,
    required this.onCopy,
    required this.onCut,
    required this.onDetails,
    required this.onOpen,
    required this.onMoveTo,
    required this.onCopyTo,
    required this.onCompress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF404040), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              title: 'Open',
              onTap: onOpen,
              hasArrow: true,
            ),
            _buildMenuItem(
              title: 'Cut',
              shortcut: 'Ctrl+X',
              onTap: onCut,
            ),
            _buildMenuItem(
              title: 'Copy',
              shortcut: 'Ctrl+C',
              onTap: onCopy,
            ),
            _buildMenuItem(
              title: 'Move to...',
              onTap: onMoveTo,
              hasEllipsis: true,
            ),
            _buildMenuItem(
              title: 'Copy to...',
              onTap: onCopyTo,
              hasEllipsis: true,
            ),
            const Divider(
              color: Color(0xFF404040),
              height: 1,
            ),
            _buildMenuItem(
              title: 'Rename...',
              shortcut: 'F2',
              onTap: onRename,
              hasEllipsis: true,
            ),
            _buildMenuItem(
              title: 'Compress...',
              onTap: onCompress,
              hasEllipsis: true,
            ),
            _buildMenuItem(
              title: 'Move to Trash',
              shortcut: 'Delete',
              onTap: onDelete,
              isDestructive: true,
            ),
            const Divider(
              color: Color(0xFF404040),
              height: 1,
            ),
            _buildMenuItem(
              title: 'Properties',
              shortcut: 'Alt+Return',
              onTap: onDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    String? shortcut,
    bool isDestructive = false,
    bool hasArrow = false,
    bool hasEllipsis = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDestructive ? Colors.red : Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (hasArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.white54,
                )
              else if (hasEllipsis)
                Text(
                  '...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                )
              else if (shortcut != null)
                Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyContextMenu extends StatelessWidget {
  final VoidCallback onNewFolder;
  final VoidCallback onNewDocument;
  final VoidCallback onOpenWith;
  final VoidCallback onOpenInConsole;
  final VoidCallback? onPaste;
  final VoidCallback onSelectAll;
  final VoidCallback onProperties;

  const EmptyContextMenu({
    super.key,
    required this.onNewFolder,
    required this.onNewDocument,
    required this.onOpenWith,
    required this.onOpenInConsole,
    required this.onPaste,
    required this.onSelectAll,
    required this.onProperties,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF404040), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(title: 'New Folder...', onTap: onNewFolder),
            _buildMenuItem(title: 'New Document', onTap: onNewDocument, hasArrow: true),
            _buildMenuItem(title: 'Open With...', onTap: onOpenWith),
            _buildMenuItem(title: 'Open in Console', onTap: onOpenInConsole),
            const Divider(color: Color(0xFF404040), height: 1),
            _buildMenuItem(title: 'Paste', onTap: onPaste ?? () {}, disabled: onPaste == null),
            _buildMenuItem(title: 'Select All', onTap: onSelectAll, shortcut: 'Ctrl+A'),
            const Divider(color: Color(0xFF404040), height: 1),
            _buildMenuItem(title: 'Properties', onTap: onProperties, shortcut: 'Alt+Return'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    String? shortcut,
    bool disabled = false,
    bool hasArrow = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: disabled ? Colors.white24 : Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (hasArrow)
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white54)
              else if (shortcut != null)
                Text(
                  shortcut,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CombinedContextMenu extends StatelessWidget {
  final FileItem? file;
  final VoidCallback? onNewFolder;
  final VoidCallback? onNewDocument;
  final VoidCallback? onOpenWith;
  final VoidCallback? onOpenInConsole;
  final VoidCallback? onPaste;
  final VoidCallback? onSelectAll;
  final VoidCallback? onProperties;

  // File-specific
  final VoidCallback? onOpen;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onMoveTo;
  final VoidCallback? onCopyTo;
  final VoidCallback? onRename;
  final VoidCallback? onCompress;
  final VoidCallback? onDelete;
  final VoidCallback? onDetails;

  const CombinedContextMenu({
    super.key,
    this.file,
    this.onNewFolder,
    this.onNewDocument,
    this.onOpenWith,
    this.onOpenInConsole,
    this.onPaste,
    this.onSelectAll,
    this.onProperties,
    this.onOpen,
    this.onCut,
    this.onCopy,
    this.onMoveTo,
    this.onCopyTo,
    this.onRename,
    this.onCompress,
    this.onDelete,
    this.onDetails,
  });

  bool get hasSelectionOrFile => file != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF404040), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // New folder / document / open with / open in console
            _buildMenuItem(
              title: 'New Folder...',
              onTap: onNewFolder,
              disabled: onNewFolder == null,
            ),
            _buildMenuItem(
              title: 'New Document',
              onTap: onNewDocument,
              hasArrow: true,
              disabled: onNewDocument == null,
            ),
            _buildMenuItem(
              title: 'Open With...',
              onTap: onOpenWith,
              disabled: onOpenWith == null || file == null,
            ),
            _buildMenuItem(
              title: 'Open in Console',
              onTap: onOpenInConsole,
              disabled: onOpenInConsole == null,
            ),
            const Divider(color: Color(0xFF404040), height: 1),

            // File operations
            _buildMenuItem(
              title: 'Open',
              onTap: onOpen,
              hasArrow: true,
              disabled: onOpen == null || file == null,
            ),
            _buildMenuItem(
              title: 'Cut',
              onTap: onCut,
              shortcut: 'Ctrl+X',
              disabled: onCut == null || file == null,
            ),
            _buildMenuItem(
              title: 'Copy',
              onTap: onCopy,
              shortcut: 'Ctrl+C',
              disabled: onCopy == null || file == null,
            ),
            _buildMenuItem(
              title: 'Move to...',
              onTap: onMoveTo,
              hasEllipsis: true,
              disabled: onMoveTo == null || file == null,
            ),
            _buildMenuItem(
              title: 'Copy to...',
              onTap: onCopyTo,
              hasEllipsis: true,
              disabled: onCopyTo == null || file == null,
            ),
            const Divider(color: Color(0xFF404040), height: 1),
            _buildMenuItem(
              title: 'Rename...',
              onTap: onRename,
              shortcut: 'F2',
              hasEllipsis: true,
              disabled: onRename == null || file == null,
            ),
            _buildMenuItem(
              title: 'Compress...',
              onTap: onCompress,
              hasEllipsis: true,
              disabled: onCompress == null || file == null,
            ),
            _buildMenuItem(
              title: 'Move to Trash',
              onTap: onDelete,
              shortcut: 'Delete',
              isDestructive: true,
              disabled: onDelete == null || file == null,
            ),
            const Divider(color: Color(0xFF404040), height: 1),
            // Paste / Select all / Properties
            _buildMenuItem(
              title: 'Paste',
              onTap: onPaste,
              disabled: onPaste == null,
            ),
            _buildMenuItem(
              title: 'Select All',
              onTap: onSelectAll,
              shortcut: 'Ctrl+A',
              disabled: onSelectAll == null,
            ),
            const Divider(color: Color(0xFF404040), height: 1),
            _buildMenuItem(
              title: 'Properties',
              onTap: onProperties ?? onDetails,
              shortcut: 'Alt+Return',
              disabled: (onProperties == null && onDetails == null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    VoidCallback? onTap,
    String? shortcut,
    bool isDestructive = false,
    bool hasArrow = false,
    bool hasEllipsis = false,
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: disabled ? Colors.white24 : (isDestructive ? Colors.red : Colors.white70),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (hasArrow)
                Icon(Icons.arrow_forward_ios, size: 12, color: disabled ? Colors.white24 : Colors.white54)
              else if (hasEllipsis)
                Text('...', style: TextStyle(fontSize: 13, color: disabled ? Colors.white24 : Colors.white54))
              else if (shortcut != null)
                Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 11,
                    color: disabled ? Colors.white24 : Colors.white54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
