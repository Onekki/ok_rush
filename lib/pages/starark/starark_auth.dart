import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/web/web_view.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StarArkAuthPage extends StatefulWidget {
  const StarArkAuthPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StarArkAuthPageState();
  }
}

class _StarArkAuthPageState extends AuthRequiredState<StarArkAuthPage> {
  static const domain = "h5.stararknft.art";
  static const url = "https://$domain/";

  final cookieManager = WebviewCookieManager();
  final Completer<WebViewController> _controller = Completer();

  int _index = 1;
  String? _token;
  String? _cookie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("StarArkAuth"),
        actions: [
          _index == 1 ? const SizedBox.shrink() :
          IconButton(
              onPressed: () async {
                _cookie = null;
                await cookieManager.clearCookies();
                context.showSnackBar(message: "cookie cleared");
              },
              icon: const Icon(Icons.clear_all)
          ),
          _index == 1 ? const SizedBox.shrink() :
          IconButton(
              onPressed: () async {
                _updateTokenAndCookie();
                if (_cookie != null) {
                  context.showSnackBar(message: _cookie!);
                } else {
                  context.showErrorSnackBar(message: "cookie get failed");
                }
              },
              icon: const Icon(Icons.remove_red_eye)
          ),
          _index == 1 ? const SizedBox.shrink() :
          IconButton(
              onPressed: () async {
                _updateTokenAndCookie();
                if (_cookie != null) {
                  Navigator.of(context).pop([_token, _cookie!]);
                } else {
                  context.showErrorSnackBar(message: "cookie get failed");
                }
              },
              icon: const Icon(Icons.check)
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          WebViewWidget(
            url: url,
            domain: domain,
            cookie: null,
            onWebViewCreated: (controller) {
              _controller.complete(controller);
            },
            onPageStarted: (url) {
              setState(() {
                _index = 1;
              });
            },
            onPageFinished: (url) async {
              setState(() {
                _index = 0;
              });
              _updateTokenAndCookie();
            },
          ),
          const Center(child: CircularProgressIndicator(),),
        ],
      )
    );
  }

  void _updateTokenAndCookie() async {
    final cookies = await cookieManager.getCookies(url);
    _cookie = cookies.map((e) {
      if (e.name == "user") {
        try {
          final value = Uri.decodeComponent(e.value);
          final user = jsonDecode(value);
          _token = user["login_token"];
          debugPrint(_token);
        } catch (e) { }
      }
      return "${e.name}=${e.value}";
    }).join(";");
  }
}