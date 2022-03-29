import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewWidget extends StatefulWidget {
  const WebViewWidget(
      {Key? key,
      this.showNav = true,
      required this.url,
      this.cookies,
      this.onWebViewCreated,
      this.onProgress,
      this.onPageStarted,
      this.onPageFinished,
      this.onJioCallback})
      : super(key: key);

  final bool showNav;
  final String url;
  final List<WebViewCookie>? cookies;

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
  WebViewController? _controller;
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
                _controller = webViewController;
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
                setState(() {
                  _progress = progress.toDouble();
                });
              },
              javascriptChannels: <JavascriptChannel>{
                JavascriptChannel(
                    name: "Jio",
                    onMessageReceived: (message) {
                      if (widget.onJioCallback != null) {
                        widget.onJioCallback!(message.message);
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
                              final canGoBack = await _controller!.canGoBack();
                              if (canGoBack) {
                                _controller!.goBack();
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (_controller != null) {
                              _controller!.reload();
                            }
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (_controller != null) {
                              final _canGoForward =
                                  await _controller!.canGoForward();
                              if (_canGoForward) {
                                _controller!.goForward();
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
