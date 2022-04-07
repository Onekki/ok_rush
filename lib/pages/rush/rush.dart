import 'dart:core';

import 'package:ok_rush/pages/rush/rush_store.dart';
import 'package:ok_rush/pages/rush/rusher.dart';

class RushContainer {
  RushContainer(this.platform, this.category);

  final String platform;
  final String category;

  factory RushContainer.jsonDecode(json) =>
      RushContainer(json["platform"], json["category"]);
}

class Rush {
  Rush({required this.name,
    required this.runners,
    required this.steps,
    this.init,
    this.magic,
    this.inputKeys,
    this.cache,
    this.webShowKeys});

  final String name;
  final List<String>? init;
  final List<String>? magic;
  final List<dynamic>? inputKeys;
  final Map<String, dynamic>? cache;
  final Map<String, AbsRunner> runners;
  final List<String> steps;

  final List<String>? webShowKeys;

  factory Rush.jsonDecode(json) =>
      Rush(
          name: json["name"],
      init: json["init"]?.cast<String>(),
      magic: json["magic"]?.cast<String>(),
      webShowKeys: json["webShowKeys"]?.cast<String>(),
      inputKeys: json["inputKeys"],
      cache: json["cache"],
      runners: Map<String, AbsRunner>.from(json["runners"].map((key, value) {
        if (key.startsWith("dio")) {
          return MapEntry(key, DIORunner.jsonDecode(value));
        } else if (key.startsWith("jio")) {
          return MapEntry(key, JIORunner.jsonDecode(value));
        }
        throw UnimplementedError();
      })),
      steps: json["steps"]?.cast<String>());
}

class Web {}

abstract class AbsRunner {
  AbsRunner(this.name);

  final String name;

  Future<dynamic> run(RushStore store, Rusher rusher, Rush rush);
}

class NothingRunner extends AbsRunner {
  NothingRunner(String name) : super(name);

  @override
  Future run(RushStore store, Rusher rusher, Rush rush) {
    throw UnimplementedError();
  }
}

class LoadingRunner extends AbsRunner {
  LoadingRunner() : super("");

  @override
  Future run(RushStore store, Rusher rusher, Rush rush) {
    throw UnimplementedError();
  }
}

class DIORunner extends AbsRunner {
  DIORunner({
    required String name,
    required this.method,
    required this.prefix,
    required this.endpoint,
    this.bodyKeys,
    this.queryKeys,
    this.headerKeys,
    this.forCache,
    this.predicate,
  }) : super(name);
  final String method;
  final String prefix;
  final String endpoint;
  final List<String>? headerKeys;
  final List<String>? queryKeys;
  final List<String>? bodyKeys;
  final Map<String, dynamic>? forCache;
  final Map<String, dynamic>? predicate;

  factory DIORunner.jsonDecode(json) => DIORunner(
      name: json["name"],
      method: json["method"],
      prefix: json["prefix"],
      endpoint: json["endpoint"],
      headerKeys: json["headerKeys"]?.cast<String>(),
      queryKeys: json["queryKeys"]?.cast<String>(),
      bodyKeys: json["bodyKeys"]?.cast<String>(),
      forCache: json["forCache"],
      predicate: json["predicate"]);

  @override
  Future run(RushStore store, Rusher rusher, Rush rush) async {
    var domain = store.cache["domain"];
    var data = await rusher.request(this, {
      "url": "$prefix$domain$endpoint",
      "method": method,
      "headers": getHeaders(store, rush),
      "query": getQuery(store),
      "body": getBody(store),
      "predicate": predicate
    });
    store.putCache(forCache, data);
    return data;
  }

  Map<String, String> getHeaders(RushStore store, Rush rush) {
    Map<String, String> headers = {};
    headerKeys?.forEach((key) {
      final value = store.cache[key];
      if (value != null) {
        headers.putIfAbsent(key, () => value);
      }
    });
    return headers;
  }

  Map<String, dynamic> getQuery(RushStore store) {
    Map<String, dynamic> query = {};
    queryKeys?.forEach((key) {
      final value = store.cache[key];
      if (value != null) {
        query.putIfAbsent(key, () => value);
      }
    });
    return query;
  }

  Map<String, dynamic>? getBody(RushStore store) {
    Map<String, dynamic> body = {};
    bodyKeys?.forEach((key) {
      final value = store.cache[key];
      if (value != null) {
        body.putIfAbsent(key, () => value);
      }
    });
    return body;
  }
}

class JIORunner extends AbsRunner {
  JIORunner(
      {required String name,
      required this.function,
      this.sync,
      this.argKeys,
      this.forCache,
      this.predicate})
      : super(name);
  final String function;
  final bool? sync;
  final List<String>? argKeys;
  final Map<String, dynamic>? forCache;
  final Map<String, dynamic>? predicate;

  factory JIORunner.jsonDecode(json) => JIORunner(
      name: json["name"],
      sync: json["sync"],
      function: json["function"],
      argKeys: json["argKeys"]?.cast<String>(),
      forCache:
          Map<String, List<dynamic>>.from(json["forCache"]?.map((key, value) {
        return MapEntry(key, List<dynamic>.from(value));
      })),
      predicate: json["predicate"]);

  @override
  Future run(RushStore store, Rusher rusher, Rush rush) async {
    var data = await rusher.request(this, {
      "sync": sync,
      "function": function,
      "args": getArgs(store),
      "predicate": predicate
    });
    store.putCache(forCache, data);
    return data;
  }

  Map<String, dynamic>? getArgs(RushStore store) {
    Map<String, dynamic> args = {};
    argKeys?.forEach((key) {
      final value = store.cache[key];
      if (value != null) {
        args.putIfAbsent(key, () => "\"$value\"");
      }
    });
    return args;
  }
}
