import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/api_config.dart';

class TMDBService {
  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/trending/movie/day?api_key=${ApiConfig.tmdbApiKey}'));
    return _handleResponse(response);
  }

  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/popular?api_key=${ApiConfig.tmdbApiKey}'));
    return _handleResponse(response);
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/top_rated?api_key=${ApiConfig.tmdbApiKey}'));
    return _handleResponse(response);
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    final response = await http.get(
      Uri.parse('${ApiConfig.tmdbBaseUrl}/search/movie?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=${ApiConfig.tmdbApiKey}&append_to_response=videos,credits'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  List<Movie> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((m) => Movie.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load data from TMDB');
    }
  }
}
