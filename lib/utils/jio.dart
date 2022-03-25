import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

class Jio {
  late final Function(String) _callback;
  Function(String) get callback => _callback;
  Completer<String>? completer;
  Timer? _timer;

  Jio(String name) {
    _callback = (message) {
      _timer?.cancel();
      if (completer != null && !completer!.isCompleted) {
        completer?.complete(message);
      }
    };
  }

  Future<String> runJs(WebViewController controller, String js) async {
    completer = Completer();
    _timer = Timer(const Duration(seconds: 1000), () {
      if (completer != null && !completer!.isCompleted) {
        completer?.complete("Jio error runJs timeout");
      }
    });
    await controller.runJavascript(js);
    return await completer!.future;
  }

  void close() {
    _timer?.cancel();
  }
}