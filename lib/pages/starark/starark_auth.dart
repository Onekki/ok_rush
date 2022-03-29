import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/web/web_view.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

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

  String? _id;
  String? _token;
  String? _cookie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("StarArkAuth"),
          actions: [
            IconButton(
                onPressed: () async {
                  _cookie = null;
                  await cookieManager.clearCookies();
                  context.showSnackBar(message: "cookie cleared");
                },
                icon: const Icon(Icons.clear_all)),
            IconButton(
                onPressed: () async {
                  _updateTokenAndCookie();
                  Navigator.of(context)
                      .pop([_id ?? "", _token ?? "", _cookie ?? ""]);
                },
                icon: const Icon(Icons.check)),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(
              url: url,
              onPageStarted: (url) {
                try {
                  String queryString = url.split("?")[1];
                  final queryParameters = Uri.splitQueryString(queryString);
                  _id = queryParameters["id"];
                  debugPrint("id=$_id");
                } catch (e) {}
              },
              onPageFinished: (url) async {
                debugPrint(url);
                _updateTokenAndCookie();
              },
            ),
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
          debugPrint("token=$_token");
        } catch (e) { }
      }
      return "${e.name}=${e.value}";
    }).join(";");
  }
}