import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
                child: WebView(
              debuggingEnabled: kDebugMode,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) async {
                debugPrint("onWebViewCreated");
                if (widget.cookie != null) {
                  final cookieMap = Uri.splitQueryString(widget.cookie!);
                  final cookieManager = CookieManager();

                  cookieMap.forEach((key, value) async {
                    cookieManager.setCookie(
                      WebViewCookie(
                          name: key, value: value, domain: widget.domain),
                    );
                  });
                }
                if (widget.url.startsWith("assets")) {
                  await webViewController.loadFlutterAsset(widget.url);
                } else {
                  await webViewController.loadUrl(widget.url);
                }
                _controller = webViewController;
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
                    })
              },
              onPageStarted: (String url) async {
                debugPrint('Page started loading: $url');
                setState(() {
                  _isLoading = true;
                });
                if (widget.onPageStarted != null) {
                  widget.onPageStarted!(url);
                }
              },
              onPageFinished: (String url) async {
                debugPrint('Page finished loading: $url');
                setState(() {
                  _isLoading = false;
                });
                if (widget.onPageFinished != null) {
                  widget.onPageFinished!(url);
                }
              },
              backgroundColor: const Color(0x00ffffff),
            )),
            _controller == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}
