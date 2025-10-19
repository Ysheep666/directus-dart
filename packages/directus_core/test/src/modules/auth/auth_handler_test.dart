import 'package:dio/dio.dart';
import 'package:directus_core/src/data_classes/directus_error.dart';
import 'package:directus_core/src/modules/auth/_auth_response.dart';
import 'package:directus_core/src/modules/auth/_auth_storage.dart';
import 'package:directus_core/src/modules/auth/_current_user.dart';
import 'package:directus_core/src/modules/auth/_tfa.dart';
import 'package:directus_core/src/modules/auth/auth_handler.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../mock/mock_auth_response.dart';
import '../../mock/mock_dio_response.dart';
import '../../mock/mocks.mocks.dart';

// class MockAuthStorage extends Mock implements AuthStorage {}

void main() {
  group('AuthHandler', () {
    late MockDirectusStorage storage;
    late MockDio client;
    late MockDio refreshClient;
    late AuthHandler auth;
    late MockAuthStorage authStorage;
    Map getRefreshResponse() => {
          'data': {
            'refresh_token': 'rt',
            'access_token': 'at',
            'expires': 10000,
          }
        };

    setUp(() async {
      storage = MockDirectusStorage();
      client = MockDio();
      refreshClient = MockDio();
      authStorage = MockAuthStorage();
      when(client.options)
          .thenReturn(BaseOptions(baseUrl: 'http://example.com'));
      when(client.interceptors).thenReturn(Interceptors());
      // Adjust to new DirectusStorage.getItem signature (key, fromJson)
      when(storage.getItem(any, any))
          .thenAnswer((realInvocation) async => null);

      when(refreshClient.options)
          .thenReturn(BaseOptions(baseUrl: 'http://example.com'));
      auth = AuthHandler(
          client: client, storage: storage, refreshClient: refreshClient);
      auth.storage = authStorage;
      when(authStorage.getLoginData())
          .thenAnswer((realInvocation) async => null);
      await auth.init();
    });

    test('logout', () async {
      when(client.post('auth/logout', data: anyNamed('data'))).thenAnswer(
          (realInvocation) async =>
              Response(requestOptions: RequestOptions(path: '/')));

      final loginData = mockAuthResponse();
      auth.tokens = loginData;
      await auth.logout();

      expect(auth.currentUser, isNull);
      expect(auth.tfa, isNull);
      verify(client.post('auth/logout',
          data: {'refresh_token': loginData.refreshToken})).called(1);
    });

    test('logout throws error if user is not logged in', () async {
      // reset(client);
      // verifyNoMoreInteractions(client);
      auth.tokens = null;
      expect(() => auth.logout(), throwsA(isA<DirectusError>()));
      verifyNever(client.post(any));
      verifyNever(client.delete(any));
      verifyNever(client.get(any));
      // verifyZeroInteractions(client);
    });

    test('init', () async {
      when(storage.getItem(any, any)).thenAnswer((realInvocation) async => null);
      final auth = AuthHandler(
          client: client, storage: storage, refreshClient: refreshClient);
      await auth.init();
      expect(auth.tokens, isNull);
      expect(auth.currentUser, isNull);
      expect(auth.tfa, isNull);
    });

    test('Init properties when user is logged in', () async {
      when(authStorage.getLoginData())
          .thenAnswer((realInvocation) async => mockAuthResponse());

      final auth = AuthHandler(
          client: client, storage: storage, refreshClient: refreshClient);
      auth.storage = authStorage;
      await auth.init();

      expect(auth.tokens, isA<AuthResponse>());
      expect(auth.currentUser, isA<CurrentUser>());
      expect(auth.tfa, isA<Tfa>());
    });

    test('isLoggedIn', () {
      expect(auth.isLoggedIn, false);
      auth.tokens = mockAuthResponse();
      expect(auth.isLoggedIn, true);
    });

    test('login', () async {
      when(client.post(any, data: anyNamed('data'))).thenAnswer(dioResponse({
        'data': {
          'access_token': 'ac',
          'refresh_token': 'rt',
          'expires': 1000,
        }
      }));

      expect(auth.tokens, isNull);
      expect(auth.currentUser, isNull);
      expect(auth.tfa, isNull);

      auth.storage = AuthStorage(storage);
      await auth.login(
          email: 'email@email', password: 'password1', otp: 'otp1');

      expect(auth.tokens, isA<AuthResponse>());
      expect(auth.currentUser, isA<CurrentUser>());
      expect(auth.tfa, isA<Tfa>());

      verify(storage.setItem('directus__auth', any)).called(1);

      verify(client.post('auth/login', data: {
        'mode': 'json',
        'email': 'email@email',
        'password': 'password1',
        'otp': 'otp1',
      })).called(1);
    });

    test('Do not get new access token if user is not logged in.', () async {
      reset(refreshClient);
      auth.tokens = null;
      final interceptorHandler = MockRequestInterceptorHandler();
      await auth.refreshExpiredTokenInterceptor(
        RequestOptions(path: '/'),
        interceptorHandler,
      );

      verifyZeroInteractions(refreshClient);
      verify(interceptorHandler.next(any)).called(1);

      //
    });

    test('Do not get new access token if AT is valid for more then 10 seconds.',
        () async {
      reset(refreshClient);

      final interceptorHandler = MockRequestInterceptorHandler();
      auth.tokens = mockAuthResponse();
      auth.tokens?.accessTokenExpiresAt =
          DateTime.now().add(Duration(seconds: 11));
      await auth.refreshExpiredTokenInterceptor(
        RequestOptions(path: '/'),
        interceptorHandler,
      );

      verifyZeroInteractions(refreshClient);
      verify(interceptorHandler.next(any)).called(1);
      //
    });

    test('Get new access token if AT is valid for less then 10 seconds.',
        () async {
      when(refreshClient.post(any, data: anyNamed('data')))
          .thenAnswer(dioResponse({
        'data': {
          'refresh_token': 'rt',
          'access_token': 'at',
          'expires': 3600000,
        }
      }));
      auth.storage = authStorage;
      final loginData = mockAuthResponse();
      auth.tokens = loginData;
      auth.tokens!.accessTokenExpiresAt =
          DateTime.now().add(Duration(seconds: 9));
      final interceptorHandler = MockRequestInterceptorHandler();
      await auth.refreshExpiredTokenInterceptor(
        RequestOptions(path: '/'),
        interceptorHandler,
      );

      verify(interceptorHandler.next(any)).called(1);
      verify(refreshClient.post('auth/refresh', data: {
        'mode': 'json',
        'refresh_token': loginData.refreshToken,
      })).called(1);

      verify(authStorage.storeLoginData(any)).called(1);
    });

    test('init listener', () async {
      final auth = AuthHandler(
          client: client, storage: storage, refreshClient: refreshClient);
      auth.storage = authStorage;
      var loggedIn = false;
      var refreshed = false;
      var loggedOut = false;

      auth.onChange((type, event) {
        if (type == 'login') loggedIn = true;
        if (type == 'refresh') refreshed = true;
        if (type == 'logout') loggedOut = true;
      });

      when(client.post(any, data: anyNamed('data'))).thenAnswer(dioResponse({
        'data': {
          'access_token': 'ac',
          'refresh_token': 'rt',
          'expires': 1000,
        }
      }));

      await auth.login(email: 'email@email', password: 'password1');

      when(refreshClient.post(any, data: anyNamed('data')))
          .thenAnswer(dioResponse(getRefreshResponse()));

      await auth.manuallyRefresh();

      when(client.post(any)).thenAnswer(dioResponse());
      await auth.logout();

      expect(loggedIn, true);
      expect(refreshed, true);
      expect(loggedOut, true);
    });
  });
}
