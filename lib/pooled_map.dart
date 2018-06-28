import 'dart:async';
import 'package:pool/pool.dart';

/// An asynchronous map for Dart that locks keys, to avoid the Thundering Herd problem.
class PooledMap<T, U> {
  /// The maximum amount of concurrent reads+writes to a given key.
  final int maxConcurrency;

  /// Whether to lock the entire map when querying the map.
  ///
  /// By default, this is `false`, and each key is treated as completely independent.
  ///
  ///
  /// If you regularly plan to query the `length`, `keys`, `values`, or `clear`,
  /// consider enabling this.
  final bool lockEntireMap;

  final Map<T, U> _data = {};
  final Map<T, Pool> _pools = {};
  final Pool _keyPool = new Pool(1);

  PooledMap({this.maxConcurrency: 1, this.lockEntireMap: false});

  /// Copies the contents of a [map] into a new [PooledMap].
  factory PooledMap.from(Map<T, U> map,
          {int maxConcurrency: 1, bool lockEntireMap: false}) =>
      new PooledMap<T, U>(
          maxConcurrency: maxConcurrency, lockEntireMap: lockEntireMap)
        .._data.addAll(map);

  Future<V> _getPool<V>(T key, FutureOr<V> Function(Pool) f) {
    return _keyPool.request().then((keyResx) {
      var pool = _pools.putIfAbsent(key, () => new Pool(maxConcurrency));

      if (lockEntireMap) {
        return new Future<V>.sync(() => f(pool)).whenComplete(keyResx.release);
      } else {
        keyResx.release();
        return f(pool);
      }
    });
  }

  /// Retrieves the length of this map.
  Future<int> get length => _keyPool.withResource(() => _data.length);

  /// Determines if the map is empty.
  Future<bool> get isEmpty => _keyPool.withResource(() => _data.isEmpty);

  /// Determines if the map is not empty.
  Future<bool> get isNotEmpty => isEmpty.then((empty) => !empty);

  /// Retrieves an unmodifiable list of this map's keys.
  Future<List<T>> get keys => _keyPool
      .withResource(() => new List<T>.unmodifiable(_data.keys.toList()));

  /// Retrieves an unmodifiable list of this map's values.
  Future<List<U>> get values => _keyPool
      .withResource(() => new List<U>.unmodifiable(_data.values.toList()));

  Future clear() => _keyPool.withResource(() => _data.clear());

  /// Determines if the map contains a given [key].
  Future<bool> containsKey(T key) =>
      _keyPool.withResource(() => _pools.containsKey(key));

  /// Creates a new, synchronously-available [Map] from the contents of this one.
  Future<Map<T, U>> toMap() =>
      _keyPool.withResource(() => new Map<T, U>.from(_data));

  /// Duplicates this [PooledMap].
  Future<PooledMap<T, U>> clone() => toMap()
      .then((map) => new PooledMap.from(map, maxConcurrency: maxConcurrency));

  /// Get the value for the given [key].
  Future<U> operator [](T key) =>
      _getPool(key, (pool) => pool.withResource(() => _data[key]));

  /// Sets a [value] for the given [key].
  void operator []=(T key, U value) => put(key, value);

  /// Asynchronously adds all of the given [values] into the map.
  Future addAll(Map<T, U> values) {
    return Future.wait(values.keys.map((k) => update(k, (_) => values[k])));
  }

  /// Sets a [value] for the given [key].
  Future<U> put(T key, U value) =>
      _getPool(key, (pool) => pool.withResource(() => _data[key] = value));

  /// Sets a value for the given [key], based on a [computation] against the current value.
  ///
  /// A [defaultValue] may be provided, in the case the [key] is not present in the map.
  Future<U> update(T key, FutureOr<U> Function(U) computation,
      {FutureOr<U> Function() defaultValue}) {
    return _getPool(key, (pool) {
      return pool.withResource(() {
        Future ensure;
        if (defaultValue == null) {
          ensure = new Future.value();
        } else {
          ensure = new Future.sync(defaultValue)
              .then((v) => _data.putIfAbsent(key, () => v));
        }

        return ensure
            .then((_) => computation(_data[key]))
            .then((v) => _data[key] = v);
      });
    });
  }

  /// Removes, and returns, the value for a given [key].
  Future<U> remove(T key) {
    return _getPool(key, (pool) {
      return pool.withResource(() => _data.remove(key));
    });
  }

  /// Gets the value for the given [key], or insert a new [value].
  Future<U> putIfAbsent(T key, FutureOr<U> Function() value) {
    return _getPool(key, (pool) {
      return pool.withResource(() {
        if (_data.containsKey(key)) return _data[key];
        var f = new Future.sync(value);
        return f.then((v) => _data[key] = v);
      });
    });
  }
}
