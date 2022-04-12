import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:ok_rush/components/auth_required_state.dart';
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
                          store.runAction();
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Divider(),
                        Offstage(
                          offstage: store.webOffstage,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: AspectRatio(
                                  aspectRatio: 320.0 / 320.0,
                                  child: WebEngine(
                                    showNav: false,
                                    content: "assets/www/rush/index.html",
                                    onWebViewCreated: (controller) {
                                      store.controller = controller;
                                      store.runInit();
                                    },
                                  ),
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                "运行状态",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(store.runState),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "失败日志:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 16),
                              child: Text(
                                store.rushErrorLog ?? "暂无日志",
                                style: TextStyle(color: store.runStateColor),
                              ),
                            ),
                          ),
                        ),
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "成功日志:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          child: SelectableLinkify(
                            onOpen: (link) async {
                              String url = link.url
                                  .replaceAll(",", "")
                                  .replaceAll("}", "");
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else {
                                context.showErrorSnackBar(message: "无法打开");
                              }
                            },
                            text: store.rushSuccessLog ?? "暂无日志",
                            style: const TextStyle(color: Colors.grey),
                            options: const LinkifyOptions(humanize: false),
                            linkStyle: const TextStyle(
                                decoration: TextDecoration.none),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
            floatingActionButton: store.isLoading
                ? null
                : FloatingActionButton(
                    onPressed: () {
                      store.start();
                    },
                    child: Icon(store.isRunning
                        ? Icons.stop
                        : Icons.play_arrow_rounded),
                  ), // This trailing comma makes auto-formatting nicer for build methods.
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
