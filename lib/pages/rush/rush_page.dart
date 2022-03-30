import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ok_rush/components/auth_required_state.dart';
import 'package:ok_rush/pages/base/base_rush.dart';
import 'package:ok_rush/pages/starark/captcha_netease.dart';
import 'package:ok_rush/pages/starark/starark_rush.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:ok_rush/utils/rusher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RushPage extends StatefulWidget {
  const RushPage({Key? key}) : super(key: key);

  @override
  State<RushPage> createState() => _RushPageState();
}

class _RushPageState extends AuthRequiredState<RushPage> {
  late final Rusher _rusher;
  WebViewController? _controller;

  late String _category;
  RushState _rushState = RushState.none;

  set setRushState(rushState) {
    _rushState = rushState;
  }

  final Map<RushCategory, Map<String, TextEditingController>>
      _presetsControllerMapMap = {};
  final Map<RushCategory, List<TextEditingController>>
      _presetsControllerListMap = {};
  final Map<RushCategory, List<String>> _presetsControllerKeyListMap = {};

  String get _rushStateMessage =>
      categoryMap[_category]![CategoryProperty.rushState][_rushState]
          [RushStateProperty.message];

  String? get _rushStateEndpoint =>
      categoryMap[_category]![CategoryProperty.rushState][_rushState]
          [RushStateProperty.endpoint];

  Map<String, dynamic>? get _rushStateParser =>
      categoryMap[_category]![CategoryProperty.rushState][_rushState]
          [RushStateProperty.parser];

  List<String>? get _rushStateQuery =>
      categoryMap[_category]![CategoryProperty.rushState][_rushState]
          [RushStateProperty.query];

  bool get _isRunning =>
      _rushState != RushState.none &&
      _rushState != RushState.done &&
      _rushState != RushState.cancel;
  String? _rushSuccessLog;
  String? _rushErrorLog;
  Color _runStateColor = Colors.grey;

  bool _isLoading = false;
  final _configKey = GlobalKey<FormState>();

  late final TextEditingController _cookieController;

  String get _cookie => _cookieController.text.trim();

  late final TextEditingController _sleepMinController;

  String get _sleepMin => _sleepMinController.text.trim();

  late final TextEditingController _sleepMaxController;

  String get _sleepMax => _sleepMaxController.text.trim();

  @override
  void initState() {
    _rusher = Rusher("Rush");
    dataTypeMaps.forEach((category, dataTypeMap) {
      dataTypeMap.forEach((key, dataType) {
        _presetsControllerMapMap.putIfAbsent(category, () => {});
        _presetsControllerListMap.putIfAbsent(category, () => []);
        _presetsControllerKeyListMap.putIfAbsent(category, () => []);
        if (dataType == RushStateDataType.presets) {
          final textEditingController = TextEditingController();
          _presetsControllerKeyListMap[category]?.add(key);
          _presetsControllerListMap[category]?.add(textEditingController);
          _presetsControllerMapMap[category]
              ?.putIfAbsent(key, () => textEditingController);
        }
      });
    });
    _cookieController = TextEditingController();
    _sleepMinController = TextEditingController();
    _sleepMaxController = TextEditingController();
    _fetchConfig();
    super.initState();
  }

  @override
  void dispose() {
    _rusher.dispose();
    _presetsControllerListMap.forEach((key, value) {
      for (var element in value) {
        element.dispose();
      }
    });
    _cookieController.dispose();
    _sleepMinController.dispose();
    _sleepMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rush'),
        actions: [
          _isLoading || _isRunning
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: _saveConfig, icon: const Icon(Icons.cloud_upload)),
          _isLoading || _isRunning
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: _editConfig, icon: const Icon(Icons.edit)),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Divider(),
                  Offstage(
                    offstage: ![RushState.fetchCaptcha, RushState.inputCaptcha]
                        .contains(_rushState),
                    child: Column(
                      children: [
                        CaptchaWidget(
                          cookie: _cookie,
                          onWebViewCreated: (controller) {
                            _controller = controller;
                          },
                          onJioCallback: _rusher.onJioCallback,
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            "购买类型",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownButton(
                            value: _category,
                            items: [
                              DropdownMenuItem(
                                child: Text(categoryMap[RushCategory.box]![
                                    CategoryProperty.name]!),
                                value: RushCategory.box,
                              ),
                              DropdownMenuItem(
                                child: Text(categoryMap[RushCategory.product]![
                                    CategoryProperty.name]!),
                                value: RushCategory.product,
                              ),
                              DropdownMenuItem(
                                child: Text(categoryMap[RushCategory.goods]![
                                    CategoryProperty.name]!),
                                value: RushCategory.goods,
                              ),
                            ],
                            onChanged: _isRunning
                                ? null
                                : (value) {
                                    _category = value as RushCategory;
                                    _fetchConfig();
                                  }),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          "运行状态",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(_rushStateMessage),
                        _isRunning
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
                          _rushErrorLog ?? "暂无日志",
                          style: TextStyle(color: _runStateColor),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Text(
                      _rushSuccessLog ?? "暂无日志",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _rush,
              tooltip: 'Rush',
              child: Icon(_isRunning ? Icons.stop : Icons.play_arrow_rounded),
            ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  int get min => int.tryParse(_sleepMin) ?? 0;

  int get max => int.tryParse(_sleepMax) ?? 0;

  PredicateType predicate(Map<String, dynamic> map) {
    final code = map["code"];
    if (code is int) {
      if (code == 1) {
        return PredicateType.stop;
      }
      final msg = map["msg"];
      if (msg is String) {
        if (msg.contains("网络繁忙")) {
          return PredicateType.repeat;
        }
      }
      if (_rushState == RushState.payOrder) {
        return PredicateType.stop;
      }
    }
    return PredicateType.repeat;
  }

  void logger(String log, PredicateType predicateType) {
    debugPrint(log.toString());
    if (_isRunning) {
      setState(() {
        if (predicateType == PredicateType.stop) {
          if (_rushSuccessLog != null) {
            _rushSuccessLog = "$log\n\n$_rushSuccessLog";
          } else {
            _rushSuccessLog = log;
          }
        } else {
          _runStateColor =
              Colors.primaries[Random().nextInt(Colors.primaries.length)];
          _rushErrorLog = log.toString();
        }
      });
    }
  }

  Future<void> _rush() async {
    debugPrint("$_isRunning");

    if (_isRunning) {
      _rusher.stop();
      setState(() {
        _runStateColor = Colors.grey;
        _rushState = RushState.cancel;
      });
    } else {
      if (_controller == null) {
        context.showErrorSnackBar(message: "网页尚未加载完毕");
        return;
      }

      _rusher.start();

      setState(() {
        _rushState = RushState.fetchCaptcha;
      });

      _rushCaptcha(_controller);
    }
  }

  Future<void> _rushCaptcha(controller) async {
    setState(() {
      _rushState = RushState.inputCaptcha;
    });
    final data = await _rusher.ensureRunJs(
        controller, kStararkCaptchaJs, predicate, min, max, logger);

    if (data == null) return;

    var parser, queryCache = {};
    if (_rushStateParser != null) {
      _rushStateParser!.forEach((key, value) {
        parser = data;
        for (var i = 0; i < value.length; i++) {
          parser = parser[value[i]];
        }
        queryCache.putIfAbsent(key, () => parser);
      });
      debugPrint("$_rushState queryCache=$queryCache");
    }

    _rushOther(queryCache, controller);
  }

  Future<void> _rushOther(queryCache, WebViewController controller) async {
    debugPrint("_rushOther queryCache=$queryCache");

    var query, data, parser, t, sign;
    Map<String, dynamic>? currentQuery;
    _presetsControllerMapMap[_category]!.forEach((key, value) {
      queryCache.putIfAbsent(key, () => value.text);
    });
    debugPrint("$_rushState queryCache=$queryCache");

    setState(() {
      _rushState = RushState.fetchTarget;
    });

    if (_rushStateQuery != null) {
      currentQuery = {};
      for (var key in _rushStateQuery!) {
        if (queryCache[key] != null) {
          currentQuery.putIfAbsent(key, () => queryCache[key]);
        }
      }

      debugPrint("$_rushState currentQuery=$currentQuery");
      query = Uri(
          queryParameters: currentQuery
              .map((key, value) => MapEntry(key, value!.toString()))).query;

      debugPrint("$_rushState query=$query");
    }

    t = (DateTime.now().microsecondsSinceEpoch ~/ 1000 * 1000).toString();
    sign = await controller.runJavascriptReturningResult(signJs(t));
    sign = sign.replaceAll('"', '');
    debugPrint("t=$t sign=$sign");
    data = await _rusher.ensurePost(kBaseUrl + _rushStateEndpoint!,
        headers(_cookie, t, sign), query, predicate, min, max, logger);

    if (data == null) return;

    if (_rushStateParser != null) {
      _rushStateParser!.forEach((key, value) {
        parser = data;
        for (var i = 0; i < value.length; i++) {
          parser = parser[value[i]];
        }
        queryCache.putIfAbsent(key, () => parser);
      });
      debugPrint("$_rushState queryCache=$queryCache");
    }

    setState(() {
      _rushState = RushState.prepareOrder;
    });

    if (_rushStateQuery != null) {
      currentQuery = {};
      for (var key in _rushStateQuery!) {
        if (queryCache[key] != null) {
          currentQuery.putIfAbsent(key, () => queryCache[key]);
        }
      }
      debugPrint("$_rushState currentQuery=$currentQuery");
      query = Uri(
          queryParameters: currentQuery
              .map((key, value) => MapEntry(key, value!.toString()))).query;
      debugPrint("$_rushState query=$query");
    }

    t = (DateTime.now().microsecondsSinceEpoch ~/ 1000 * 1000).toString();
    sign = await controller.runJavascriptReturningResult(signJs(t));
    sign = sign.replaceAll('"', '');
    debugPrint("t=$t sign=$sign");
    data = await _rusher.ensurePost(kBaseUrl + _rushStateEndpoint!,
        headers(_cookie, t, sign), query, predicate, min, max, logger);

    if (data == null) return;

    if (_rushStateParser != null) {
      _rushStateParser!.forEach((key, value) {
        parser = data;
        for (var i = 0; i < value.length; i++) {
          parser = parser[value[i]];
        }
        queryCache.putIfAbsent(key, () => parser);
      });
      debugPrint("$_rushState queryCache=$queryCache");
    }

    setState(() {
      _rushState = RushState.payOrder;
    });

    if (_rushStateQuery != null) {
      currentQuery = {};
      for (var key in _rushStateQuery!) {
        if (queryCache[key] != null) {
          currentQuery.putIfAbsent(key, () => queryCache[key]);
        }
      }
      debugPrint("$_rushState currentQuery=$currentQuery");
      query = Uri(
          queryParameters: currentQuery
              .map((key, value) => MapEntry(key, value!.toString()))).query;
      debugPrint("$_rushState query=$query");
    }

    t = (DateTime.now().microsecondsSinceEpoch ~/ 1000 * 1000).toString();
    sign = await controller.runJavascriptReturningResult(signJs(t));
    sign = sign.replaceAll('"', '');
    debugPrint("t=$t sign=$sign");
    data = await _rusher.ensurePost(kBaseUrl + _rushStateEndpoint!,
        headers(_cookie, t, sign), query, predicate, min, max, logger);

    if (data == null) return;

    setState(() {
      _rushState = RushState.done;
    });
  }

  Future<void> _fetchConfig() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase
          .from("configs")
          .select("config")
          .eq("user", supabase.auth.currentUser!.id)
          .eq("platform", "star-ark")
          .eq("category", _category.name)
          .execute();
      final error = response.error;
      final data = response.data;
      if (error != null) {
        context.showErrorSnackBar(message: error.message);
      } else if (data != null) {
        final config = jsonDecode(data[0]['config']);
        _presetsControllerMapMap[_category]!.forEach((key, value) {
          value.text = config[key];
        });
        _cookieController.text = config['cookie']!;
        _sleepMinController.text = config['sleep_min']!;
        _sleepMaxController.text = config['sleep_max']!;
      }
    } catch (e) {
      debugPrint("$e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _editConfig() {
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
                      itemCount: _presetsControllerListMap[_category]!.length,
                      itemBuilder: (context, index) {
                        final key =
                            _presetsControllerKeyListMap[_category]![index];
                        return TextFormField(
                          controller:
                              _presetsControllerListMap[_category]![index],
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
                    TextFormField(
                      controller: _cookieController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'cookie', hintText: '输入cookie'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入cookie';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _sleepMinController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      onFieldSubmitted: (value) {
                        Navigator.of(context).pop();
                      },
                      decoration: const InputDecoration(
                          labelText: '最短间隔时间', hintText: '输入最短间隔时间(ms)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入最短间隔时间(ms)';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _sleepMaxController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      onFieldSubmitted: (value) {
                        Navigator.of(context).pop();
                      },
                      decoration: const InputDecoration(
                          labelText: '最长间隔时间', hintText: '输入最长间隔时间(ms)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入最长间隔时间(ms)';
                        }
                        return null;
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('浏览器'),
              onPressed: () async {
                final result =
                    await Navigator.of(context).pushNamed('/starark_auth');
                if (result is List) {
                  final id = result[0];
                  final token = result[1];
                  final cookie = result[2];
                  if (id is String) {
                    _presetsControllerMapMap[_category]!["id"]!.text = id;
                  }
                  if (token is String) {
                    _presetsControllerMapMap[_category]!["login_token"]!.text =
                        token;
                  }
                  if (cookie is String) {
                    _cookieController.text = cookie;
                  }
                }
              },
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final map = {};
      _presetsControllerMapMap[_category]!.forEach((key, value) {
        map.putIfAbsent(key, () => value.text.trim());
      });
      map.putIfAbsent("cookie", () => _cookie);
      map.putIfAbsent("sleep_min", () => _sleepMin);
      map.putIfAbsent("sleep_max", () => _sleepMax);
      final response = await supabase.from("configs").upsert({
        "user": supabase.auth.currentUser!.id,
        "platform": "star-ark",
        "category": _category.name,
        "config": jsonEncode(map)
      }).execute();
      final error = response.error;
      if (error != null) {
        context.showErrorSnackBar(message: error.message);
      } else {
        context.showSnackBar(message: "保存成功");
      }
    } catch (e) {
      debugPrint("$e");
    }
    setState(() {
      _isLoading = false;
    });
  }
}
