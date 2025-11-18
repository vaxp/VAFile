# External Drag-and-Drop Limitation

## Current Issue

When dragging files from the file manager to external applications (like the desktop), the drag disappears when it reaches the window edge. This happens because:

1. **Flutter's Draggable** only works within the Flutter app window
2. **GTK drag source** must be triggered by a mouse button press on the GTK widget itself
3. Since Flutter's Draggable captures mouse events, GTK never gets a chance to start its own drag

## Current Implementation

The current implementation:
- Prepares GTK drag data when Flutter drag starts
- Enables GTK drag source on the Flutter view widget
- Stores file paths for GTK to retrieve via `drag-data-get` callback

However, GTK drag source cannot be programmatically started - it must be triggered by a mouse button press on the GTK widget.

## Potential Solutions

### Option 1: Use GTK Drag Source Directly (Recommended)
Instead of using Flutter's `Draggable` for external drags, detect mouse events at the GTK level and trigger GTK drag source directly. This would require:
- Adding mouse event handlers in the native code
- Detecting mouse down/up events on file items
- Starting GTK drag when mouse is pressed and moved

### Option 2: Hybrid Approach
Use Flutter's Draggable for internal drags (within the app) and GTK drag source for external drags. This would require:
- Detecting when drag is about to leave the window
- Canceling Flutter's drag
- Starting GTK drag (but this is still problematic since GTK drag can't be started programmatically)

### Option 3: Use a Different Widget
Replace Flutter's `Draggable` with a custom widget that uses `Listener` to detect mouse events and coordinates with GTK drag source.

## Current Workaround

The current implementation prepares the data, but external drags won't work until we implement one of the solutions above. Internal drags (within the app) continue to work normally.

