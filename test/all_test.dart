import 'package:pooled_map/pooled_map.dart';
import 'package:test/test.dart';

void main() {
  group('lock-entire-map', tests(true));
  group('independent-keys', tests(true));
}

void Function() tests(bool lockEntireMap) {
  return () {
    PooledMap<String, int> map;

    setUp(() => map = new PooledMap<String, int>());

    tearDown(() => map.clear());

    test('is empty by default', () {
      expect(map.isEmpty, completion(true));
      expect(map.isNotEmpty, completion(false));
    });

    test('addAll', () async {
      await map.addAll({'1': 1, '23': 23});
      expect(map.toMap(), completion({'1': 1, '23': 23}));
    });

    group('after insert', () {
      setUp(() => map.put('ten', 10));

      test('keys', () {
        expect(map.keys, completion(['ten']));
      });

      test('values', () {
        expect(map.values, completion([10]));
      });

      test('length', () {
        expect(map.length, completion(1));
      });

      test('containsKey', () {
        expect(map.containsKey('ten'), completion(true));
        expect(map.containsKey('eleven'), completion(false));
      });

      test('putIfAbsent', () {
        expect(map.putIfAbsent('ten', () => 234), completion(10));
      });

      test('update', () {
        expect(map.update('ten', (i) => i * i), completion(100));
        expect(map['ten'], completion(100));
      });

      test('clone', () {
        expect(map.clone().then((m) => m.toMap()), completion({'ten': 10}));
      });

      group('remove', () {
        test('returns value', () {
          expect(map.remove('ten'), completion(10));
        });

        test('becomes empty', () {
          expect(map.remove('ten').then((_) => map.isEmpty), completion(true));
          expect(
              map.remove('ten').then((_) => map.isNotEmpty), completion(false));
        });
      });
    });
  };
}
