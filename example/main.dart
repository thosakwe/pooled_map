import 'dart:async';
import 'package:pooled_map/pooled_map.dart';

main() async {
  // Even though we start 100000 simultaneous, asynchronous updates,
  // access is restricted to one-at-a-time.
  //
  // Thus, the output will be 100000.
  var i = 100000;
  var map = new PooledMap<String, int>(lockEntireMap: true);

  Future<int> increment() {
    return map.update('i', (i) => i + 1, defaultValue: () => 0);
  }

  var futures = new List<Future<int>>.generate(i, (_) => increment());
  await Future.wait(futures);
  var value = await map['i'];
  print('$value == 100000');
}
