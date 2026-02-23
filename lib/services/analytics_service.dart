import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  static const String _baseUrl = 'https://searchflix.github.io/server/api/stats.php';

  static Future<void> trackHit() async {
    try {
      await http.get(Uri.parse('$_baseUrl?action=track'));
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
    } catch (e) {
      print('Fetch stats error: $e');
    }
    return null;
  }
}
