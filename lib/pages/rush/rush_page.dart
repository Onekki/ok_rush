import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/components/resizable_box.dart';
import 'package:ok_rush/pages/rush/browser_page.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/rush_store.dart';
import 'package:ok_rush/pages/rush/web_engine.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RushPage extends StatefulWidget {
  const RushPage({Key? key, required this.rushContainer}) : super(key: key);

  final RushContainer rushContainer;

  @override
  State<RushPage> createState() => _RushPageState();
}

class _RushPageState extends AuthRequiredState<RushPage> {
  final _configKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RushStore>(
      create: (c) => RushStore(context, widget.rushContainer),
      child: Consumer<RushStore>(
        builder: (context, store, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(store.name),
              actions: [
                store.isLoading || store.isRunning
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          store.saveConfig(context, widget.rushContainer);
                        },
                        icon: const Icon(Icons.cloud_upload)),
                store.magic == null || store.isLoading || store.isRunning
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          store.runMagic(context);
                        },
                        icon: const Icon(Icons.auto_fix_high),
                      ),
                store.isLoading || store.isRunning
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          _editConfig(store);
                        },
                        icon: const Icon(Icons.edit)),
              ],
            ),
            body: store.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Offstage(
                        offstage: true,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: WebEngine(
                            showNav: false,
                            content: store.webUrl,
                            onWebViewCreated: (controller) {
                              store.controller = controller;
                              store.runInit(context);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Text(
                              "运行状态",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              store.runState,
                              style: TextStyle(color: store.runStateColor),
                            ),
                            store.isRunning
                                ? const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                      ),
                      const Divider(),
                      if (store.currentLogs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              const Text(
                                "当前日志",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                "${store.currentDelayMs}",
                                style: TextStyle(
                                    fontSize: 12, color: store.currentLogColor),
                              ),
                            ],
                          ),
                        ),
                      if (store.currentLogs.isNotEmpty)
                        ResizableBox(
                          maxHeight: MediaQuery.of(context).size.width,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var item in store.currentLogs)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: item != store.currentLogs.first
                                        ? Text(item)
                                        : Text(item,
                                            style: TextStyle(
                                                color: store.currentLogColor)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Text(
                              "历史日志",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                store.clear();
                              },
                              child: const Icon(Icons.clear_all),
                            )
                          ],
                        ),
                      ),
                      store.historyLogs.isEmpty
                          ? const Expanded(
                              child: Center(
                              child: Text("暂无日志"),
                            ))
                          : Expanded(
                              child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  for (var i = 0;
                                      i < store.historyLogs.length;
                                      i++)
                                    Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        store.historyColors[i],
                                                    width: 1)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: SelectableLinkify(
                                                onOpen: (link) async {
                                                  String url = link.url
                                                      .replaceAll(",", "")
                                                      .replaceAll("}", "");
                                                  if (await canLaunch(url)) {
                                                    await launch(url);
                                                  } else {
                                                    context.showErrorSnackBar(
                                                        message: "无法打开");
                                                  }
                                                },
                                                text: store.historyLogs[i],
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                                options: const LinkifyOptions(
                                                    humanize: false),
                                                linkStyle: const TextStyle(
                                                    decoration:
                                                        TextDecoration.none),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: store.historyColors[i]
                                                      .withAlpha(40),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  4)),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: Text(
                                                    "$i",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: store
                                                            .historyColors[i]),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                ],
                              ),
                            ))
                    ],
                  ),
            floatingActionButton: store.isLoading
                ? null
                : FloatingActionButton(
              onPressed: () {
                store.runStep(context);
              },
              child: Icon(store.isRunning
                  ? Icons.stop
                  : Icons.play_arrow_rounded),
            ),
          );
        },
      ),
    );
  }

  void _editConfig(RushStore store) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('配置信息'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Form(
              key: _configKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: store.controllers.length,
                      itemBuilder: (context, index) {
                        final key = store.controllerLabels[index];
                        return TextFormField(
                          controller: store.controllers[index],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              labelText: key, hintText: '输入$key'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入$key';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            store.browser != null
                ? TextButton(
                    child: const Text('浏览器'),
                    onPressed: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BrowserPage(
                                  webUrl: store.browser!["webUrl"])));
                      if (result != null) {
                        store.putCache({
                          "cookie": ["data"]
                        }, {
                          "data": result
                        });
                      }
                    },
                  )
                : const SizedBox.shrink(),
            TextButton(
              child: const Text("确认"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
