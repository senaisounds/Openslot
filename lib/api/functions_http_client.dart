import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/config/environment_config.dart';

/// Shared helper for authenticated HTTP calls to Cloud Functions.
class FunctionsHttpClient {
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  /// Returns headers including a fresh Firebase ID token.
  /// Throws if the user is not signed in.
  static Future<Map<String, String>> authHeaders({
    String contentType = 'application/json',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Failed to get auth token');
    }
    return {
      'Content-Type': contentType,
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    String contentType = 'application/json',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final headers = await authHeaders(contentType: contentType);
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body,
        )
        .timeout(timeout);
  }
}
