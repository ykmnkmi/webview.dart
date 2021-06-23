import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _CWCreate = Pointer<Void> Function(Int32 debug, Pointer<Void> window);
typedef _DWCreate = Pointer<Void> Function(int debug, Pointer<Void> window);

typedef _CWVGetWindow = Pointer<Void> Function(Pointer<Void> webview);
typedef _DartWVGetWindow = Pointer<Void> Function(Pointer<Void> webview);

typedef _CWSetSize = Void Function(
    Pointer<Void> webview, Int32 width, Int32 height, Int32 hint);
typedef _DWSetSize = void Function(
    Pointer<Void> webview, int width, int height, int hint);

typedef _CWVCb = Void Function(Pointer<Void> webview);
typedef _DWVCb = void Function(Pointer<Void> webview);

typedef _CWVStringCb = Void Function(Pointer<Void> webview, Pointer<Utf8> url);
typedef _DWVStringCb = void Function(Pointer<Void> webview, Pointer<Utf8> url);

class WebviewBindings {
  factory WebviewBindings([String? path]) {
    if (path == null) {
      switch (Platform.operatingSystem) {
        case 'windows':
          path = 'webview.dll';
          break;
        default:
          throw UnsupportedError(Platform.operatingSystem);
      }
    }

    return WebviewBindings.from(DynamicLibrary.open(path));
  }

  WebviewBindings.from(this.library)
      : create = library.lookupFunction<_CWCreate, _DWCreate>('webview_create'),
        destroy = library.lookupFunction<_CWVCb, _DWVCb>('webview_destroy'),
        run = library.lookupFunction<_CWVCb, _DWVCb>('webview_run'),
        terminate = library.lookupFunction<_CWVCb, _DWVCb>('webview_terminate'),
        getWindow = library.lookupFunction<_CWVGetWindow, _DartWVGetWindow>(
            'webview_get_window'),
        setTitle = library
            .lookupFunction<_CWVStringCb, _DWVStringCb>('webview_set_title'),
        setSize =
            library.lookupFunction<_CWSetSize, _DWSetSize>('webview_set_size'),
        navigate = library
            .lookupFunction<_CWVStringCb, _DWVStringCb>('webview_navigate'),
        init =
            library.lookupFunction<_CWVStringCb, _DWVStringCb>('webview_init'),
        eval =
            library.lookupFunction<_CWVStringCb, _DWVStringCb>('webview_eval');

  final DynamicLibrary library;

  /// Creates a new native webview instance.
  ///
  /// If `debug` is non-zero - developer tools will be enabled (if the
  /// platform supports them). Window parameter can be a pointer to the native
  /// window handle. If it's non-null - then child WebView is embedded into
  /// the given parent window. Otherwise a new window is created. Depending on
  /// the platform, a GtkWindow, NSWindow or HWND pointer can be passed here.
  final _DWCreate create;

  /// Destroys a webview and closes the native window.
  final _DWVCb destroy;

  /// Runs the main loop until it's terminated.
  ///
  /// After this function exits - you must destroy the webview.
  final _DWVCb run;

  /// Stops the main loop.
  final _DWVCb terminate;

  /// Returns a native window handle pointer.
  ///
  /// When using GTK backend the pointer is GtkWindow pointer, when using
  /// Cocoa backend the pointer is NSWindow pointer, when using Win32 backend
  /// the pointer is HWND pointer.
  final _DartWVGetWindow getWindow;

  /// Updates the title of the native window.
  final _DWVStringCb setTitle;

  /// Updates native window size.
  ///
  /// 0 - width and height are default size,
  /// 1 - width and height are minimum bounds,
  /// 2 - width and height are maximum bounds,
  /// 3 - window size can not be changed by a user.
  final _DWSetSize setSize;

  /// Navigates webview to the given URL.
  ///
  /// URL may be a data URI, i.e. "data:text/text,<html>...</html>".
  /// It is often ok not to url-encode it properly,
  /// webview will re-encode it for you.
  final _DWVStringCb navigate;

  final _DWVStringCb init;

  final _DWVStringCb eval;
}

/// Window size hints.
enum WebviewHint {
  /// Width and height are default size.
  none,

  /// Width and height are minimum bounds.
  min,

  /// Width and height are maximum bounds.
  max,

  /// Window size can not be changed by a user.
  fixed,
}

class Webview {
  /// Creates a new `Webview`.
  ///
  /// If `debug` is non-zero - developer tools will be enabled (if the
  /// platform supports them).
  Webview({bool debug = false, String? libraryPath, Pointer<Void>? window})
      : library = WebviewBindings(libraryPath) {
    webviewRef = library.create(debug ? 1 : 0, window ?? nullptr);
  }

  /// Creates a new `Webview` with specified [WebviewBindings] wrapper.
  ///
  /// If `debug` is non-zero - developer tools will be enabled (if the
  /// platform supports them). Window parameter can be a pointer to the native
  /// window handle. If it's non-null - then child WebView is embedded into
  /// the given parent window. Otherwise a new window is created. Depending on
  /// the platform, a GtkWindow, NSWindow or HWND pointer can be passed here.
  Webview.fromLibrary(this.library, {bool debug = false, Pointer<Void>? window})
      : webviewRef = library.create(debug ? 1 : 0, window ?? nullptr);

  final WebviewBindings library;

  /// Pointer to native webview instance.
  late final Pointer<Void> webviewRef;

  /// Returns a native window handle pointer.
  ///
  /// When using GTK backend the pointer is GtkWindow pointer, when using
  /// Cocoa backend the pointer is NSWindow pointer, when using Win32 backend
  /// the pointer is HWND pointer.
  Pointer<Void> get windowRef {
    return library.getWindow(webviewRef);
  }

  /// Updates the title of the native window.
  set title(String title) {
    final titleRef = title.toNativeUtf8();
    library.setTitle(webviewRef, titleRef);
    calloc.free(titleRef);
  }

  /// Destroys a webview and closes the native window.
  void destroy() {
    library.destroy(webviewRef);
  }

  /// Runs the main loop until it's terminated.
  ///
  /// After this function exits - you must destroy the webview.
  void run() {
    library.run(webviewRef);
  }

  /// Stops the main loop.
  void terminate() {
    library.terminate(webviewRef);
  }

  /// Updates native window size.
  void resize(int width, int height, WebviewHint hint) {
    library.setSize(webviewRef, width, height, hint.index);
  }

  /// Navigates webview to the given URL.
  ///
  /// URL may be a data URI, i.e. "data:text/text,<html>...</html>".
  /// It is often ok not to url-encode it properly,
  /// webview will re-encode it for you.
  void navigate(String url) {
    final urlRef = url.toNativeUtf8();
    library.navigate(webviewRef, urlRef);
    calloc.free(urlRef);
  }

  void init(String url) {
    final urlRef = url.toNativeUtf8();
    library.init(webviewRef, urlRef);
    calloc.free(urlRef);
  }

  void eval(String url) {
    final urlRef = url.toNativeUtf8();
    library.eval(webviewRef, urlRef);
    calloc.free(urlRef);
  }
}
