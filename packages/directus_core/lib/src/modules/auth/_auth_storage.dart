import 'package:directus_core/src/data_classes/directus_storage.dart';

import '_auth_fields.dart';
import 'auth_response.dart';

class AuthStorage {
  final DirectusStorage storage;

  /// Key used for differentiating between multiple storages
  final AuthFields fields;

  AuthStorage(
    this.storage, {
    String? key,
  }) : fields = AuthFields(key ?? 'default');

  static const String _authKey = 'directus__auth';

  /// Store login data to cold storage, and set it in memory.
  ///
  /// This method is used after fetching new data from server,
  Future<void> storeLoginData(AuthResponse data) async {
    await storage.setItem<AuthResponse>(_authKey, data);
    return;
  }

  /// Store login data to both cold storage and in memory.
  ///
  /// This method should only be called in [init], this will fetch data
  /// from cold storage and return it.
  Future<AuthResponse?> getLoginData() async {
    return await storage.getItem<AuthResponse>(_authKey, AuthResponse.fromMap);
  }

  /// Delete data from storage
  ///
  /// This method should be called to remove auth
  Future<void> removeLoginData() async {
    await storage.removeItem(_authKey);
    return;
  }
}
