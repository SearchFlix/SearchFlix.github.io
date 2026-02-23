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

  Future<List<Map<String, dynamic>>> getGenres() async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/genre/movie/list?api_key=${ApiConfig.tmdbApiKey}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['genres']);
    }
    return [];
  }

  Future<List<Movie>> discoverMovies({
    int? year,
    String? genreId,
    double? minRating,
    String? castIds,
    String? sortBy = 'popularity.desc',
    String? language,
  }) async {
    String url = '${ApiConfig.tmdbBaseUrl}/discover/movie?api_key=${ApiConfig.tmdbApiKey}&sort_by=$sortBy';
    if (year != null) url += '&primary_release_year=$year';
    if (genreId != null) url += '&with_genres=$genreId';
    if (minRating != null) url += '&vote_average.gte=$minRating';
    if (castIds != null && castIds.isNotEmpty) url += '&with_cast=$castIds';
    if (language != null && language != 'all') url += '&with_original_language=$language';

    final response = await http.get(Uri.parse(url));
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> searchActors(String query) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/search/person?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return [];
  }

  Future<List<Movie>> getSimilarMovies(List<int> movieIds) async {
    if (movieIds.isEmpty) return [];
    List<Movie> combinedResults = [];
    for (var id in movieIds.take(3)) {
      final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/$id/recommendations?api_key=${ApiConfig.tmdbApiKey}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        combinedResults.addAll(results.map((m) => Movie.fromJson(m)).toList());
      }
    }
    final seen = <int>{};
    return combinedResults.where((m) => seen.add(m.id)).toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=${ApiConfig.tmdbApiKey}&append_to_response=videos,credits,external_ids'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<Map<String, dynamic>> getTVShowDetails(int tvId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/tv/$tvId?api_key=${ApiConfig.tmdbApiKey}&append_to_response=videos,credits,external_ids'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  Future<List<Movie>> getActorMovies(int actorId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/person/$actorId/combined_credits?api_key=${ApiConfig.tmdbApiKey}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List cast = data['cast'] ?? [];
      return cast.map((m) => Movie.fromJson(m)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/person/$personId?api_key=${ApiConfig.tmdbApiKey}'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load person details');
  }

  Future<List<Movie>> getSimilarTVShows(int tvId) async {
    final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/tv/$tvId/recommendations?api_key=${ApiConfig.tmdbApiKey}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((m) => Movie.fromJson(m)).toList();
    }
    return [];
  }

  Future<Movie> getRandomMovie() async {
    try {
      // Pick a random page from the first 20 pages of popular movies
      final randomPage = (DateTime.now().microsecondsSinceEpoch % 20) + 1;
      final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/popular?api_key=${ApiConfig.tmdbApiKey}&page=$randomPage'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        if (results.isEmpty) throw Exception('No movies found');
        
        final randomIndex = DateTime.now().microsecondsSinceEpoch % results.length;
        return Movie.fromJson(results[randomIndex]);
      } else {
        throw Exception('Failed to fetch data from TMDB');
      }
    } catch (e) {
      // Fallback: search for a common term and pick one
      final response = await http.get(Uri.parse('${ApiConfig.tmdbBaseUrl}/movie/top_rated?api_key=${ApiConfig.tmdbApiKey}&page=1'));
      final data = json.decode(response.body);
      final List results = data['results'];
      return Movie.fromJson(results[0]);
    }
  }

  List<Movie> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((m) => Movie.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }
}
