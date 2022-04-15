import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:dio_logging_interceptor/dio_logging_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/pages/rush/web_engine.dart';

class Rusher {
  final Dio _dio = Dio();

  var _enabled = true;
  CancelableOperation? _cancelableOperation;

  int? minMs;
  int? nextMs;
  WebController? controller;
  final void Function(String, bool) logger;

  Rusher(this.logger) {
    _dio.interceptors.add(DioLoggingInterceptor(
        level: kDebugMode ? Level.body : Level.none, compact: false));
  }

  void start(minMs, maxMs, WebController? controller) {
    _enabled = true;
    this.minMs = max(0, minMs);
    nextMs = max(1, maxMs - minMs);
    this.controller = controller;
  }

  Future<dynamic> request(type, options) async {
    switch (type.runtimeType) {
      case DIORunner:
        return await _dioRequest(options);
      case JIORunner:
        return await _jioRequest(options);
    }
  }

  Future<dynamic> _dioRequest(options) async {
    if (!_enabled) return null;
    final delayMs = Random().nextInt(nextMs!) + minMs!;
    final delayDuration = Duration(milliseconds: delayMs);
    try {
      final response = await _dio.request(options["url"],
          queryParameters: options["query"],
          data: options["body"],
          options: Options(
              method: options["method"],
              headers: options["headers"],
              responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.data);
        if (_isExpected(data, options["predicate"])) {
          logger(data.toString(), true);
          return data;
        } else {
          logger("$delayMs - ${data.toString()}", false);
        }
      } else {
        logger("$delayMs - ${response.statusCode}", false);
      }
    } on DioError catch (e) {
      logger("$delayMs - ${e.message}", false);
    } catch (e) {
      logger("$delayMs - $e", false);
    }
    if (delayMs > 0) {
      if (!_enabled) return null;
      _cancelableOperation = CancelableOperation.fromFuture(
          Future.delayed(delayDuration, () async {
        if (_cancelableOperation?.isCanceled ?? true) return;
        return await _dioRequest(options);
      }));
      return await _cancelableOperation?.value;
    } else {
      return await _dioRequest(options);
    }
  }

  Future<dynamic> _jioRequest(options) async {
    if (!_enabled) return null;
    final delayMillis = Random().nextInt(nextMs!) + minMs!;
    final delayDuration = Duration(milliseconds: delayMillis);
    final script = "${options["function"]}(${options["args"]})";
    try {
      dynamic response;
      if (options["sync"] ?? false) {
        response = await controller?.webViewController
            .runJavascriptReturningResult(script);
        if (response is String) response = jsonDecode(response);
      } else {
        controller?.completer = Completer();
        await controller?.webViewController.runJavascript(script);
        response = await controller?.completer!.future;
      }
      if (response is String) response = jsonDecode(response);
      if (_isExpected(response, options["predicate"])) {
        logger(response.toString(), true);
        return response;
      }
      logger("$delayMillis - $response", false);
    } catch (e) {
      logger("$delayMillis - ${e.toString()}", false);
    }
    if (delayMillis > 0) {
      if (!_enabled) return null;
      _cancelableOperation = CancelableOperation.fromFuture(
          Future.delayed(delayDuration, () async {
        if (_cancelableOperation?.isCanceled ?? true) return;
        return await _jioRequest(options);
      }));
      return await _cancelableOperation?.value;
    } else {
      return await _jioRequest(options);
    }
  }

  bool _isExpected(Map<String, dynamic> data, Map<String, dynamic>? predicate) {
    var isExpected = true;
    predicate?.forEach((key, value) {
      dynamic target = data;
      for (var item in value) {
        target = target[item];
      }
      debugPrint("predicate:${target.toString()} $key");
      isExpected = target.toString() == key;
    });
    return isExpected;
  }

  void stop() {
    _enabled = false;
    _cancelableOperation?.cancel();
  }

  void dispose() {
    stop();
    _dio.close();
  }
}
