import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_logging_interceptor/dio_logging_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:ok_rush/pages/base/base_rush.dart';
import 'package:ok_rush/utils/jio.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Rusher {
  final Dio _dio = Dio();
  late final Jio? _jio;

  get onJioCallback => _jio!.callback;

  bool _enabled = true;

  WebViewController webViewController;
  int minMillis;
  int maxMillis;
  void Function(String, bool) logger;

  Duration durationSafe = const Duration(microseconds: 5000);

  Rusher(String? name, String? baseUrl) {
    _dio.interceptors.add(DioLoggingInterceptor(
        level: kDebugMode ? Level.body : Level.none, compact: false));
    if (name != null) {
      _jio = Jio(name);
    }
  }

  bool isExpected(
      Map<String, dynamic> data, Map<String, List<String>> predicate) {
    var shouldRepeat = false;
    predicate.forEach((key, value) {
      dynamic target = data;
      for (var item in value) {
        target = target[item];
      }
      shouldRepeat = target == key;
    });
    return shouldRepeat;
  }

  Future<Map<String, dynamic>?> request(method, url, headers, query, data,
      Map<String, List<String>> predicate) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);
    try {
      final response = await _dio.request(url,
          queryParameters: query,
          data: data,
          options: Options(headers: headers, responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.data);
        if (isExpected(data, predicate)) {
          logger(data.toString(), true);
          return data;
        }
      }
      if (response.data != null) {
        logger("$delayMillis - ${jsonDecode(response.data).toString()}", false);
      } else {
        logger("$delayMillis - ${response.statusCode}", false);
      }
    } on DioError catch (e) {
      logger("$delayMillis - ${e.message}", false);
    } catch (e) {
      logger("$delayMillis - $e", false);
      return await Future.delayed(durationSafe, () async {
        if (!_enabled) return null;
        return await request(method, url, headers, predicate);
      });
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await request(method, url, headers, predicate);
      });
    } else {
      if (!_enabled) return null;
      return await request(method, url, headers, predicate);
    }
  }

  Future runJs(String js, Map<String, List<String>> predicate) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);

    final result = await _jio!.runJs(webViewController, js);
    debugPrint(result);
    try {
      Map<String, dynamic> data = jsonDecode(result);
      if (isExpected(data, predicate)) {
        logger(data.toString(), true);
        return data;
      }
      logger("$delayMillis - $result", false);
    } catch (e) {
      logger("$delayMillis - ${e.toString()}", false);
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await runJs(js, predicate);
      });
    } else {
      if (!_enabled) return null;
      return await runJs(js, predicate);
    }
  }

  Future<Map<String, dynamic>?> ensureGet(
      url,
      headers,
      Map<String, List<String>> predicate,
      int minMillis,
      int maxMillis,
      void Function(String, bool) logger) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);
    try {
      final response = await _dio.get(url,
          options: Options(headers: headers, responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.data);
        if (isExpected(data, predicate)) {
          logger(data.toString(), true);
          return data;
        }
      }
      if (response.data != null) {
        logger("$delayMillis - ${jsonDecode(response.data).toString()}", false);
      } else {
        logger("$delayMillis - ${response.statusCode}", false);
      }
    } on DioError catch (e) {
      logger("$delayMillis - ${e.message}", false);
    } catch (e) {
      logger("$delayMillis - $e", false);
      return await Future.delayed(durationSafe, () async {
        if (!_enabled) return null;
        return await ensureGet(
            url, headers, predicate, minMillis, maxMillis, logger);
      });
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await ensureGet(url, headers, predicate, minMillis, maxMillis, logger);
      });
    } else {
      if (!_enabled) return null;
      return await ensureGet(url, headers, predicate, minMillis, maxMillis, logger);
    }
  }

  Future<Uint8List?> ensureGetBytes(url, headers,
      PredicateType Function(Map<String, dynamic>) predicate,
      int minMillis, int maxMillis,
      void Function(String, PredicateType) logger) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);
    try {
      final response = await _dio.get(url,
          options: Options(headers: headers, responseType: ResponseType.bytes));
      if (response.statusCode == 200) {
        return response.data;
      } else {
        logger("$delayMillis - ${response.statusCode}", PredicateType.repeat);
      }
    } on DioError catch (e) {
      logger("$delayMillis - ${e.message}", PredicateType.repeat);
    } catch (e) {
      logger("$delayMillis - $e", PredicateType.repeat);
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await ensureGetBytes(url, headers, predicate, minMillis, maxMillis, logger);
      });
    } else {
      if (!_enabled) return null;
      return await ensureGetBytes(url, headers, predicate, minMillis, maxMillis, logger);
    }
  }

  Future<Map<String, dynamic>?> ensurePost(url, headers, data,
      PredicateType Function(Map<String, dynamic>) predicate,
      int minMillis, int maxMillis,
      void Function(String, PredicateType) logger) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);
    try {
      final response = await _dio.post(url,
          data: data,
          options: Options(headers: headers, responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.data);
        final predicateType = predicate(data);
        if ([PredicateType.restart, PredicateType.stop].contains(predicateType)) {
          logger(data.toString(), predicateType);
          return data;
        }
      }
      if (response.data != null) {
        logger("$delayMillis - ${jsonDecode(response.data)}", PredicateType.repeat);
      } else {
        logger("$delayMillis - ${response.statusCode}", PredicateType.repeat);
      }
    } on DioError catch (e) {
      logger("$delayMillis - ${e.message}", PredicateType.repeat);
    } catch (e) {
      logger("$delayDuration - $e", PredicateType.repeat);
      return await Future.delayed(durationSafe, () async {
        if (!_enabled) return null;
        return await ensurePost(url, headers, data, predicate, minMillis, maxMillis, logger);
      });
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await ensurePost(url, headers, data, predicate, minMillis, maxMillis, logger);
      });
    } else {
      if (!_enabled) return null;
      return await ensurePost(url, headers, data, predicate, minMillis, maxMillis, logger);
    }
  }

  Future ensureRunJs(WebViewController controller, String js,
      PredicateType Function(Map<String, dynamic>) predicate,
      int minMillis, int maxMillis,
      void Function(String, PredicateType) logger) async {
    if (!_enabled) return null;
    minMillis = max(0, minMillis);
    final nextMillis = max(1, maxMillis - minMillis);
    final delayMillis = Random().nextInt(nextMillis) + minMillis;
    final delayDuration = Duration(milliseconds: delayMillis);

    final result = await _jio!.runJs(controller, js);
    debugPrint(result);
    try {
      Map<String, dynamic> data = jsonDecode(result);
      final predicateType = predicate(data);
      if ([PredicateType.restart, PredicateType.stop].contains(predicateType)) {
        logger(data.toString(), predicateType);
        return data;
      }
      logger("$delayMillis - $result", PredicateType.repeat);
    } catch (e) {
      logger("$delayMillis - ${e.toString()}", PredicateType.repeat);
    }
    if (delayMillis > 0) {
      return await Future.delayed(delayDuration, () async {
        if (!_enabled) return null;
        return await ensureRunJs(controller, js, predicate, minMillis, maxMillis, logger);
      });
    } else {
      if (!_enabled) return null;
      return await ensureRunJs(controller, js, predicate, minMillis, maxMillis, logger);
    }
  }

  void start() {
    _enabled = true;
  }

  void stop() {
    _enabled = false;
  }

  void dispose() {
    stop();
    _dio.close();
    _jio?.close();
  }
}
