import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slotted/api/functions_http_client.dart';

class EventPasswordVerifier {
  static Future<bool> verify(String eventId, String password) async {
    try {
      final headers = await FunctionsHttpClient.authHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      final response = await http.post(
        Uri.parse('${FunctionsHttpClient.baseUrl}/verifyEventPassword'),
        headers: headers,
        body: {
          'eventID': eventId,
          'password': Uri.encodeComponent(password),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final data = json.decode(response.body);
      return data['success'] == true || data['valid'] == true;
    } catch (e) {
      return false;
    }
  }
}
