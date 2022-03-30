import 'dart:core';

import 'package:ok_rush/pages/rush/rusher.dart';
import 'package:ok_rush/utils/rusher.dart';

class Rush {
  Rush(
      {required this.key,
      required this.name,
      required this.states,
      this.platform,
      this.baseUrl,
      this.headers,
      this.inputProperties,
      this.predicate});

  final String key;
  final String name;
  final String? platform;
  final String? baseUrl;
  final List<AbsState> states;
  final Map<String, dynamic>? headers;
  final List<String>? inputProperties;
  final Map<String, List<String>>? predicate;
}

abstract class AbsState {
  AbsState({required this.key});

  final String key;

  Future<dynamic> execute(Rusher rusher, RRusher rRusher, Rush rush);
}

class NothingState extends AbsState {
  NothingState({required String key, required this.name}) : super(key: key);
  final String name;

  @override
  Future execute(Rusher rusher, RRusher rRusher, Rush rush) {
    // TODO: implement execute
    throw UnimplementedError();
  }
}

class DioState extends AbsState {
  DioState(
      {required String key,
      required this.method,
      required this.endpoint,
      required this.headers,
      this.baseUrl,
      this.dynamicBody,
      this.dynamicQuery,
      this.dynamicHeaders,
      this.forQuery,
      this.forBody,
      this.forHeader,
      this.predicate})
      : super(key: key);
  final String method;
  final String? baseUrl;
  final String endpoint;
  final Map<String, dynamic>? headers;
  final List<String>? dynamicQuery;
  final List<String>? dynamicBody;
  final List<String>? dynamicHeaders;
  final Map<String, List<String>>? forQuery;
  final Map<String, List<String>>? forBody;
  final Map<String, List<String>>? forHeader;
  final Map<String, List<String>>? predicate;

  String mergeBaseUrl(Rush rush) {
    return (baseUrl ?? rush.baseUrl)!;
  }

  Map<String, String> mergeHeaders(Rush rush) {
    Map<String, String> merge = {};
    rush.headers?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    headers?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    return merge;
  }

  Map<String, List<String>> mergePredicate(Rush rush) {
    Map<String, List<String>> merge = {};
    rush.predicate?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    predicate?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    return merge;
  }

  @override
  Future<Map<String, dynamic>?> execute(
      Rusher rusher, RRusher rRusher, Rush rush) async {
    final currentUrl = mergeBaseUrl(rush);
    final currentPredicate = mergePredicate(rush);

    Map<String, dynamic>? currentHeaders = mergeHeaders(rush);
    dynamicHeaders?.forEach((key) {
      final value = rRusher.bodyCache[key];
      if (value != null) {
        currentHeaders.putIfAbsent(key, () => value);
      }
    });

    Map<String, dynamic>? currentQuery = {};
    dynamicBody?.forEach((key) {
      final value = rRusher.bodyCache[key];
      if (value != null) {
        currentQuery.putIfAbsent(key, () => value);
      }
    });

    Map<String, dynamic>? currentBody = {};
    dynamicBody?.forEach((key) {
      final value = rRusher.bodyCache[key];
      if (value != null) {
        currentBody.putIfAbsent(key, () => value);
      }
    });

    Map<String, dynamic>? data = await rusher.request(method, currentUrl,
        currentHeaders, currentQuery, currentBody, currentPredicate);
    return data;
  }
}

class JioState extends AbsState {
  JioState(
      {required String key,
      required this.name,
      required this.document,
      required this.function,
      this.options,
      this.forQuery,
      this.predicate})
      : super(key: key);
  final String name;
  final String document;
  final String function;
  final List<String>? options;
  final Map<String, List<String>>? forQuery;
  final Map<String, List<String>>? predicate;

  Map<String, List<String>> mergePredicate(Rush rush) {
    Map<String, List<String>> merge = {};
    rush.predicate?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    predicate?.forEach((key, value) {
      merge.putIfAbsent(key, () => value);
    });
    return merge;
  }

  @override
  Future<Map<String, dynamic>?> execute(
      Rusher rusher, RRusher rRusher, Rush rush) {
    final predicate = mergePredicate(rush);

    return rusher.runJs(function, predicate);
  }
}

class DartState extends AbsState {
  DartState({required String key, required this.name}) : super(key: key);
  final String name;

  @override
  Future execute(Rusher rusher, RRusher rRusher, Rush rush) async {
    switch (name) {
      case "t10*1000":
        final t10 =
            (DateTime.now().microsecondsSinceEpoch ~/ 1000 * 1000).toString();
        return await Future.value(t10);
    }
    throw UnimplementedError("其他功能尚未拓展");
  }
}
