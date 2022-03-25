import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewWidget extends StatefulWidget {
  const WebViewWidget(
      {Key? key,
      required this.url,
      required this.domain,
      required this.cookie,
      this.onWebViewCreated,
      this.onProgress,
      this.onPageStarted,
      this.onPageFinished,
      this.onJioCallback})
      : super(key: key);

  final String domain;
  final String? cookie;
  final String url;

  final void Function(WebViewController controller)? onWebViewCreated;
  final void Function(int progress)? onProgress;
  final void Function(String url)? onPageStarted;
  final void Function(String url)? onPageFinished;
  final void Function(String result)? onJioCallback;

  @override
  State<StatefulWidget> createState() {
    return _WebViewWidgetState();
  }
}

class _WebViewWidgetState extends State<WebViewWidget> {
  @override
  void initState() {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      debuggingEnabled: kDebugMode,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) async {
        debugPrint("onWebViewCreated");
        if (widget.cookie != null) {
          final cookieMap = Uri.splitQueryString(widget.cookie!);
          final cookieManager = CookieManager();

          cookieMap.forEach((key, value) async {
            cookieManager.setCookie(
              WebViewCookie(name: key, value: value, domain: widget.domain),
            );
          });
        }
        if (widget.url.startsWith("assets")) {
          await webViewController.loadFlutterAsset(widget.url);
        } else {
          await webViewController.loadUrl(widget.url);
        }
        if (widget.onWebViewCreated != null) {
          widget.onWebViewCreated!(webViewController);
        }
      },
      onProgress: (int progress) {
        debugPrint('WebView is loading (progress : $progress%)');
        if (widget.onProgress != null) {
          widget.onProgress!(progress);
        }
      },
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(
          name: "Jio",
          onMessageReceived: (message) {
            if (widget.onJioCallback != null) {
              widget.onJioCallback!(message.message);
            }
          }
        )
      },
      onPageStarted: (String url) {
        debugPrint('Page started loading: $url');
        if (widget.onPageStarted != null) {
          widget.onPageStarted!(url);
        }
      },
      onPageFinished: (String url) {
        debugPrint('Page finished loading: $url');
        if (widget.onPageFinished != null) {
          widget.onPageFinished!(url);
        }
      },
      backgroundColor: const Color(0x00ffffff),
    );
  }
}
