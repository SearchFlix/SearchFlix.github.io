import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TMDBService {
  static const String _apiKey = '1dc4cbf81f0accf4fa108820d551dafc'; // Actual TMDB API Key
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey'));
    return _handleResponse(response);
  }

  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey'));
    return _handleResponse(response);
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final response = await http.get(Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey'));
    return _handleResponse(response);
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey&append_to_response=videos,credits'));
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
