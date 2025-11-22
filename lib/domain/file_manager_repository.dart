import 'vaxp.dart';

abstract class FileManagerRepository {
  Future<List<FileItem>> loadDirectory(String path, {bool showHiddenFiles = false});
  Future<void> deleteFile(FileItem file);
  Future<void> renameFile(FileItem file, String newName);
  Future<void> createNewFolder(String path, String name);
  Future<List<DeviceInfo>> detectConnectedDevices();
  Future<void> copyFile(FileItem file, String destination);
  Future<void> moveFile(FileItem file, String destination);
  Future<void> compressFiles(List<String> filePaths, String destination, String format);
  Future<void> extractArchive(String archivePath, String destinationPath);
  Future<void> restoreFromTrash(FileItem file, String originalPath);
  Future<void> permanentlyDeleteFile(FileItem file);
  Future<void> emptyTrash();
  Future<void> executeFile(String filePath);
}
