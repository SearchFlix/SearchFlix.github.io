import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../config/api_config.dart';

class TMDBService {
  Future<http.Response> _getCached(String url) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        prefs.setString('cache_$url', response.body);
      }
      return response;
    } catch (e) {
      final cachedBody = prefs.getString('cache_$url');
      if (cachedBody != null) {
        return http.Response(cachedBody, 200);
      }
      rethrow;
    }
  }

  Future<List<Movie>> getTrendingMovies() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/trending/movie/day?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> getPopularMovies() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/popular?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/top_rated?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> getTrendingTVShows() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/trending/tv/day?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> getPopularTVShows() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/tv/popular?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> getTopRatedTVShows() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/tv/top_rated?api_key=${ApiConfig.tmdbApiKey}');
    return _handleResponse(response);
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/search/movie?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}');
    return _handleResponse(response);
  }

  Future<List<Movie>> searchTVShows(String query) async {
    if (query.isEmpty) return [];
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/search/tv?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}');
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/genre/movie/list?api_key=${ApiConfig.tmdbApiKey}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['genres']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getTVGenres() async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/genre/tv/list?api_key=${ApiConfig.tmdbApiKey}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['genres']);
    }
    return [];
  }

  Future<List<Movie>> discoverMovies({
    int? year,
    String? genreIds,
    double? minRating,
    String? castIds,
    String? sortBy = 'popularity.desc',
    String? language,
  }) async {
    String url = '${ApiConfig.tmdbBaseUrl}/discover/movie?api_key=${ApiConfig.tmdbApiKey}&sort_by=$sortBy';
    if (year != null) url += '&primary_release_year=$year';
    if (genreIds != null && genreIds.isNotEmpty) url += '&with_genres=$genreIds';
    if (minRating != null) url += '&vote_average.gte=$minRating';
    if (castIds != null && castIds.isNotEmpty) url += '&with_cast=$castIds';
    if (language != null && language != 'all') url += '&with_original_language=$language';

    final response = await _getCached(url);
    return _handleResponse(response);
  }

  Future<List<Movie>> discoverTVShows({
    int? year,
    String? genreIds,
    double? minRating,
    String? sortBy = 'popularity.desc',
    String? language,
  }) async {
    String url = '${ApiConfig.tmdbBaseUrl}/discover/tv?api_key=${ApiConfig.tmdbApiKey}&sort_by=$sortBy';
    if (year != null) url += '&first_air_date_year=$year';
    if (genreIds != null && genreIds.isNotEmpty) url += '&with_genres=$genreIds';
    if (minRating != null) url += '&vote_average.gte=$minRating';
    if (language != null && language != 'all') url += '&with_original_language=$language';

    final response = await _getCached(url);
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> searchActors(String query) async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/search/person?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}');
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
      final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/$id/recommendations?api_key=${ApiConfig.tmdbApiKey}');
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
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=${ApiConfig.tmdbApiKey}&append_to_response=videos,credits,external_ids');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<Map<String, dynamic>> getTVShowDetails(int tvId) async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/tv/$tvId?api_key=${ApiConfig.tmdbApiKey}&append_to_response=videos,credits,external_ids');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  Future<List<Movie>> getActorMovies(int actorId) async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/person/$actorId/combined_credits?api_key=${ApiConfig.tmdbApiKey}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List cast = data['cast'] ?? [];
      return cast.map((m) => Movie.fromJson(m)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/person/$personId?api_key=${ApiConfig.tmdbApiKey}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load person details');
  }

  Future<List<Movie>> getSimilarTVShows(int tvId) async {
    final response = await _getCached('${ApiConfig.tmdbBaseUrl}/tv/$tvId/recommendations?api_key=${ApiConfig.tmdbApiKey}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((m) => Movie.fromJson(m)).toList();
    }
    return [];
  }

  Future<Movie> getRandomMovie() async {
    try {
      final randomPage = (DateTime.now().microsecondsSinceEpoch % 20) + 1;
      final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/popular?api_key=${ApiConfig.tmdbApiKey}&page=$randomPage');
      
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
      final response = await _getCached('${ApiConfig.tmdbBaseUrl}/movie/top_rated?api_key=${ApiConfig.tmdbApiKey}&page=1');
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
