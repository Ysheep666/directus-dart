/// Interface that any custom storage must fulfill to use
/// their storage for storing directus internal data.
/// SDK uses `shared_preferences` by default.
/// If user wants something more secure, store remotely on some server,
/// write to file, or to use other DB engine, user needs to implement all methods.
abstract class DirectusStorage {
  /// Call this method to store data.
  Future<void> setItem<T>(String key, T value);

  /// Call this method to get data from storage.
  Future<T?> getItem<T>(String key, T Function(Map<String, dynamic>) fromJson);

  /// Call this method to remove data from storage.
  Future<void> removeItem(String key);
}
