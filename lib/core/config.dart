import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static late String baseUrl;

  static Future<void> initialize() async {
    await dotenv.load();
    baseUrl = dotenv.get('BASE_URL');
  }
}
