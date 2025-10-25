import 'package:directus_core/src/modules/auth/_auth_fields.dart';
import 'package:directus_core/src/modules/auth/auth_response.dart';
import 'package:directus_core/src/modules/auth/_auth_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../mock/mocks.mocks.dart';

void main() {
  // TODO Fix this test, it's skiping currently
  // It is a problem with mockito generation, I just don't know where or why
  group('AuthStorage', () {
    late MockDirectusStorage storage;
    late AuthStorage authStorage;
    late AuthFields fields;

    setUp(() {
      storage = MockDirectusStorage();
      authStorage = AuthStorage(storage);
      fields = AuthFields();
    });

    test('storeLoginData', () async {
      final now = DateTime.now();
      when(storage.setItem(any, any)).thenAnswer((realInvocation) async {});
      await authStorage.storeLoginData(
        AuthResponse(
          accessToken: 'accessToken',
          accessTokenExpiresAt: now,
          accessTokenTtlMs: 1000,
          refreshToken: 'refreshToken',
        ),
      );

      // New storage model stores all auth data under a single key
      verify(storage.setItem('directus__auth', any)).called(1);
    });

    test('getLoginData', () async {
      // Align with new getItem signature (key, fromJson)
      when(storage.getItem(any, any))
          .thenAnswer((realInvocation) async => null);

      final data = await authStorage.getLoginData();

      expect(data, isNull);
      // Only a single getItem call is made in the new model
      verify(storage.getItem('directus__auth', any)).called(1);
    });

    test('removeLoginData', () async {
      when(storage.removeItem(any)).thenAnswer((_) async {});

      await authStorage.removeLoginData();
      // New storage model removes a single key
      verify(storage.removeItem('directus__auth')).called(1);
    });
  }, skip: true);
}
