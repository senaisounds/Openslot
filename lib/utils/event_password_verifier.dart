import 'dart:convert';
import 'package:http/http.dart' as http;

class EventPasswordVerifier {
  static const String _verifyEndpoint = 'https://us-central1-open-mic-5cc8e.cloudfunctions.net/verifyEventPassword';

  static Future<bool> verify(String eventId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'eventID': eventId,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final data = json.decode(response.body);
      return data['valid'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
} 