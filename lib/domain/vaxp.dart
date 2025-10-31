// Domain models for FileManager

enum ViewMode { grid, list, column, gallery }

class DeviceInfo {
  final String name;
  final String mountPoint;
  final String devicePath;
  final String fileSystem;
  final int totalSpace;
  final int freeSpace;
  final bool isRemovable;
  final dynamic icon; // Use dynamic for icon, UI layer will handle type

  DeviceInfo({
    required this.name,
    required this.mountPoint,
    required this.devicePath,
    required this.fileSystem,
    required this.totalSpace,
    required this.freeSpace,
    required this.isRemovable,
    required this.icon,
  });
}

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final String extension;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.extension,
  });
}
