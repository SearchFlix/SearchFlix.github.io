import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/api_config.dart';

class SearchFlixService {
  Future<List<DownloadSource>> fetchDownloadLinks(String movieTitle) async {
    try {
      final query = Uri.encodeComponent(movieTitle);
      // Try search endpoint first
      final searchUrl = '${ApiConfig.searchFlixBaseUrl}/movie/search/$query/${ApiConfig.searchFlixApiKey}';
      
      print('Fetching links for: $movieTitle');
      print('Search URL: $searchUrl');
      
      final response = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Search successful, data length: ${data is List ? data.length : 'Object'}');
        
        List? results;
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] != null) {
          results = data['results'];
        }
        
        if (results != null && results.isNotEmpty) {
          // Find closest match by title
          final bestMatch = results.firstWhere(
            (m) => m['title']?.toString().toLowerCase() == movieTitle.toLowerCase(),
            orElse: () => results!.first,
          );
          
          if (bestMatch['sources'] != null) {
            final List sourcesList = bestMatch['sources'];
            return sourcesList.map((s) => DownloadSource.fromJson(s)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('Error fetching SearchFlix links: $e');
      return [];
    }
  }
}
