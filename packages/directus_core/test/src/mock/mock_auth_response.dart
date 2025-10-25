import 'package:directus_core/src/modules/auth/auth_response.dart';

AuthResponse mockAuthResponse() {
  return AuthResponse(
    accessToken: 'accessToken',
    accessTokenExpiresAt: DateTime.now(),
    accessTokenTtlMs: 1000,
    refreshToken: 'refreshToken',
  );
}
