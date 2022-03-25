import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ok_rush/pages/web/web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

String signJs(t) {
  return "GridItems($t)";
}

class CaptchaWidget extends StatefulWidget {
  const CaptchaWidget(
      {Key? key,
      required this.cookie,
      this.onWebViewCreated,
      this.onJioCallback,})
      : super(key: key);

  final String cookie;

  final void Function(WebViewController controller)? onWebViewCreated;
  final void Function(String result)? onJioCallback;

  @override
  State<StatefulWidget> createState() {
    return CaptchaWidgetState();
  }
}

class CaptchaWidgetState extends State<CaptchaWidget> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 320.0 / 320.0,
          child: WebViewWidget(
            showNav: false,
            url: "assets/www/starark/index.html",
            domain: "h5.stararknft.art",
            cookie: widget.cookie,
            onWebViewCreated: widget.onWebViewCreated,
            onJioCallback: (message) {
              if (widget.onJioCallback != null) {
                widget.onJioCallback!(message);
              }
            },
          ),
        ));
  }
}
