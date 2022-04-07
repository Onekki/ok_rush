import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebController {
  WebController(this.webViewController);

  WebViewController webViewController;
  Completer? completer;
}

class WebEngine extends StatefulWidget {
  const WebEngine(
      {Key? key,
      this.showNav = true,
      required this.content,
      this.cookies,
      this.onWebViewCreated,
      this.onProgress,
      this.onPageStarted,
      this.onPageFinished})
      : super(key: key);

  final bool showNav;
  final String content;
  final List<WebViewCookie>? cookies;

  final void Function(WebController controller)? onWebViewCreated;
  final void Function(int progress)? onProgress;
  final void Function(String url)? onPageStarted;
  final void Function(String url)? onPageFinished;

  @override
  State<StatefulWidget> createState() {
    return _WebEngineState();
  }
}

class _WebEngineState extends State<WebEngine> {
  WebController? _controller;
  double _progress = 0;

  @override
  void initState() {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: WebView(
              debuggingEnabled: kDebugMode,
              javascriptMode: JavascriptMode.unrestricted,
              initialCookies: widget.cookies != null ? widget.cookies! : [],
              onWebViewCreated: (WebViewController webViewController) async {
                debugPrint("onWebViewCreated");
                _controller = WebController(webViewController);
                if (widget.content.startsWith("assets")) {
                  await webViewController.loadFlutterAsset(widget.content);
                } else if (widget.content.startsWith("http")) {
                  await webViewController.loadUrl(widget.content);
                } else {
                  await webViewController.loadHtmlString(widget.content);
                }
                if (widget.onWebViewCreated != null) {
                  widget.onWebViewCreated!(_controller!);
                }
              },
              onProgress: (int progress) {
                debugPrint('WebView is loading (progress : $progress%)');
                setState(() {
                  _progress = progress.toDouble();
                });
              },
              javascriptChannels: <JavascriptChannel>{
                JavascriptChannel(
                    name: "Jio",
                    onMessageReceived: (message) {
                      if (_controller != null &&
                          _controller!.completer != null &&
                          !_controller!.completer!.isCompleted) {
                        _controller!.completer!.complete(message.message);
                      }
                    })
              },
              onWebResourceError: (error) {
                debugPrint(error.toString());
              },
              onPageStarted: (String url) async {
                debugPrint('Page started loading: $url');
                if (widget.onPageStarted != null) {
                  widget.onPageStarted!(url);
                }
              },
              onPageFinished: (String url) async {
                debugPrint('Page finished loading: $url');
                if (widget.onPageFinished != null) {
                  widget.onPageFinished!(url);
                }
              },
              backgroundColor: const Color(0x00ffffff),
            ),
          ),
          _controller != null && widget.showNav
              ? Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (_controller != null) {
                              final canGoBack = await _controller!
                                  .webViewController
                                  .canGoBack();
                              if (canGoBack) {
                                _controller!.webViewController.goBack();
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (_controller != null) {
                              _controller!.webViewController.reload();
                            }
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (_controller != null) {
                              final _canGoForward = await _controller!
                                  .webViewController
                                  .canGoForward();
                              if (_canGoForward) {
                                _controller!.webViewController.goForward();
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_ios),
                        )
                      ],
                    ),
                    _progress < 0 || _progress >= 100
                        ? const SizedBox.shrink()
                        : SizedBox(
                            width: double.infinity,
                            height: 1,
                            child: LinearProgressIndicator(value: _progress),
                          ),
                  ],
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }
}
