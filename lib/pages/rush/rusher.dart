import 'package:ok_rush/pages/rush/rush.dart';
import 'package:ok_rush/utils/rusher.dart';

class RRusher {
  var queryCache = {};
  var bodyCache = {};
  var headerCache = {};

  late AbsState rushState;
  final Rusher rusher;
  final Rush rush;

  RRusher(this.rusher, this.rush);

  Future<void> nextState(int index, dynamic data) async {
    rushState = rush.states[index];
    data = await rushState.execute(rusher, rush);
    nextState(index + 1, data);
  }

  void updateCacheFromResponse(Map<String, dynamic> cache, dynamic data,
      Map<String, List<String>>? forCache) {
    dynamic temp;
    forCache?.forEach((key, value) {
      temp = data;
      for (var item in value) {
        temp = temp[item];
      }
      cache.putIfAbsent(key, () => temp);
    });
  }

  void updateQuery() {}

  Future<dynamic> execute() {}
}
