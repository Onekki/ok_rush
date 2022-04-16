import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/rush/web_engine.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({Key? key, required this.webUrl}) : super(key: key);

  final String webUrl;

  @override
  State<StatefulWidget> createState() {
    return _BrowserPageState();
  }
}

class _BrowserPageState extends AuthRequiredState<BrowserPage> {
  final cookieManager = WebviewCookieManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Browser"),
          actions: [
            IconButton(
                onPressed: () async {
                  await cookieManager.clearCookies();
                  context.showSnackBar(message: "cookie cleared");
                },
                icon: const Icon(Icons.clear_all)),
            IconButton(
                onPressed: () async {
                  final cookies = await cookieManager.getCookies(widget.webUrl);
                  final cookie = cookies.map((e) {
                    return "${e.name}=${e.value}";
                  }).join(";");
                  Navigator.of(context).pop(cookie);
                },
                icon: const Icon(Icons.check)),
          ],
        ),
        body: Stack(
          children: [
            WebEngine(
              content: widget.webUrl,
              onPageStarted: (url) {
                context.showSnackBar(message: url);
              },
            ),
          ],
        ));
  }
}
