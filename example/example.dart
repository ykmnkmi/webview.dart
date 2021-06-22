import 'package:webview/webview.dart';

void main(List<String> arguments) {
  final webview = Webview();
  webview.navigate('https://google.com');
  webview.run();
  webview.destroy();
}
