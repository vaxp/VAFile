import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/domain/file_manager_repository.dart';
import 'package:vafile/domain/vaxp.dart';
import 'package:vafile/infrastructure/file_manager_repository_impl.dart';
part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  // repository field already declared below, remove duplicate
  late final FileManagerRepository repository;

  String currentPath = '';
  List<FileItem> files = [];
  List<FileItem> filteredFiles = [];
  String searchQuery = '';
  bool showHiddenFiles = false;

  // navigation history stacks
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];

  FileManagerBloc({FileManagerRepository? repo}) : super(FileManagerInitial()) {
    repository = repo ?? FileManagerRepositoryImpl();

    on<InitializeFileManager>((event, emit) async {
      currentPath = '/home';
      _backStack.clear();
      _forwardStack.clear();
      emit(FileManagerLoading());
      try {
        files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
        filteredFiles = List<FileItem>.from(files);
        emit(FileManagerLoaded(
          currentPath: currentPath,
          files: files,
          filteredFiles: filteredFiles,
          searchQuery: searchQuery,
          availableSpace: '',
          viewMode: ViewMode.grid,
          showHiddenFiles: showHiddenFiles,
          showFileExtensions: true,
          canGoBack: _backStack.isNotEmpty,
          canGoForward: _forwardStack.isNotEmpty,
          sortBy: 'name',
          connectedDevices: const [],
        ));
      } catch (e) {
        emit(FileManagerError(e.toString()));
      }
    });

    on<LoadDirectory>((event, emit) async {
      // If requested to load a new directory, update history stacks
      emit(FileManagerLoading());
      try {
        if (event.path != currentPath) {
          // push current to back stack
          if (currentPath.isNotEmpty) {
            _backStack.add(currentPath);
          }
          // clear forward stack when navigating to a new path
          _forwardStack.clear();
        }

        currentPath = event.path;
        files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
        filteredFiles = List<FileItem>.from(files);
        emit(FileManagerLoaded(
          currentPath: currentPath,
          files: files,
          filteredFiles: filteredFiles,
          searchQuery: searchQuery,
          availableSpace: '',
          viewMode: ViewMode.grid,
          showHiddenFiles: showHiddenFiles,
          showFileExtensions: true,
          canGoBack: _backStack.isNotEmpty,
          canGoForward: _forwardStack.isNotEmpty,
          sortBy: 'name',
          connectedDevices: const [],
        ));
      } catch (e) {
        emit(FileManagerError(e.toString()));
      }
    });

    on<NavigateBack>((event, emit) async {
      if (_backStack.isEmpty) return;
      emit(FileManagerLoading());
      try {
        final target = _backStack.removeLast();
        // push current to forward stack
        if (currentPath.isNotEmpty) _forwardStack.add(currentPath);
        currentPath = target;
        files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
        filteredFiles = List<FileItem>.from(files);
        emit(FileManagerLoaded(
          currentPath: currentPath,
          files: files,
          filteredFiles: filteredFiles,
          searchQuery: searchQuery,
          availableSpace: '',
          viewMode: ViewMode.grid,
          showHiddenFiles: showHiddenFiles,
          showFileExtensions: true,
          canGoBack: _backStack.isNotEmpty,
          canGoForward: _forwardStack.isNotEmpty,
          sortBy: 'name',
          connectedDevices: const [],
        ));
      } catch (e) {
        emit(FileManagerError(e.toString()));
      }
    });

    on<NavigateForward>((event, emit) async {
      if (_forwardStack.isEmpty) return;
      emit(FileManagerLoading());
      try {
        final target = _forwardStack.removeLast();
        // push current to back stack
        if (currentPath.isNotEmpty) _backStack.add(currentPath);
        currentPath = target;
        files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
        filteredFiles = List<FileItem>.from(files);
        emit(FileManagerLoaded(
          currentPath: currentPath,
          files: files,
          filteredFiles: filteredFiles,
          searchQuery: searchQuery,
          availableSpace: '',
          viewMode: ViewMode.grid,
          showHiddenFiles: showHiddenFiles,
          showFileExtensions: true,
          canGoBack: _backStack.isNotEmpty,
          canGoForward: _forwardStack.isNotEmpty,
          sortBy: 'name',
          connectedDevices: const [],
        ));
      } catch (e) {
        emit(FileManagerError(e.toString()));
      }
    });

    on<SearchFiles>((event, emit) async {
      searchQuery = event.query;
    filteredFiles = searchQuery.isEmpty
      ? List<FileItem>.from(files)
      : files.where((file) => file.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      emit(FileManagerLoaded(
        currentPath: currentPath,
        files: files,
        filteredFiles: filteredFiles,
        searchQuery: searchQuery,
        availableSpace: '',
        viewMode: ViewMode.grid,
        showHiddenFiles: showHiddenFiles,
        showFileExtensions: true,
        canGoBack: _backStack.isNotEmpty,
        canGoForward: _forwardStack.isNotEmpty,
        sortBy: 'name',
        connectedDevices: const [],
      ));
    });

    on<RenameFile>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.renameFile(event.file, event.newName);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<DeleteFile>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.deleteFile(event.file);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<CopyFile>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.copyFile(event.file, event.destination);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<MoveFile>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.moveFile(event.file, event.destination);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<CompressFiles>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.compressFiles(event.files.map((f) => f.path).toList(), event.destination);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<ToggleHiddenFiles>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        showHiddenFiles = event.show;
        files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
        filteredFiles = List<FileItem>.from(files);
        emit(FileManagerLoaded(
          currentPath: currentPath,
          files: files,
          filteredFiles: filteredFiles,
          searchQuery: searchQuery,
          availableSpace: '',
          viewMode: currentState.viewMode,
          showHiddenFiles: showHiddenFiles,
          showFileExtensions: true,
          canGoBack: _backStack.isNotEmpty,
          canGoForward: _forwardStack.isNotEmpty,
          sortBy: currentState.sortBy,
          connectedDevices: currentState.connectedDevices,
        ));
      }
    });

    on<ChangeViewMode>((event, emit) {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        emit(currentState.copyWith(viewMode: event.viewMode));
      }
    });

    on<RefreshFileManager>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<CreateNewFolderEvent>((event, emit) async {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        try {
          await repository.createNewFolder(currentPath, event.name);
          files = await repository.loadDirectory(currentPath, showHiddenFiles: showHiddenFiles);
          filteredFiles = List<FileItem>.from(files);
          emit(FileManagerLoaded(
            currentPath: currentPath,
            files: files,
            filteredFiles: filteredFiles,
            searchQuery: searchQuery,
            availableSpace: '',
            viewMode: currentState.viewMode,
            showHiddenFiles: showHiddenFiles,
            showFileExtensions: true,
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            sortBy: currentState.sortBy,
            connectedDevices: currentState.connectedDevices,
          ));
        } catch (e) {
          emit(FileManagerError(e.toString()));
        }
      }
    });

    on<ChangeSortOrder>((event, emit) {
      if (state is FileManagerLoaded) {
        final currentState = state as FileManagerLoaded;
        var sortedFiles = List<FileItem>.from(currentState.files);
        switch (event.sortBy) {
          case 'name':
            sortedFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case 'size':
            sortedFiles.sort((a, b) => b.size.compareTo(a.size));
            break;
          case 'date':
            sortedFiles.sort((a, b) => b.modified.compareTo(a.modified));
            break;
          case 'type':
            sortedFiles.sort((a, b) => a.extension.toLowerCase().compareTo(b.extension.toLowerCase()));
            break;
        }
        emit(currentState.copyWith(
          files: sortedFiles,
          filteredFiles: sortedFiles,
          sortBy: event.sortBy,
        ));
      }
    });
  }
}
