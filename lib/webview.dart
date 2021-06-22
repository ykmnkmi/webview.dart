import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef CWebview = Pointer<Void>;

typedef CWebviewCreate = CWebview Function(Int32 debug, Pointer<Void> window);
typedef DartWebviewCreate = CWebview Function(int debug, Pointer<Void> window);

typedef CWebviewCallback = Void Function(CWebview webview);
typedef DartWebviewCallback = void Function(CWebview webview);

typedef CWebviewNavigate = Void Function(CWebview webview, Pointer<Utf8> url);
typedef DartWebviewNavigate = void Function(CWebview webview, Pointer<Utf8> url);

class WebviewLibrary {
  factory WebviewLibrary() {
    switch (Platform.operatingSystem) {
      case 'windows':
        return WebviewLibrary.open('webview.dll');
      default:
        throw UnsupportedError(Platform.operatingSystem);
    }
  }

  factory WebviewLibrary.open(String path) {
    return WebviewLibrary.from(DynamicLibrary.open(path));
  }

  WebviewLibrary.from(this.library)
      : webviewCreate = library.lookupFunction<CWebviewCreate, DartWebviewCreate>('webview_create'),
        webviewDestroy = library.lookupFunction<CWebviewCallback, DartWebviewCallback>('webview_destroy'),
        webviewRun = library.lookupFunction<CWebviewCallback, DartWebviewCallback>('webview_run'),
        webviewTerminate = library.lookupFunction<CWebviewCallback, DartWebviewCallback>('webview_terminate'),
        webviewNavigate = library.lookupFunction<CWebviewNavigate, DartWebviewNavigate>('webview_navigate');

  final DynamicLibrary library;

  final DartWebviewCreate webviewCreate;

  final DartWebviewCallback webviewDestroy;

  final DartWebviewCallback webviewRun;

  final DartWebviewCallback webviewTerminate;

  final DartWebviewNavigate webviewNavigate;

  Webview create({bool debug = false}) {
    return Webview.fromPointer(webviewCreate(debug ? 1 : 0, nullptr), library: this);
  }

  void destroy(Webview webview) {
    webviewDestroy(webview.pointer);
  }

  void run(Webview webview) {
    webviewRun(webview.pointer);
  }

  void terminate(Webview webview) {
    webviewTerminate(webview.pointer);
  }

  void navigate(Webview webview, String url) {
    final pointer = url.toNativeUtf8();
    webviewNavigate(webview.pointer, pointer);
    calloc.free(pointer);
  }
}

class Webview {
  factory Webview({bool debug = false, WebviewLibrary? library}) {
    library ??= WebviewLibrary();
    return library.create(debug: debug);
  }

  Webview.fromPointer(this.pointer, {WebviewLibrary? library}) : library = library ?? WebviewLibrary();

  final WebviewLibrary library;

  final CWebview pointer;

  void destroy() {
    library.destroy(this);
  }

  void run() {
    library.run(this);
  }

  void terminate() {
    library.terminate(this);
  }

  void navigate(String url) {
    library.navigate(this, url);
  }
}
