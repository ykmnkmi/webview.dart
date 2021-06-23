import 'package:webview/webview.dart';

void main(List<String> arguments) {
  final webview = Webview();
  print('window pointer: ${webview.windowRef.address}');
  webview.resize(320, 240, WebviewHint.fixed);
  webview.title = 'hello world!';
  webview.navigate('data:text/html,%3Cp%3Ehello%2C%20world%21%3C%2Fp%3E');
  webview.run();
  webview.destroy();
}
