import 'package:dio/dio.dart';
import 'package:directus_core/src/data_classes/directus_error.dart';

/// Response that is returned from login or refresh
class AuthResponse {
  /// Refresh token
  late String refreshToken;

  /// Access token
  late String accessToken;

  /// Access token time to live in milliseconds
  ///
  ///
  late int accessTokenTtlMs;

  /// [DateTime] when access token expires.
  ///
  /// It's using time of app time, not server time.
  late DateTime accessTokenExpiresAt;

  /// Static token
  ///
  String? staticToken;

  /// Constructor for manually creating object
  AuthResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.accessTokenTtlMs,
    required this.refreshToken,
    this.staticToken,
  });

  /// Create [AuthResponse] from [Dio] [Response] object.
  AuthResponse.fromResponse(Response response) {
    // Response is possible to be null in testing when we forget to return response.
    // ignore: unnecessary_null_comparison
    if (response == null || response.data == null) {
      throw DirectusError(
          message: 'Response and response data can\'t be null.');
    }

    final data = response.data?['data'];

    if (data == null) throw Exception('Login response is invalid.');

    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final accessTokenTtlInMs = data['expires'];

    if (accessToken == null ||
        accessTokenTtlInMs is! int ||
        refreshToken == null) {
      throw DirectusError(message: 'Login response is invalid.');
    }

    this.refreshToken = refreshToken;
    this.accessToken = accessToken;
    accessTokenTtlMs = accessTokenTtlInMs;
    accessTokenExpiresAt = DateTime.now().add(
      Duration(milliseconds: accessTokenTtlMs),
    );
  }

  /// Convert [AuthResponse] to [Map] object.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_at': accessTokenExpiresAt.toIso8601String(),
      'access_token_ttl_in_ms': accessTokenTtlMs,
      'refresh_token': refreshToken,
      'static_token': staticToken,
    };
  }

  /// Create [AuthResponse] from [Map] object.
  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      accessToken: map['access_token'] as String,
      accessTokenExpiresAt: DateTime.parse(map['expires_at'] as String),
      accessTokenTtlMs: map['access_token_ttl_in_ms'] as int,
      refreshToken: map['refresh_token'] as String,
      staticToken: map['static_token'] as String?,
    );
  }
}
