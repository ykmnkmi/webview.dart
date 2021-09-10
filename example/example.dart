import 'package:webview/webview.dart';

const String html = '''<!doctype html>
<html>
  <body>hello</body>
  <script>
    window.onload = function() {
      document.body.innerText = `hello, \${navigator.userAgent}`;
      noop().then(function(res) {
        console.log('noop res', res);
      });
    };
  </script>
</html>''';

void main(List<String> arguments) {
  Webview(debug: true)
    ..title = 'Hello'
    ..navigate(Uri.dataFromString(html, mimeType: 'text/html; charset=utf-8'))
    ..run()
    ..destroy();
}
