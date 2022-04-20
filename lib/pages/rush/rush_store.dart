import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/rusher.dart';
import 'package:ok_rush/pages/rush/web_engine.dart';
import 'package:ok_rush/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock/wakelock.dart';

class RushStore extends ChangeNotifier {
  late final RushContainer _rushContainer;
  Rush? _rush;

  get name => _rushContainer.category;

  get magic => _rush?.magic;

  get browser => _rush?.browser;

  get showCaptcha => (_rush?.webShowKeys?.contains(runState) ?? false);

  late final Rusher _rusher;
  late final String webUrl;
  WebController? controller;
  AbsRunner _runner = LoadingRunner();

  get isRunning => [DIORunner, JIORunner].contains(_runner.runtimeType);

  get isLoading => _runner is LoadingRunner;

  get runState => _runner.name;

  final Map<String, TextEditingController> inputControllers = {};
  final TextEditingController minMsController = TextEditingController();
  final TextEditingController maxMsController = TextEditingController();
  final List<TextEditingController> controllers = [];
  final List<String> controllerLabels = [];

  String? rushSuccessLog;
  String? rushErrorLog;
  List<String> successLogs = [];
  Color runStateColor = Colors.grey;

  RushStore(BuildContext context, rushContainer) {
    _rushContainer = rushContainer;
    _rusher = Rusher((String log, bool isExpected) {
      debugPrint(log.toString());
      if (isRunning) {
        if (isExpected) {
          if (rushSuccessLog != null) {
            rushSuccessLog = "$log\n\n$rushSuccessLog";
          } else {
            rushSuccessLog = log;
          }
        } else {
          runStateColor =
          Colors.primaries[Random().nextInt(Colors.primaries.length)];
          rushErrorLog = log.toString();
        }
        notifyListeners();
      }
    });

    fetchRush(context, rushContainer);
  }

  void fetchRush(BuildContext context, RushContainer rushContainer) async {
    var response = await supabase
        .from("rushes")
        .select("rush")
        .eq("platform", rushContainer.platform)
        .eq("category", rushContainer.category)
        .execute();
    if (response.error != null) {
      context.showErrorSnackBar(message: response.error!.message);
    } else {
      debugPrint(response.data.toString());
      _rush = Rush.jsonDecode(response.data[0]["rush"]);
      _rush!.inputKeys?.forEach((key) {
        final controller = TextEditingController();
        String combineKey = key is List ? key.join(",") : key;
        inputControllers[combineKey] = controller;
        if (_rush!.cache?[key] != null) {
          controllerLabels.add(combineKey + ":${_rush!.cache?[key]}");
        } else {
          controllerLabels.add(combineKey);
        }
        controllers.add(controller);
      });
      _rush!.cache?.forEach((key, value) {
        inputControllers[key]?.text = value;
      });
      inputControllers.putIfAbsent("min", () => minMsController);
      inputControllers.putIfAbsent("max", () => maxMsController);
      controllers.add(minMsController);
      controllers.add(maxMsController);
      controllerLabels.add("min");
      controllerLabels.add("max");

      final appDir = await getApplicationDocumentsDirectory();
      if (_rush!.source != null) {
        webUrl = "${appDir.path}/rushes/${_rushContainer.platform}/index.html";
      } else {
        webUrl = "assets/www/rush/index.html";
      }
      debugPrint(webUrl);

      _rush!.source?.forEach((item) async {
        final response = await supabase.storage
            .from("rushes")
            .download("${_rushContainer.platform}/$item");
        if (response.error != null) {
          context.showSnackBar(message: response.error!.message);
        } else if (response.data != null) {
          Directory rushDir =
          Directory("${appDir.path}/rushes/${_rushContainer.platform}");
          if (!await rushDir.exists()) rushDir.createSync(recursive: true);
          File file = File("${rushDir.path}/$item");
          file.writeAsBytesSync(response.data!);
        }
      });

      _fetchConfig(context, rushContainer);
    }
  }

  Future<void> _fetchConfig(BuildContext context, RushContainer rushContainer) async {
    try {
      var response = await supabase
          .from("configs")
          .select("config")
          .eq("user_id", supabase.auth.currentUser!.id)
          .eq("platform", rushContainer.platform)
          .eq("category", rushContainer.category)
          .execute();
      if (response.error != null) {
        context.showErrorSnackBar(message: response.error!.message);
      } else {
        final config = response.data[0]["config"];
        debugPrint("config=$config");
        inputControllers.forEach((key, value) {
          if (config[key] != null) value.text = config[key];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    _runner = NothingRunner("尚未运行");
    notifyListeners();
  }

  void saveConfig(BuildContext context, RushContainer rushContainer) async {
    _runner = LoadingRunner();
    notifyListeners();
    try {
      final config =
      inputControllers.map((key, value) => MapEntry(key, value.text));
      config.removeWhere((key, value) => value.isEmpty);
      var response = await supabase.from("configs").upsert({
        "user_id": supabase.auth.currentUser!.id,
        "platform": rushContainer.platform,
        "category": rushContainer.category,
        "config": config,
      }).execute();
      if (response.error != null) {
        context.showErrorSnackBar(message: response.error!.message);
      } else {
        context.showSnackBar(message: "保存成功");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    _runner = NothingRunner("尚未运行");
    notifyListeners();
  }

  final Map<String, dynamic> cache = {};

  void start(BuildContext context) async {
    final String? successLog = await _run(context, _rush?.steps);
    debugPrint("start - insert $successLog");
    if (successLog != null) {
      final response = await supabase.from("orders").insert({
        "user_id": supabase.auth.currentUser!.id,
        "platform": _rushContainer.platform,
        "category": _rushContainer.category,
        "order": successLog,
      }).execute();
      if (response.hasError) {
        debugPrint(response.error.toString());
      }
    }
  }

  void runInit(BuildContext context) {
    _run(context, _rush?.init);
  }

  void runAction(BuildContext context) {
    _run(context, _rush?.magic);
  }

  Future<String?> _run(BuildContext context, runnerKeys) async {
    if (runnerKeys == null) return null;
    if (isRunning) {
      Wakelock.disable();
      if (rushSuccessLog != null) {
        successLogs.add(rushSuccessLog!);
        rushSuccessLog = null;
        notifyListeners();
      }
      stop("已取消");
    } else {
      Wakelock.enable();
      final minMs = int.tryParse(minMsController.text) ?? 0;
      final maxMs = int.tryParse(maxMsController.text) ?? 0;
      _rusher.start(minMs, maxMs, controller);
      cache.clear();
      _rush?.cache?.forEach((key, value) {
        cache[key] = value;
      });
      inputControllers.forEach((key, value) {
        if (key.contains(",")) {
          key.split(",").forEach((item) {
            cache[item] = value.text;
          });
        } else {
          cache[key] = value.text;
        }
      });
      for (String runnerKey in runnerKeys) {
        _runner = _rush!.runners[runnerKey]!;
        notifyListeners();
        if (showCaptcha) {
          _rusher.captchaController = await _showCaptcha(context);
        } else {
          _rusher.captchaController = null;
        }
        final data = await _runner.run(this, _rusher, _rush!);
        if (data == null) break;
      }
      if (isRunning) {
        stop("已完成");
        if (rushSuccessLog != null) {
          successLogs.add(rushSuccessLog!);
          rushSuccessLog = null;
          notifyListeners();
          return successLogs.last;
        }
      }
    }
    return null;
  }

  Future<WebController> _showCaptcha(context) async {
    Completer<WebController> completer = Completer();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("验证码"),
            content: SizedBox(
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 320.0 / 320.0,
                child: WebEngine(
                  showNav: false,
                  content: webUrl,
                  onPageFinished: (controller, url) {
                    completer.complete(controller);
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text("关闭"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
    return completer.future;
  }

  void putCache(Map<String, dynamic>? forCache, dynamic data) {
    debugPrint("putCache: data=$data");
    if (data != null) {
      forCache?.forEach((key, value) {
        var parser = data;
        for (var item in value) {
          parser = parser[item];
        }
        cache[key] = parser;
        inputControllers[key]?.text = parser.toString();
      });
      debugPrint("DioRunner: cache=$cache");
    }
  }

  void stop(String message) {
    _rusher.stop();
    _runner = NothingRunner(message);
    runStateColor = Colors.grey;
    notifyListeners();
  }

  @override
  void dispose() {
    stop("已取消");
    _rusher.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
