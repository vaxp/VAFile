import '../file_manager_repository.dart';

class CreateNewFolder {
  final FileManagerRepository repository;
  CreateNewFolder(this.repository);

  Future<void> call(String path, String name) {
    return repository.createNewFolder(path, name);
  }
}
