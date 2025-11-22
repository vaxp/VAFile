// Domain models for FileManager
import 'package:equatable/equatable.dart';

enum ViewMode { grid, list,  gallery }

class DeviceInfo extends Equatable {
  final String name;
  final String mountPoint;
  final String devicePath;
  final String fileSystem;
  final int totalSpace;
  final int freeSpace;
  final bool isRemovable;
  final dynamic icon; // Use dynamic for icon, UI layer will handle type

  const DeviceInfo({
    required this.name,
    required this.mountPoint,
    required this.devicePath,
    required this.fileSystem,
    required this.totalSpace,
    required this.freeSpace,
    required this.isRemovable,
    required this.icon,
  });

  @override
  List<Object?> get props => [
    name,
    mountPoint,
    devicePath,
    fileSystem,
    totalSpace,
    freeSpace,
    isRemovable,
    // Note: icon is excluded from props comparison because it's dynamic
  ];
}

class FileItem extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final String extension;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.extension,
  });

  @override
  List<Object?> get props => [
    name,
    path,
    isDirectory,
    size,
    modified,
    extension,
  ];
}
