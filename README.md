# pooled_map
[![Pub](https://img.shields.io/pub/v/pooled_map.svg)](https://pub.dartlang.org/packages/pooled_map)
[![build status](https://travis-ci.org/thosakwe/pooled_map.svg)](https://travis-ci.org/thosakwe/pooled_map)

An asynchronous map for Dart that locks keys, to avoid the Thundering Herd problem.

`package:pooled_map` is best-suited for implementing caches of expensive
operations (i.e. database lookups).

## Notes
* `PooledMap` is inherently asynchronous; therefore, it is incompatible with the standard
`Map`. However, you can easily convert between the two.
* `PooledMap` by default has `lockEntireMap` set to `false`, as this can become a bottleneck
for Web applications. If you plan to frequently query `length`, `keys`, `values`, or `clear`
the map, however, you *may* consider enabling it. Most applications will likely not need it.

## Brief Example
```dart
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
```