import '../vaxp.dart';
import '../file_manager_repository.dart';

class LoadDirectory {
  final FileManagerRepository repository;
  LoadDirectory(this.repository);

  Future<List<FileItem>> call(String path, {bool showHiddenFiles = false}) {
    return repository.loadDirectory(path, showHiddenFiles: showHiddenFiles);
  }
}
