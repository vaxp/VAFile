
part of 'file_manager_bloc.dart';

abstract class FileManagerEvent extends Equatable {
  const FileManagerEvent();

  @override
  List<Object?> get props => [];
}

class InitializeFileManager extends FileManagerEvent {}
class LoadDirectory extends FileManagerEvent {
  final String path;
  // when false, don't add this navigation to history stacks (used by back/forward)
  final bool addToHistory;
  const LoadDirectory(this.path, {this.addToHistory = true});
  @override
  List<Object?> get props => [path, addToHistory];
}

class NavigateBack extends FileManagerEvent {}
class NavigateForward extends FileManagerEvent {}
class SearchFiles extends FileManagerEvent {
  final String query;
  const SearchFiles(this.query);
  @override
  List<Object?> get props => [query];
}

class RenameFile extends FileManagerEvent {
  final FileItem file;
  final String newName;
  const RenameFile(this.file, this.newName);
  @override
  List<Object?> get props => [file, newName];
}

class DeleteFile extends FileManagerEvent {
  final FileItem file;
  const DeleteFile(this.file);
  @override
  List<Object?> get props => [file];
}

class CopyFile extends FileManagerEvent {
  final FileItem file;
  final String destination;
  const CopyFile(this.file, this.destination);
  @override
  List<Object?> get props => [file, destination];
}

class MoveFile extends FileManagerEvent {
  final FileItem file;
  final String destination;
  const MoveFile(this.file, this.destination);
  @override
  List<Object?> get props => [file, destination];
}

class CompressFiles extends FileManagerEvent {
  final List<FileItem> files;
  final String destination;
  final String archiveFormat; // 'zip', 'tar', 'tar.gz', 'tar.bz2', '7z'
  const CompressFiles(this.files, this.destination, {this.archiveFormat = 'zip'});
  @override
  List<Object?> get props => [files, destination, archiveFormat];
}

class ExtractArchive extends FileManagerEvent {
  final FileItem archiveFile;
  final String destinationPath;
  const ExtractArchive(this.archiveFile, this.destinationPath);
  @override
  List<Object?> get props => [archiveFile, destinationPath];
}

class ToggleHiddenFiles extends FileManagerEvent {
  final bool show;
  const ToggleHiddenFiles(this.show);
  @override
  List<Object?> get props => [show];
}

class ChangeViewMode extends FileManagerEvent {
  final ViewMode viewMode;
  const ChangeViewMode(this.viewMode);
  @override
  List<Object?> get props => [viewMode];
}

class ChangeSortOrder extends FileManagerEvent {
  final String sortBy;
  const ChangeSortOrder(this.sortBy);
  @override
  List<Object?> get props => [sortBy];
}

class CreateNewFolderEvent extends FileManagerEvent {
  final String name;
  const CreateNewFolderEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class RefreshFileManager extends FileManagerEvent {
  const RefreshFileManager();
}

class ChangeSortBy extends FileManagerEvent {
  final String sortBy;
  const ChangeSortBy(this.sortBy);
  @override
  List<Object?> get props => [sortBy];
}

class ToggleFileExtensions extends FileManagerEvent {
  final bool show;
  const ToggleFileExtensions(this.show);
  @override
  List<Object?> get props => [show];
}

class CheckConnectedDevices extends FileManagerEvent {
  const CheckConnectedDevices();
}

class UpdateConnectedDevices extends FileManagerEvent {
  final List<DeviceInfo> devices;
  const UpdateConnectedDevices(this.devices);
  @override
  List<Object?> get props => [devices];
}
