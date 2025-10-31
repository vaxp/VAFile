# VA File Manager

A comprehensive file manager for Linux with a macOS Finder-inspired interface, built with Flutter.

## Features

### 🎨 macOS-Style Interface
- **Dark Theme**: Beautiful dark theme matching macOS appearance
- **Traffic Light Controls**: macOS-style window controls (red, orange, green)
- **Sidebar Navigation**: Organized sidebar with Favourites, iCloud, Locations, Network, and Tags
- **Grid View**: Icon-based grid view for files and folders with visual file type indicators

### 📁 File Operations
- **Navigate**: Browse through directories with forward/back navigation
- **Rename**: Right-click or press F2 to rename files and folders
- **Delete**: Delete files and folders with confirmation dialog
- **Copy & Cut**: Copy and cut operations (keyboard shortcuts: Ctrl+C, Ctrl+X)
- **Paste**: Paste operations (keyboard shortcut: Ctrl+V)
- **Create Folder**: Create new folders in the current directory
- **File Details**: View detailed information about files (size, path, modified date, type)

### 🔍 Search Functionality
- **Real-time Search**: Search files and folders in the current directory
- **Instant Filtering**: Results update as you type in the search bar

### ⌨️ Keyboard Shortcuts
- **Delete**: Delete selected files
- **F2**: Rename selected file
- **Ctrl+C**: Copy selected files
- **Ctrl+X**: Cut selected files
- **Ctrl+V**: Paste files
- **Ctrl+A**: Select all files

### 🖱️ Context Menu (Right-Click)
- **Rename**: Rename the selected file or folder
- **Copy**: Copy the selected item
- **Cut**: Cut the selected item
- **Get Info**: View detailed file information
- **Move to Trash**: Delete the selected item

### 📍 Quick Navigation
- **Recents**: Access recently used files
- **Desktop**: Navigate to Desktop folder
- **Documents**: Navigate to Documents folder
- **Downloads**: Navigate to Downloads folder
- **Applications**: Navigate to Applications folder
- **Home**: Navigate to home directory
- **System Locations**: Quick access to system directories

### 🏷️ Visual Features
- **File Type Icons**: Different icons and colors for different file types
  - 📁 Folders (Blue)
  - 📄 Documents (White/Gray)
  - 📕 PDFs (Red)
  - 🖼️ Images (Green)
  - 🎥 Videos (Purple)
  - 🎵 Audio files (Orange)
  - 📦 Archives (Brown)
  - ⚙️ Executables (Blue)

- **Color Tags**: Organize files with color tags (Grey, Yellow, Red, Orange)
- **Status Bar**: Shows item count and available disk space
- **Visual Selection**: Clear visual feedback for selected items

## Installation

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Linux development tools
- CMake
- GTK development headers

### Setup
1. Clone or navigate to the project directory:
```bash
cd /home/x/Desktop/vafile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d linux
```

4. Build for production:
```bash
flutter build linux
```

## Project Structure

```
vafile/
├── lib/
│   ├── main.dart                    # Main application entry point
│   ├── models/
│   │   └── file_manager_state.dart  # State management and file operations
│   └── widgets/
│       ├── sidebar.dart             # Sidebar navigation component
│       ├── file_grid_view.dart      # File grid view component
│       └── context_menu.dart        # Context menu component
├── linux/                           # Linux platform specific files
├── pubspec.yaml                     # Project dependencies
└── README.md                        # This file
```

## Dependencies

- **provider**: State management
- **path**: File path manipulation
- **path_provider**: Access to common file system locations
- **file_picker**: File selection dialogs

## Usage

### Basic Navigation
1. Use the sidebar to quickly navigate to common locations
2. Click on folders in the grid view to open them
3. Use the back/forward buttons in the toolbar to navigate history
4. The current path is displayed in the toolbar

### File Operations
1. **Select**: Click on a file to select it
2. **Right-click**: Opens context menu with available operations
3. **Double-click folder**: Opens the folder
4. **Keyboard shortcuts**: Use standard shortcuts for quick operations

### Search
1. Type in the search bar at the top right
2. Results filter in real-time
3. Clear the search to show all files

## Customization

The application uses a dark theme by default. Colors and styling can be customized in `main.dart`:

```dart
colorScheme: const ColorScheme.dark(
  primary: Color(0xFF007AFF),      // macOS blue
  secondary: Color(0xFF5856D6),    // Purple accent
  surface: Color(0xFF2D2D2D),      // Surface color
  background: Color(0xFF1E1E1E),   // Background color
),
```

## Known Limitations

- Copy/Paste functionality is partially implemented
- Some advanced file operations may require additional permissions
- Network and iCloud features are placeholders

## Future Enhancements

- Full clipboard support for copy/paste operations
- Drag and drop functionality
- Multiple selection with Ctrl+Click
- List view and column view modes
- File preview with Quick Look
- Batch file operations
- Custom tags and favorites
- Network drive mounting
- File compression/extraction
- Advanced search with filters

## License

This project is open source and available for personal and commercial use.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Support

For issues, questions, or feature requests, please open an issue on the project repository.

---

**VA File Manager** - A powerful, modern file manager for Linux with a macOS-inspired interface.
# VAFile
# VAFile
