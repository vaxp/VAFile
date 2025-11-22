import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/vaxp.dart';
import '../domain/file_manager_repository.dart';
import 'device_detection_service.dart';

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
    try {
      return await DeviceDetectionService.detectDevices();
    } catch (_) {
      return [];
    }
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
  Future<void> compressFiles(List<String> filePaths, String destination, String format) async {
    try {
      for (final filePath in filePaths) {
        String archivePath;
        
        switch (format.toLowerCase()) {
          case 'zip':
            archivePath = p.join(destination, '${p.basenameWithoutExtension(filePath)}.zip');
            await _compressToZip(filePath, archivePath);
            break;
          case 'tar':
            archivePath = p.join(destination, '${p.basenameWithoutExtension(filePath)}.tar');
            await _compressToTar(filePath, archivePath, gzip: false, bzip2: false);
            break;
          case 'tar.gz':
            archivePath = p.join(destination, '${p.basenameWithoutExtension(filePath)}.tar.gz');
            await _compressToTar(filePath, archivePath, gzip: true);
            break;
          case 'tar.bz2':
            archivePath = p.join(destination, '${p.basenameWithoutExtension(filePath)}.tar.bz2');
            await _compressToTar(filePath, archivePath, bzip2: true);
            break;
          case '7z':
            archivePath = p.join(destination, '${p.basenameWithoutExtension(filePath)}.7z');
            await _compressTo7z(filePath, archivePath);
            break;
          default:
            throw ArgumentError('Unsupported archive format: $format');
        }
      }
    } catch (e) {
      throw Exception('Failed to compress files: $e');
    }
  }

  @override
  Future<void> extractArchive(String archivePath, String destinationPath) async {
    try {
      final extension = p.extension(archivePath).toLowerCase();
      
      switch (extension) {
        case '.zip':
          await _extractZip(archivePath, destinationPath);
          break;
        case '.tar':
          await _extractTar(archivePath, destinationPath);
          break;
        case '.gz':
          // Check if it's tar.gz
          if (archivePath.endsWith('.tar.gz')) {
            await _extractTarGz(archivePath, destinationPath);
          } else {
            await _extractGz(archivePath, destinationPath);
          }
          break;
        case '.bz2':
          // Check if it's tar.bz2
          if (archivePath.endsWith('.tar.bz2')) {
            await _extractTarBz2(archivePath, destinationPath);
          } else {
            throw Exception('Unsupported archive format: $extension');
          }
          break;
        case '.7z':
          await _extract7z(archivePath, destinationPath);
          break;
        default:
          throw Exception('Unsupported archive format: $extension');
      }
    } catch (e) {
      throw Exception('Failed to extract archive: $e');
    }
  }

  Future<void> _compressToZip(String sourcePath, String archivePath) async {
    final basename = p.basename(sourcePath);
    final parentDir = p.dirname(sourcePath);
    final process = await Process.start('zip', ['-r', archivePath, basename], workingDirectory: parentDir);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('zip command failed with exit code $exitCode');
    }
  }

  Future<void> _compressToTar(String sourcePath, String archivePath, {bool gzip = false, bool bzip2 = false}) async {
    final List<String> args = [];
    
    if (gzip) {
      args.add('-czf');
    } else if (bzip2) {
      args.add('-cjf');
    } else {
      args.add('-cf');
    }
    
    args.add(archivePath);
    args.add(p.basename(sourcePath));
    
    final process = await Process.start('tar', args, workingDirectory: p.dirname(sourcePath));
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('tar command failed with exit code $exitCode');
    }
  }

  Future<void> _compressTo7z(String sourcePath, String archivePath) async {
    final basename = p.basename(sourcePath);
    final parentDir = p.dirname(sourcePath);
    final process = await Process.start('7z', ['a', archivePath, basename], workingDirectory: parentDir);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('7z command failed with exit code $exitCode');
    }
  }

  Future<void> _extractZip(String archivePath, String destinationPath) async {
    final process = await Process.start('unzip', ['-o', archivePath, '-d', destinationPath]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('unzip command failed with exit code $exitCode');
    }
  }

  Future<void> _extractTar(String archivePath, String destinationPath) async {
    final process = await Process.start('tar', ['-xf', archivePath, '-C', destinationPath]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('tar command failed with exit code $exitCode');
    }
  }

  Future<void> _extractTarGz(String archivePath, String destinationPath) async {
    final process = await Process.start('tar', ['-xzf', archivePath, '-C', destinationPath]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('tar command failed with exit code $exitCode');
    }
  }

  Future<void> _extractGz(String archivePath, String destinationPath) async {
    final process = await Process.start('gunzip', ['-c', archivePath]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('gunzip command failed with exit code $exitCode');
    }
  }

  Future<void> _extractTarBz2(String archivePath, String destinationPath) async {
    final process = await Process.start('tar', ['-xjf', archivePath, '-C', destinationPath]);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('tar command failed with exit code $exitCode');
    }
  }

  Future<void> _extract7z(String archivePath, String destinationPath) async {
    final process = await Process.start('7z', ['x', archivePath, '-o$destinationPath']);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('7z command failed with exit code $exitCode');
    }
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
