import '../vaxp.dart';

class SearchFiles {
  List<FileItem> call(List<FileItem> files, String query) {
    if (query.isEmpty) return List.from(files);
    return files.where((file) => file.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
