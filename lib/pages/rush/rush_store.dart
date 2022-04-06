import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/rusher.dart';
import 'package:ok_rush/pages/rush/web_engine.dart';
import 'package:ok_rush/utils/constants.dart';

class RushStore extends ChangeNotifier {
  Rush? _rush;

  get name => _rush?.name ?? "加载中";

  get magic => _rush?.magic;

  get webOffstage => !(_rush?.webShowKeys?.contains(runState) ?? false);

  late final Rusher _rusher;
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
  Color runStateColor = Colors.grey;

  RushStore(BuildContext context, rushContainer) {
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
      _rush = Rush.jsonDecode(response.data[0]["rush"]);
      _rush?.inputKeys?.forEach((key) {
        final controller = TextEditingController();
        String combineKey = key is List ? key.join(",") : key;
        inputControllers[combineKey] = controller;
        if (_rush?.cache?[key] != null) {
          controllerLabels.add(combineKey + ":${_rush?.cache?[key]}");
        } else {
          controllerLabels.add(combineKey);
        }
        controllers.add(controller);
      });
      _rush?.cache?.forEach((key, value) {
        inputControllers[key]?.text = value;
      });
      inputControllers.putIfAbsent("min", () => minMsController);
      inputControllers.putIfAbsent("max", () => maxMsController);
      controllers.add(minMsController);
      controllers.add(maxMsController);
      controllerLabels.add("min");
      controllerLabels.add("max");
    }
    _fetchConfig(context, rushContainer);
  }

  Future<void> _fetchConfig(
      BuildContext context, RushContainer rushContainer) async {
    try {
      var response = await supabase
          .from("configs")
          .select("config")
          .eq("user", supabase.auth.currentUser!.id)
          .eq("platform", rushContainer.platform)
          .eq("category", rushContainer.category)
          .execute();
      if (response.error != null) {
        context.showErrorSnackBar(message: response.error!.message);
      } else {
        final config = response.data[0]["config"];
        debugPrint("config=$config");
        inputControllers.forEach((key, value) {
          value.text = config[key] ?? "";
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
      var response = await supabase.from("configs").upsert({
        "user": supabase.auth.currentUser!.id,
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

  void start() {
    _run(_rush?.steps);
  }

  void runInit() {
    _run(_rush?.init);
  }

  void runAction() {
    _run(_rush?.magic);
  }

  void _run(runnerKeys) async {
    if (runnerKeys == null) return;
    if (isRunning) {
      stop();
    } else {
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
        await _runner.run(this, _rusher, _rush!);
      }
      if (isRunning) {
        _runner = NothingRunner("已完成");
        notifyListeners();
      }
    }
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

  void stop() {
    _rusher.stop();
    _runner = NothingRunner("已取消");
    runStateColor = Colors.grey;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _rusher.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
