enum ClipboardOperation { copy, cut }

class ClipboardService {
  ClipboardService._privateConstructor();
  static final ClipboardService instance = ClipboardService._privateConstructor();

  List<String> _paths = [];
  ClipboardOperation? _operation;

  void setCopy(List<String> paths) {
    _paths = List.from(paths);
    _operation = ClipboardOperation.copy;
  }

  void setCut(List<String> paths) {
    _paths = List.from(paths);
    _operation = ClipboardOperation.cut;
  }

  void clear() {
    _paths = [];
    _operation = null;
  }

  bool get hasItems => _paths.isNotEmpty && _operation != null;

  ClipboardOperation? get operation => _operation;

  List<String> get paths => List.unmodifiable(_paths);
}
