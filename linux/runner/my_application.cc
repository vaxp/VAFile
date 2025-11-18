#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <gtk/gtk.h>
#include <string.h>
#include <vector>
#include <string>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Forward declarations
static void setup_external_drag(FlView* view, GtkWindow* window);
static void setup_clipboard(FlView* view);

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView *view)
{
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  GtkWidget* window_widget = GTK_WIDGET(window);
  gtk_widget_set_app_paintable(window_widget, TRUE);
  GdkScreen* screen = gtk_window_get_screen(window);

#if GTK_CHECK_VERSION(3, 0, 0)
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr) {
    gtk_widget_set_visual(window_widget, visual);
  }
#endif

  // === (بدء الكود لجعل الخلفية بلور) ===
  {
    GtkCssProvider* blur_provider = gtk_css_provider_new();
    const gchar* blur_css =
        "window {"
        "  background-color: rgba(0, 0, 0, 0.25);"
        "  backdrop-filter: blur(25px);"
        "  -gtk-backdrop-filter: blur(25px);"
        "}";

    gtk_css_provider_load_from_data(blur_provider, blur_css, -1, NULL);
    gtk_style_context_add_provider_for_screen(
        gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(blur_provider),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(blur_provider);
  }
  // === (نهاية الكود) ===

  // Header bar setup
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());

    GtkCssProvider* provider = gtk_css_provider_new();
    const gchar* css = "headerbar { background-color: rgba(0, 0, 0, 0.635); }";
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    GtkStyleContext* context = gtk_widget_get_style_context(GTK_WIDGET(header_bar));
    gtk_style_context_add_provider(context, GTK_STYLE_PROVIDER(provider),
                                   GTK_STYLE_PROVIDER_PRIORITY_USER);
    g_object_unref(provider);

    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "vafile");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "vafile");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#00000000"); // شفافية كاملة
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  gtk_widget_grab_focus(GTK_WIDGET(view));

  // Set up external drag-and-drop support
  setup_external_drag(view, window);
  
  // Set up clipboard support
  setup_clipboard(view);
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;
  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

// Global variables for drag-and-drop
static FlMethodChannel* drag_channel = nullptr;
static std::vector<std::string> drag_paths;
static GtkWidget* drag_widget = nullptr;
static GtkTargetList* drag_target_list = nullptr;
static GtkWindow* main_window = nullptr;
static bool is_flutter_dragging = false;
static GdkDragContext* active_gtk_drag = nullptr;

// Global variables for clipboard
static FlMethodChannel* clipboard_channel = nullptr;

// GTK drag data get callback
static void drag_data_get_cb(GtkWidget* widget, GdkDragContext* context,
                             GtkSelectionData* data, guint info, guint time,
                             gpointer user_data) {
  if (drag_paths.empty()) {
    return;
  }

  // Create URI list for drag data
  GString* uri_list = g_string_new(NULL);
  for (const auto& path : drag_paths) {
    // Convert path to file:// URI
    gchar* uri = g_filename_to_uri(path.c_str(), NULL, NULL);
    if (uri) {
      g_string_append(uri_list, uri);
      g_string_append(uri_list, "\r\n");
      g_free(uri);
    }
  }

  // Set the data with text/uri-list format
  gtk_selection_data_set(data, gdk_atom_intern("text/uri-list", FALSE),
                         8, (const guchar*)uri_list->str, uri_list->len);
  g_string_free(uri_list, TRUE);
}

// GTK drag begin callback
static void drag_begin_cb(GtkWidget* widget, GdkDragContext* context,
                          gpointer user_data) {
  // Set a custom drag icon (optional)
  // For now, we'll use the default
}

// Mouse motion handler - detect when drag approaches window edge
static gboolean motion_notify_cb(GtkWidget* widget, GdkEventMotion* event,
                                  gpointer user_data) {
  // Only handle if Flutter drag is active and we have paths
  if (!is_flutter_dragging || drag_paths.empty() || !main_window) {
    return FALSE;
  }

  // Get window dimensions
  gint width, height;
  gtk_window_get_size(main_window, &width, &height);
  
  // Get mouse position relative to window
  gdouble x = event->x;
  gdouble y = event->y;
  
  // Define edge threshold (in pixels)
  const gdouble edge_threshold = 20.0;
  
  // Check if mouse is near any window edge
  gboolean near_edge = (x < edge_threshold) || 
                       (x > width - edge_threshold) ||
                       (y < edge_threshold) || 
                       (y > height - edge_threshold);
  
  if (near_edge && active_gtk_drag == nullptr) {
    // Mouse is near edge and GTK drag hasn't started yet
    // Start GTK drag programmatically using the motion event
    // Check if widget is realized first
    if (!gtk_widget_get_realized(widget)) {
      gtk_widget_realize(widget);
    }
    
    GdkWindow* gdk_window = gtk_widget_get_window(widget);
    if (gdk_window) {
      // Create a button press event from the motion event
      GdkEvent* button_event = gdk_event_new(GDK_BUTTON_PRESS);
      GdkEventButton* be = &button_event->button;
      be->window = g_object_ref(gdk_window);
      be->time = event->time;
      be->x = x;
      be->y = y;
      be->x_root = event->x_root;
      be->y_root = event->y_root;
      be->button = 1;  // Left mouse button
      be->state = event->state;
      be->type = GDK_BUTTON_PRESS;
      
      // Start GTK drag
      active_gtk_drag = gtk_drag_begin_with_coordinates(
          widget, drag_target_list, GDK_ACTION_COPY, 1, button_event, 
          (gint)x, (gint)y);
      
      if (active_gtk_drag) {
        g_object_ref(active_gtk_drag);
      }
      
      gdk_event_free(button_event);
    }
  }
  
  return FALSE;  // Let other handlers process the event
}

// Mouse button release handler - clean up drag state
static gboolean button_release_cb(GtkWidget* widget, GdkEventButton* event,
                                   gpointer user_data) {
  if (active_gtk_drag) {
    g_object_unref(active_gtk_drag);
    active_gtk_drag = nullptr;
  }
  is_flutter_dragging = false;
  return FALSE;
}

// GTK drag end callback
static void drag_end_cb(GtkWidget* widget, GdkDragContext* context,
                        gpointer user_data) {
  if (active_gtk_drag == context) {
    if (active_gtk_drag) {
      g_object_unref(active_gtk_drag);
    }
    active_gtk_drag = nullptr;
    is_flutter_dragging = false;
  }
}

// Method call handler for external drag
static void handle_method_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "startDrag") == 0) {
    // Get paths from arguments and store them
    drag_paths.clear();
    FlValue* paths_value = fl_value_lookup_string(args, "paths");
    if (paths_value && fl_value_get_type(paths_value) == FL_VALUE_TYPE_LIST) {
      size_t length = fl_value_get_length(paths_value);
      for (size_t i = 0; i < length; i++) {
        FlValue* path_value = fl_value_get_list_value(paths_value, i);
        if (fl_value_get_type(path_value) == FL_VALUE_TYPE_STRING) {
          const gchar* path = fl_value_get_string(path_value);
          drag_paths.push_back(std::string(path));
        }
      }
    }

    // Store the paths for when drag-data-get is called
    // Mark that Flutter drag is active so we can detect when to start GTK drag
    is_flutter_dragging = true;
    active_gtk_drag = nullptr;  // Reset any previous GTK drag

    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "endDrag") == 0) {
    // Flutter drag has ended, clean up state
    is_flutter_dragging = false;
    // Don't clear drag_paths yet - GTK drag might still be active
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// Global storage for clipboard data (needs to persist)
static GString* clipboard_uri_list = nullptr;

// Clipboard callbacks
static void clipboard_get_cb(GtkClipboard* clipboard, GtkSelectionData* selection_data, guint info, gpointer user_data) {
  if (clipboard_uri_list && clipboard_uri_list->str) {
    gtk_selection_data_set(selection_data,
                          gdk_atom_intern("text/uri-list", FALSE),
                          8,
                          (const guchar*)clipboard_uri_list->str,
                          clipboard_uri_list->len);
  }
}

static void clipboard_clear_cb(GtkClipboard* clipboard, gpointer user_data) {
  if (clipboard_uri_list) {
    g_string_free(clipboard_uri_list, TRUE);
    clipboard_uri_list = nullptr;
  }
}

// Method call handler for clipboard operations
static void handle_clipboard_method_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (!method) {
    g_warning("Method name is null");
    fl_method_call_respond_error(method_call, "INVALID_METHOD", "Method name is null", nullptr, nullptr);
    return;
  }

  if (strcmp(method, "setFileUris") == 0) {
    if (!args) {
      g_warning("Arguments are null");
      fl_method_call_respond_error(method_call, "INVALID_ARGUMENT", "Arguments are null", nullptr, nullptr);
      return;
    }
    
    // Get paths from arguments
    FlValue* paths_value = fl_value_lookup_string(args, "paths");
    
    if (paths_value && fl_value_get_type(paths_value) == FL_VALUE_TYPE_LIST) {
      // Get the default clipboard
      GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
      
      if (!clipboard) {
        g_warning("Failed to get clipboard");
        fl_method_call_respond_error(method_call, "CLIPBOARD_ERROR", "Failed to get clipboard", nullptr, nullptr);
        return;
      }
      
      // Clear clipboard ownership first to ensure we can set new data
      // This is important if the clipboard is still owned from a previous operation
      gtk_clipboard_clear(clipboard);
      
      // Clear any existing clipboard data from our storage
      if (clipboard_uri_list) {
        g_string_free(clipboard_uri_list, TRUE);
        clipboard_uri_list = nullptr;
      }
      
      // Build URI list string (text/uri-list format)
      clipboard_uri_list = g_string_new(NULL);
      size_t length = fl_value_get_length(paths_value);
      
      for (size_t i = 0; i < length; i++) {
        FlValue* path_value = fl_value_get_list_value(paths_value, i);
        if (fl_value_get_type(path_value) == FL_VALUE_TYPE_STRING) {
          const gchar* path = fl_value_get_string(path_value);
          // Convert path to file:// URI
          gchar* uri = g_filename_to_uri(path, NULL, NULL);
          if (uri) {
            g_string_append(clipboard_uri_list, uri);
            g_string_append(clipboard_uri_list, "\r\n");  // CRLF line endings for uri-list format
            g_free(uri);
          } else {
            g_warning("Failed to convert path to URI: %s", path);
          }
        }
      }
      
      if (clipboard_uri_list->len == 0) {
        g_warning("No valid URIs to set in clipboard");
        g_string_free(clipboard_uri_list, TRUE);
        clipboard_uri_list = nullptr;
        fl_method_call_respond_error(method_call, "INVALID_DATA", "No valid file paths", nullptr, nullptr);
        return;
      }
      
      // Set clipboard data with text/uri-list target
      GtkTargetEntry target = {(gchar*)"text/uri-list", 0, 0};
      gboolean success = gtk_clipboard_set_with_data(clipboard, &target, 1,
                                                     clipboard_get_cb,
                                                     clipboard_clear_cb,
                                                     nullptr);
      
      if (!success) {
        g_warning("Failed to set clipboard data - clipboard may be owned by another application");
        g_string_free(clipboard_uri_list, TRUE);
        clipboard_uri_list = nullptr;
        fl_method_call_respond_error(method_call, "CLIPBOARD_ERROR", "Failed to set clipboard data", nullptr, nullptr);
        return;
      }
      
      // Store the clipboard data so it persists
      gtk_clipboard_store(clipboard);
      
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    } else {
      g_warning("Invalid paths argument: paths_value=%p, type=%d", paths_value, paths_value ? fl_value_get_type(paths_value) : -1);
      fl_method_call_respond_error(method_call, "INVALID_ARGUMENT", "Paths argument is required or invalid", nullptr, nullptr);
      return;
    }
  } else {
    g_warning("Unknown method: %s", method);
    fl_method_call_respond_not_implemented(method_call, nullptr);
    return;
  }
}

// Set up clipboard support
static void setup_clipboard(FlView* view) {
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(fl_view_get_engine(view));
  if (!messenger) {
    g_warning("setup_clipboard: Failed to get binary messenger");
    return;
  }
  
  FlStandardMethodCodec* codec = fl_standard_method_codec_new();
  if (!codec) {
    g_warning("setup_clipboard: Failed to create method codec");
    return;
  }
  
  clipboard_channel = fl_method_channel_new(messenger, "vafile/clipboard", FL_METHOD_CODEC(codec));
  g_object_unref(codec);
  
  if (!clipboard_channel) {
    g_warning("setup_clipboard: Failed to create method channel");
    return;
  }
  
  fl_method_channel_set_method_call_handler(clipboard_channel, handle_clipboard_method_call, view, nullptr);
}

// Set up external drag support
static void setup_external_drag(FlView* view, GtkWindow* window) {
  // Store window reference for getting dimensions
  main_window = window;
  
  // Create method channel
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(fl_view_get_engine(view));
  FlStandardMethodCodec* codec = fl_standard_method_codec_new();
  drag_channel = fl_method_channel_new(
      messenger, "vafile/external_drag", FL_METHOD_CODEC(codec));
  g_object_unref(codec);
  
  // Set method call handler
  fl_method_channel_set_method_call_handler(drag_channel, handle_method_call, view, nullptr);

  // Set up GTK drag source on the Flutter view widget
  // This allows dragging files to external applications
  GtkWidget* widget = GTK_WIDGET(view);
  drag_widget = widget;
  
  // Create target list for drag-and-drop
  drag_target_list = gtk_target_list_new(NULL, 0);
  gtk_target_list_add_uri_targets(drag_target_list, 0);
  gtk_target_list_add_text_targets(drag_target_list, 0);
  
  // Connect drag signals
  g_signal_connect(widget, "drag-begin", G_CALLBACK(drag_begin_cb), NULL);
  g_signal_connect(widget, "drag-data-get", G_CALLBACK(drag_data_get_cb), NULL);
  g_signal_connect(widget, "drag-end", G_CALLBACK(drag_end_cb), NULL);
  
  // Connect mouse motion to detect when drag approaches window edge
  gtk_widget_add_events(widget, GDK_POINTER_MOTION_MASK | GDK_BUTTON_RELEASE_MASK);
  g_signal_connect(widget, "motion-notify-event", G_CALLBACK(motion_notify_cb), NULL);
  g_signal_connect(widget, "button-release-event", G_CALLBACK(button_release_cb), NULL);
  
  // Always enable GTK drag source so it can handle external drags
  // The drag-data-get callback will only provide data when we have file paths
  gtk_drag_source_set_target_list(widget, drag_target_list);
}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}

