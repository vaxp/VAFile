
part of 'file_manager_bloc.dart';

abstract class FileManagerState extends Equatable {
  const FileManagerState();
  @override
  List<Object?> get props => [];
}

class FileManagerInitial extends FileManagerState {}
class FileManagerLoading extends FileManagerState {}
class FileManagerLoaded extends FileManagerState {
  final String currentPath;
  final List<FileItem> files;
  final List<FileItem> filteredFiles;
  final String searchQuery;
  final String availableSpace;
  final ViewMode viewMode;
  final bool showHiddenFiles;
  final bool showFileExtensions;
  final bool canGoBack;
  final bool canGoForward;
  final String sortBy;
  final List<DeviceInfo> connectedDevices;

  const FileManagerLoaded({
    required this.currentPath,
    required this.files,
    required this.filteredFiles,
    required this.searchQuery,
    required this.availableSpace,
    required this.viewMode,
    required this.showHiddenFiles,
    required this.showFileExtensions,
    required this.canGoBack,
    required this.canGoForward,
    required this.sortBy,
    required this.connectedDevices,
  });

  FileManagerLoaded copyWith({
    String? currentPath,
    List<FileItem>? files,
    List<FileItem>? filteredFiles,
    String? searchQuery,
    String? availableSpace,
    ViewMode? viewMode,
    bool? showHiddenFiles,
    bool? showFileExtensions,
    String? sortBy,
    List<DeviceInfo>? connectedDevices,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    return FileManagerLoaded(
      currentPath: currentPath ?? this.currentPath,
      files: files ?? this.files,
      filteredFiles: filteredFiles ?? this.filteredFiles,
      searchQuery: searchQuery ?? this.searchQuery,
      availableSpace: availableSpace ?? this.availableSpace,
      viewMode: viewMode ?? this.viewMode,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      showFileExtensions: showFileExtensions ?? this.showFileExtensions,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      sortBy: sortBy ?? this.sortBy,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }

  @override
  List<Object?> get props => [
    currentPath,
    files,
    filteredFiles,
    searchQuery,
    availableSpace,
    viewMode,
    showHiddenFiles,
    showFileExtensions,
    sortBy,
    connectedDevices,
    canGoBack,
    canGoForward,
  ];
}
class FileManagerError extends FileManagerState {
  final String message;
  const FileManagerError(this.message);
  @override
  List<Object?> get props => [message];
}
