import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:path/path.dart' as p;
import 'package:markdown_widget/widget/markdown.dart';

/// A very small, local syntax-highlighting controller. It subclasses
/// [TextEditingController] and overrides [buildTextSpan] to return a
/// colored [TextSpan] tree. This keeps the feature dependency-free and
/// lightweight.
class SyntaxHighlightingController extends TextEditingController {
  final TextStyle baseStyle;

  SyntaxHighlightingController({String? text, TextStyle? baseStyle})
      : baseStyle = baseStyle ?? const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Courier New'),
        super(text: text ?? '');

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, bool withComposing = false}) {
    final defaultStyle = baseStyle.merge(style);
    final source = text;

    if (source.isEmpty) return TextSpan(style: defaultStyle, text: '');

    // Token styles
    final commentStyle = defaultStyle.copyWith(color: Colors.green[400]);
    final stringStyle = defaultStyle.copyWith(color: Colors.orange[300]);
    final numberStyle = defaultStyle.copyWith(color: Colors.purple[300]);
    final keywordStyle = defaultStyle.copyWith(color: Colors.blue[300], fontWeight: FontWeight.bold);
    final classStyle = defaultStyle.copyWith(color: Colors.teal[300], fontWeight: FontWeight.w600);
    final functionStyle = defaultStyle.copyWith(color: Colors.indigo[200]);
    final bracketStyle = defaultStyle.copyWith(color: Colors.yellow[300]);

    // Priority-ordered token matchers. Higher priority first to avoid being overridden.
    final List<_PatternStyle> matchers = [
      // Multi-line comments
      _PatternStyle(RegExp(r'/\*[\s\S]*?\*/'), commentStyle),
      // Single-line comments
      _PatternStyle(RegExp(r'//.*'), commentStyle),
      // Double-quoted strings
      _PatternStyle(RegExp(r'"(?:\\.|[^"\\])*"', dotAll: true), stringStyle),
      // Single-quoted strings
      _PatternStyle(RegExp(r"'(?:\\.|[^'\\])*'", dotAll: true), stringStyle),
      // Class declarations: capture the class name
      _PatternStyle(RegExp(r'\bclass\s+([A-Z][A-Za-z0-9_]*)'), classStyle, group: 1),
      // Function definitions or calls: identifier followed by '('
      _PatternStyle(RegExp(r'\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()'), functionStyle, group: 1),
      // Keywords
      _PatternStyle(RegExp(r'\b(class|final|var|void|int|double|String|if|else|for|while|return|import|as|async|await|new|const|true|false|static|late|final)\b'), keywordStyle),
      // Numbers
      _PatternStyle(RegExp(r'\b\d+(?:\.\d+)?\b'), numberStyle),
      // Brackets
      _PatternStyle(RegExp(r'[\[\]\{\}\(\)]'), bracketStyle),
    ];

    // Collect non-overlapping tokens
    final tokens = <_Token>[];

    for (final m in matchers) {
        for (final match in m.pattern.allMatches(source)) {
          int startIndex;
          int endIndex;
          if (m.groupIndex != null && m.groupIndex! > 0) {
            final whole = match.group(0);
            final sub = match.group(m.groupIndex!);
            if (whole == null || sub == null) continue;
            // Find the subgroup occurrence inside the whole match and compute absolute indices.
            final offsetInWhole = whole.indexOf(sub);
            if (offsetInWhole < 0) continue;
            startIndex = match.start + offsetInWhole;
            endIndex = startIndex + sub.length;
          } else {
            startIndex = match.start;
            endIndex = match.end;
          }
          if (startIndex < 0 || endIndex <= startIndex) continue;
          tokens.add(_Token(startIndex, endIndex, m.style));
        }
    }

    // Sort tokens and remove overlaps (keep earlier tokens' priority)
    tokens.sort((a, b) => a.start.compareTo(b.start));
    final nonOverlapping = <_Token>[];
    int cursor = 0;
    for (final t in tokens) {
      if (t.end <= cursor) continue; // fully covered
      if (t.start < cursor) {
        // trim
        nonOverlapping.add(_Token(cursor, t.end, t.style));
        cursor = t.end;
      } else {
        nonOverlapping.add(t);
        cursor = t.end;
      }
    }

    // Build spans
    final children = <TextSpan>[];
    int last = 0;
    for (final t in nonOverlapping) {
      if (t.start > last) {
        children.add(TextSpan(text: source.substring(last, t.start), style: defaultStyle));
      }
      children.add(TextSpan(text: source.substring(t.start, t.end), style: t.style));
      last = t.end;
    }
    if (last < source.length) children.add(TextSpan(text: source.substring(last), style: defaultStyle));

    return TextSpan(style: defaultStyle, children: children);
  }
}

class _PatternStyle {
  final RegExp pattern;
  final TextStyle style;
  final int? groupIndex;
  _PatternStyle(this.pattern, this.style, {int? group}) : groupIndex = group;
}

class _Token {
  final int start;
  final int end;
  final TextStyle style;
  _Token(this.start, this.end, this.style);
}

/// Simple undo/redo manager for text editing
class UndoRedoManager {
  final List<String> _history = [];
  int _currentIndex = -1;

  /// Initialize with the current text
  void init(String text) {
    _history.clear();
    _currentIndex = -1;
    push(text);
  }

  /// Push a new state onto the undo stack
  void push(String text) {
    // Remove any redo history when new change is made
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }
    _history.add(text);
    _currentIndex = _history.length - 1;
  }

  /// Undo to the previous state. Returns the previous text or null if at the beginning.
  String? undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  /// Redo to the next state. Returns the next text or null if at the end.
  String? redo() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }
}

class TextEditorPage extends StatefulWidget {
  final String filePath;

  const TextEditorPage({
    super.key,
    required this.filePath,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late SyntaxHighlightingController _controller;
  late File _file;
  bool _isModified = false;
  bool _isSaving = false;
  late UndoRedoManager _undoRedoManager;
  late ScrollController _editorTextScrollController;
  late ScrollController _editorLineNumbersScrollController;
  late ScrollController _previewScrollController;
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _file = File(widget.filePath);
    _controller = SyntaxHighlightingController();
    _undoRedoManager = UndoRedoManager();
    _editorTextScrollController = ScrollController();
    _editorLineNumbersScrollController = ScrollController();
    _previewScrollController = ScrollController();
    _loadFile();
    _controller.addListener(_onContentChanged);
    
    // Sync line numbers scroll with editor text scroll
    _editorTextScrollController.addListener(() {
      if (!_isSyncingScroll && _editorLineNumbersScrollController.hasClients && _previewScrollController.hasClients) {
        _isSyncingScroll = true;
        _editorLineNumbersScrollController.jumpTo(_editorTextScrollController.offset);
        _previewScrollController.jumpTo(_editorTextScrollController.offset);
        _isSyncingScroll = false;
      }
    });
    
    // Sync preview scroll to editor text
    _previewScrollController.addListener(() {
      if (!_isSyncingScroll && _editorTextScrollController.hasClients && _editorLineNumbersScrollController.hasClients) {
        _isSyncingScroll = true;
        _editorTextScrollController.jumpTo(_previewScrollController.offset);
        _editorLineNumbersScrollController.jumpTo(_previewScrollController.offset);
        _isSyncingScroll = false;
      }
    });
  }

  Future<void> _loadFile() async {
    try {
      final content = await _file.readAsString();
      setState(() {
        _controller.text = content;
        _undoRedoManager.init(content);
        _isModified = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading file: $e')),
        );
      }
    }
  }

  void _onContentChanged() {
    setState(() {
      _isModified = true;
    });
    // Push to undo stack on each change
    _undoRedoManager.push(_controller.text);
  }

  void _handleUndo() {
    final prevText = _undoRedoManager.undo();
    if (prevText != null) {
      _controller.removeListener(_onContentChanged);
      _controller.text = prevText;
      _controller.addListener(_onContentChanged);
      setState(() {
        _isModified = true;
      });
    }
  }

  void _handleRedo() {
    final nextText = _undoRedoManager.redo();
    if (nextText != null) {
      _controller.removeListener(_onContentChanged);
      _controller.text = nextText;
      _controller.addListener(_onContentChanged);
      setState(() {
        _isModified = true;
      });
    }
  }

  Future<void> _saveFile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _file.writeAsString(_controller.text);
      setState(() {
        _isModified = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorTextScrollController.dispose();
    _editorLineNumbersScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.filePath);
    final isMarkdown = _isMarkdownFile(widget.filePath);

    return WillPopScope(
      onWillPop: () async {
        if (_isModified) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(188, 0, 0, 0),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.filePath,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isModified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: Text(
                    'Modified',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (_isSupportedFile(p.extension(widget.filePath)))
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                tooltip: 'Run',
                onPressed: _runFile,
              ),
            IconButton(
              icon: Icon(
                _isSaving ? Icons.hourglass_bottom : Icons.save,
                color: _isSaving ? Colors.white54 : Colors.white70,
              ),
              tooltip: 'Save',
              onPressed: _isSaving ? null : (_isModified ? _saveFile : null),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: 'Close',
              onPressed: () async {
                if (_isModified) {
                  final shouldClose = await _showUnsavedChangesDialog();
                  if (shouldClose && mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: isMarkdown ? _buildMarkdownEditor() : _buildRegularEditor(),
      ),
    );
  }

  /// Build the regular editor UI for non-markdown files
  Widget _buildRegularEditor() {
    return Focus(
      onKey: (node, event) {
        // Ctrl+S to save
        if (event.isControlPressed && event.logicalKey.keyLabel == 's') {
          if (_isModified) _saveFile();
          return KeyEventResult.handled;
        }
        // Ctrl+Z to undo
        if (event.isControlPressed && event.logicalKey.keyLabel == 'z') {
          _handleUndo();
          return KeyEventResult.handled;
        }
        // Ctrl+Y to redo
        if (event.isControlPressed && event.logicalKey.keyLabel == 'y') {
          _handleRedo();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF404040),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Line ${_getLineNumber()}, Column ${_getColumnNumber()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                Text(
                  _getFileSize(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Text editor with integrated line numbers
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      controller: _editorTextScrollController,
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: false,
                        minLines: null,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Courier New',
                          height: 1.7,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF404040),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF404040),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF007AFF),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(188, 0, 0, 0),
                          hintText: 'Start typing...',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          // Prefix with line numbers
                          prefixIcon: Container(
                            width: 50,
                            padding: const EdgeInsets.only(right: 8),
                            constraints: const BoxConstraints(maxWidth: 50),
                            child: SingleChildScrollView(
                              controller: _editorLineNumbersScrollController,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.max,
                                children: List.generate(
                                  _getLineCount(),
                                  (index) => Container(
                                    height: 23.6,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white24,
                                        fontFamily: 'Courier New',
                                        height: 1.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 50,
                            maxWidth: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the markdown editor with split-screen view (code + preview)
  Widget _buildMarkdownEditor() {
    return Focus(
      onKey: (node, event) {
        // Ctrl+S to save
        if (event.isControlPressed && event.logicalKey.keyLabel == 's') {
          if (_isModified) _saveFile();
          return KeyEventResult.handled;
        }
        // Ctrl+Z to undo
        if (event.isControlPressed && event.logicalKey.keyLabel == 'z') {
          _handleUndo();
          return KeyEventResult.handled;
        }
        // Ctrl+Y to redo
        if (event.isControlPressed && event.logicalKey.keyLabel == 'y') {
          _handleRedo();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          // Left side: Markdown code editor
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF404040),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: Color(0xFF404040),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Line ${_getLineNumber()}, Column ${_getColumnNumber()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getFileSize(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Text editor with integrated line numbers
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            controller: _editorTextScrollController,
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: false,
                              minLines: null,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Courier New',
                                height: 1.7,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF404040),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF404040),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007AFF),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(188, 0, 0, 0),
                                hintText: 'Start typing...',
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                                // Prefix with line numbers
                                prefixIcon: Container(
                                  width: 50,
                                  padding: const EdgeInsets.only(right: 8),
                                  constraints: const BoxConstraints(maxWidth: 50),
                                  child: SingleChildScrollView(
                                    controller: _editorLineNumbersScrollController,
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.max,
                                      children: List.generate(
                                        _getLineCount(),
                                        (index) => Container(
                                          height: 23.6,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white24,
                                              fontFamily: 'Courier New',
                                              height: 1.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 50,
                                  maxWidth: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side: Markdown preview
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFF404040),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF404040),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF404040),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          controller: _previewScrollController,
                          padding: const EdgeInsets.all(12),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Courier New',
                              height: 1.7,
                            ),
                            child: MarkdownWidget(
                              data: _controller.text,
                              shrinkWrap: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getLineNumber() {
    final text = _controller.text;
    final cursorPosition = _controller.selection.start;
    int lineNumber = 1;
    for (int i = 0; i < cursorPosition && i < text.length; i++) {
      if (text[i] == '\n') {
        lineNumber++;
      }
    }
    return lineNumber;
  }

  int _getColumnNumber() {
    final text = _controller.text;
    final cursorPosition = _controller.selection.start;
    int columnNumber = 1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '\n') {
        break;
      }
      columnNumber++;
    }
    return columnNumber;
  }

  String _getFileSize() {
    final bytes = _controller.text.length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int _getLineCount() {
    if (_controller.text.isEmpty) return 1;
    return '\n'.allMatches(_controller.text).length + 1;
  }

  Future<void> _runFile() async {
    final extension = p.extension(widget.filePath);
    if (!_isSupportedFile(extension)) {
      _showErrorDialog('File type not supported', 'Only .sh, .dart, and .py files are supported.');
      return;
    }

    // Save the file first before running
    if (_isModified) {
      await _saveFile();
    }

    _showExecutionDialog();
  }

  bool _isSupportedFile(String extension) {
    return ['.sh', '.dart', '.py'].contains(extension.toLowerCase());
  }

  bool _isMarkdownFile(String filePath) {
    return p.extension(filePath).toLowerCase() == '.md';
  }

  Future<String> _executeFile() async {
    final extension = p.extension(widget.filePath).toLowerCase();
    final filePath = widget.filePath;
    
    try {
      ProcessResult result;
      
      switch (extension) {
        case '.sh':
          result = await Process.run('bash', [filePath]);
          break;
        case '.dart':
          result = await Process.run('dart', [filePath]);
          break;
        case '.py':
          result = await Process.run('python3', [filePath]);
          break;
        default:
          return 'Unsupported file type';
      }

      final stdout = result.stdout.toString();
      final stderr = result.stderr.toString();
      final exitCode = result.exitCode;

      if (exitCode == 0) {
        return stdout.isNotEmpty ? stdout : '(No output)';
      } else {
        return 'Exit code: $exitCode\n\nError:\n$stderr';
      }
    } catch (e) {
      return 'Error running file: $e';
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showExecutionDialog() async {
    final output = await _executeFile();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          title: const Text(
            'Execution Output',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(0, 0, 0, 0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                output,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 12,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(188, 0, 0, 0),
            title: const Text(
              'Unsaved Changes',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Do you want to save changes to ${p.basename(widget.filePath)}?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _saveFile();
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
