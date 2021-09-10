import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'events.dart';
import 'types.dart';

typedef _CCreate = Pointer Function(Int32 debug, Pointer window);

typedef _DartCreate = Pointer Function(int, Pointer);

typedef _CGetWindow = Pointer Function(Pointer webview);

typedef _DartGetWindow = Pointer Function(Pointer);

typedef _CSetSize = Void Function(Pointer webview, Int32 width, Int32 height, Int32 hint);

typedef _DartSetSize = void Function(Pointer, int, int, int);

typedef _CBind = Void Function(Pointer webview, Pointer<Utf8> name, Pointer callback, Pointer arg);

typedef _DartBind = void Function(Pointer, Pointer<Utf8>, CBindCallbackPointer, Pointer);

typedef _CCallback = Void Function(Pointer webview);

typedef _DartCallback = void Function(Pointer);

typedef _CStringCallback = Void Function(Pointer webview, Pointer<Utf8> url);

typedef _DartStringCallback = void Function(Pointer, Pointer<Utf8>);

class WebviewBindings {
  static WebviewBindings? instance;

  factory WebviewBindings([String? path]) {
    var binding = instance;

    if (binding == null) {
      if (path == null) {
        switch (Platform.operatingSystem) {
          case 'windows':
            path = 'webview.dll';
            break;
          default:
            throw UnsupportedError(Platform.operatingSystem);
        }
      }

      binding = instance = WebviewBindings.from(DynamicLibrary.open(path));
    }

    return binding;
  }

  WebviewBindings.from(this.library)
      : create = library.lookupFunction<_CCreate, _DartCreate>('webview_create'),
        destroy = library.lookupFunction<_CCallback, _DartCallback>('webview_destroy'),
        run = library.lookupFunction<_CCallback, _DartCallback>('webview_run'),
        terminate = library.lookupFunction<_CCallback, _DartCallback>('webview_terminate'),
        getWindow = library.lookupFunction<_CGetWindow, _DartGetWindow>('webview_get_window'),
        setTitle = library.lookupFunction<_CStringCallback, _DartStringCallback>('webview_set_title'),
        setSize = library.lookupFunction<_CSetSize, _DartSetSize>('webview_set_size'),
        navigate = library.lookupFunction<_CStringCallback, _DartStringCallback>('webview_navigate'),
        init = library.lookupFunction<_CStringCallback, _DartStringCallback>('webview_init'),
        eval = library.lookupFunction<_CStringCallback, _DartStringCallback>('webview_eval'),
        bind = library.lookupFunction<_CBind, _DartBind>('webview_bind');

  /// Native library link.
  final DynamicLibrary library;

  /// Creates a new native webview instance.
  ///
  /// If `debug` is non-zero - developer tools will be enabled (if the
  /// platform supports them). Window parameter can be a pointer to the native
  /// window handle. If it's non-null - then child WebView is embedded into
  /// the given parent window. Otherwise a new window is created. Depending on
  /// the platform, a GtkWindow, NSWindow or HWND pointer can be passed here.
  final Pointer Function(int debug, Pointer window) create;

  /// Destroys a webview and closes the native window.
  final void Function(Pointer webview) destroy;

  /// Runs the main loop until it's terminated.
  ///
  /// After this function exits - you must destroy the webview.
  final void Function(Pointer webview) run;

  /// Stops the main loop.
  final void Function(Pointer webview) terminate;

  /// Returns a native window handle pointer.
  ///
  /// When using GTK backend the pointer is GtkWindow pointer, when using
  /// Cocoa backend the pointer is NSWindow pointer, when using Win32 backend
  /// the pointer is HWND pointer.
  final Pointer Function(Pointer webview) getWindow;

  /// Updates the title of the native window.
  final void Function(Pointer webview, Pointer<Utf8> url) setTitle;

  /// Updates native window size.
  ///
  /// Hints:
  /// 0 - width and height are default size,
  /// 1 - width and height are minimum bounds,
  /// 2 - width and height are maximum bounds,
  /// 3 - window size can not be changed by a user.
  final void Function(Pointer webview, int width, int height, int hint) setSize;

  /// Navigates webview to the given URL.
  ///
  /// URL may be a data URI, i.e. "data:text/text,<html>...</html>".
  /// It is often ok not to url-encode it properly,
  /// webview will re-encode it for you.
  final void Function(Pointer webview, Pointer<Utf8> url) navigate;

  /// Injects JavaScript code at the initialization of the new page.
  ///
  /// Every time the webview will open a the new page - this initialization
  /// code will be executed. It is guaranteed that code is executed before
  /// `window.onload`.
  final void Function(Pointer webview, Pointer<Utf8> js) init;

  /// Evaluates arbitrary JavaScript code.
  ///
  /// Evaluation happens asynchronously, also the result of the expression is
  /// ignored. Use RPC bindings if you want to receive notifications about
  /// the results of the evaluation.
  final void Function(Pointer webview, Pointer<Utf8> js) eval;

  /// Binds a native C callback so that it will appear under the given name as a
  /// global JavaScript function.
  ///
  /// Internally it uses webview_init(). Callback receives a request string
  /// and a user-provided argument pointer. Request string is a JSON array of
  /// all the arguments passed to the JavaScript function.
  final void Function(Pointer webview, Pointer<Utf8> name, Pointer<NativeFunction<CBindCallback>> callback, Pointer arg)
      bind;
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
  Webview({bool debug = false, String? libraryPath, Pointer? window}) : library = WebviewBindings(libraryPath) {
    webviewRef = library.create(debug ? 1 : 0, window ?? nullptr);
  }

  /// Creates a new `Webview` with specified [WebviewBindings] wrapper.
  ///
  /// If `debug` is non-zero - developer tools will be enabled (if the
  /// platform supports them). Window parameter can be a pointer to the native
  /// window handle. If it's non-null - then child WebView is embedded into
  /// the given parent window. Otherwise a new window is created. Depending on
  /// the platform, a GtkWindow, NSWindow or HWND pointer can be passed here.
  Webview.fromLibrary(this.library, {bool debug = false, Pointer? window})
      : webviewRef = library.create(debug ? 1 : 0, window ?? nullptr);

  final WebviewBindings library;

  /// Pointer to native webview instance.
  late final Pointer webviewRef;

  /// Returns a native window handle pointer.
  ///
  /// When using GTK backend the pointer is GtkWindow pointer, when using
  /// Cocoa backend the pointer is NSWindow pointer, when using Win32 backend
  /// the pointer is HWND pointer.
  Pointer get windowRef {
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
  void navigate(Uri url) {
    final urlRef = url.toString().toNativeUtf8();
    library.navigate(webviewRef, urlRef);
    calloc.free(urlRef);
  }

  /// Injects JavaScript code at the initialization of the new page.
  ///
  /// Every time the webview will open a the new page - this initialization
  /// code will be executed. It is guaranteed that code is executed before
  /// `window.onload`.
  void init(String js) {
    final jsRef = js.toNativeUtf8();
    library.init(webviewRef, jsRef);
    calloc.free(jsRef);
  }

  /// Evaluates arbitrary JavaScript code.
  ///
  /// Evaluation happens asynchronously, also the result of the expression is
  /// ignored. Use RPC bindings if you want to receive notifications about
  /// the results of the evaluation.
  void eval(String js) {
    final jsRef = js.toNativeUtf8();
    library.eval(webviewRef, jsRef);
    calloc.free(jsRef);
  }

  /// Binds a native C callback so that it will appear under the given name as a
  /// global JavaScript function.
  ///
  /// Internally it uses webview_init(). Callback receives a request string
  /// and a user-provided argument pointer. Request string is a JSON array of
  /// all the arguments passed to the JavaScript function.
  void bind(String name, Function callback) {
    final nameRef = name.toNativeUtf8();
    library.bind(windowRef, nameRef, listenerRef, nullptr);
    calloc.free(nameRef);
  }
}
