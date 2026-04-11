import 'package:collection/collection.dart';

extension type DoubledMap<K, V>(Map<K, V> _baseMap) implements Map<K, V> {
  K? removeValue(V value) {
    final entry = entries.firstWhereOrNull((e) => e.value == value);
    if (entry == null) return null;
    remove(entry.key);
    return entry.key;
  }
}
