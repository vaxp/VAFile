import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/vaxp.dart';
import '../domain/file_manager_repository.dart';

class FileManagerRepositoryImpl implements FileManagerRepository {
  @override
  Future<List<FileItem>> loadDirectory(String path, {bool showHiddenFiles = false}) async {
    final directory = Directory(path);
    if (!directory.existsSync()) return [];
    final entities = directory.listSync();
    return entities
        .map((entity) => FileItem(
              name: p.basename(entity.path),
              path: entity.path,
              isDirectory: entity is Directory,
              size: entity.statSync().size,
              modified: entity.statSync().modified,
              extension: p.extension(entity.path),
            ))
        .where((file) => showHiddenFiles || !file.name.startsWith('.'))
        .toList();
  }

  @override
  Future<void> deleteFile(FileItem file) async {
    if (file.isDirectory) {
      await Directory(file.path).delete(recursive: true);
    } else {
      await File(file.path).delete();
    }
  }

  @override
  Future<void> renameFile(FileItem file, String newName) async {
    final newPath = p.join(p.dirname(file.path), newName);
    if (file.isDirectory) {
      await Directory(file.path).rename(newPath);
    } else {
      await File(file.path).rename(newPath);
    }
  }

  @override
  Future<void> createNewFolder(String path, String name) async {
    final newPath = p.join(path, name);
    await Directory(newPath).create();
  }

  @override
  Future<List<DeviceInfo>> detectConnectedDevices() async {
    // Example implementation, can be expanded
    return [];
  }

  @override
  Future<void> copyFile(FileItem file, String destination) async {
    final destPath = p.join(destination, p.basename(file.path));
    if (file.isDirectory) {
      final newDir = await Directory(destPath).create();
      await _copyDirectory(Directory(file.path), newDir);
    } else {
      await File(file.path).copy(destPath);
    }
  }

  @override
  Future<void> moveFile(FileItem file, String destination) async {
    final destPath = p.join(destination, p.basename(file.path));
    if (file.isDirectory) {
      await Directory(file.path).rename(destPath);
    } else {
      await File(file.path).rename(destPath);
    }
  }

  @override
  Future<void> compressFiles(List<String> filePaths, String destination) async {
    // TODO: Implement file compression
    throw UnimplementedError('File compression not implemented yet');
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await newDirectory.create();
        await _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }
}
