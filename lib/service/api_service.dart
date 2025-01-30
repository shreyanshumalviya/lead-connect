import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<Map<String, String>> getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('phoneNumber') ?? '';

      return {
        'Content-Type': 'application/json',
        'user_id': userId,
      };
    } catch (e) {
      print('Error getting headers: $e');
      return {
        'Content-Type': 'application/json',
        'user_id': '99',
      };
    }
  }
}
