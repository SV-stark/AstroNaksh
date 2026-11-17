/// Bounded Least-Recently-Used (LRU) cache for ephemeris calculations.
class EphemerisCache<K, V> {
  /// Creates an [EphemerisCache] with the given [maxSize].
  EphemerisCache({this.maxSize = 5000}) : assert(maxSize > 0);

  /// Maximum number of entries retained before the oldest entry is evicted.
  final int maxSize;
  final Map<K, V> _entries = {};

  /// Returns the cached value for [key] and marks it as most-recently-used,
  /// or `null` if [key] is not present.
  V? get(K key) {
    if (!_entries.containsKey(key)) return null;
    final value = _entries.remove(key) as V;
    _entries[key] = value;
    return value;
  }

  /// Stores [value] under [key], evicting the least-recently-used entry if full.
  void put(K key, V value) {
    if (_entries.containsKey(key)) {
      _entries.remove(key);
    } else if (_entries.length >= maxSize) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = value;
  }

  /// Removes all entries from the cache.
  void clear() => _entries.clear();
}
