import '../directus_core.dart';

/// MemoryStorage is mainly used for testing
class MemoryStorage extends DirectusStorage {
  final Map<String, Object> _store = {};

  /// Get item from storage
  @override
  Future<T?> getItem<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final value = _store[key];
    if (value == null) return null;
    return fromJson(value as Map<String, dynamic>);
  }

  /// Set item to storage
  ///
  @override
  Future<void> setItem<T>(String key, T value) async {
    _store[key] = value as Object;
  }

  /// Remove item from storage
  @override
  Future<void> removeItem(String key) async {
    _store.remove(key);
  }
}
