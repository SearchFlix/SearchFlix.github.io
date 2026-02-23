import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/movie.dart';
import 'tmdb_service.dart';

class AiService {
  final TMDBService _tmdbService = TMDBService();
  
  static const String _apiKeyToken = 'gemini_api_key';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyToken);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyToken, key);
  }

  Future<List<Movie>> getRecommendations(String query) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key missing. Please add it in Profile settings.');
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    
    final prompt = '''
      You are a movie expert AI for an app called SearchFlix. 
      The user is asking: "$query"
      
      Based on this query, recommend exactly 5 movies. 
      Format your response ONLY as a JSON list of movie titles. 
      Example: ["Inception", "The Matrix", "Interstellar"]
      Do not include any other text except the JSON array.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text;
      
      if (text == null) return [];

      // Clean the string if Gemini adds markdown backticks
      String cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      List<dynamic> titles = json.decode(cleanedText);
      
      List<Movie> results = [];
      for (var title in titles) {
        final movieResults = await _tmdbService.searchMovies(title.toString());
        if (movieResults.isNotEmpty) {
          results.add(movieResults.first);
        }
      }
      return results;
    } catch (e) {
      rethrow;
    }
  }
}
