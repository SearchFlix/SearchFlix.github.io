import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistProvider with ChangeNotifier {
  List<Movie> _watchlist = [];

  List<Movie> get watchlist => _watchlist;

  WatchlistProvider() {
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('watchlist');
    if (data != null) {
      final List decoded = json.decode(data);
      _watchlist = decoded.map((m) => Movie.fromJson(m)).toList();
      notifyListeners();
    }
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final index = _watchlist.indexWhere((m) => m.id == movie.id);
    if (index >= 0) {
      _watchlist.removeAt(index);
    } else {
      _watchlist.add(movie);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final List encoded = _watchlist.map((m) => {
      'id': m.id,
      'title': m.title,
      'overview': m.overview,
      'poster_path': m.posterPath,
      'backdrop_path': m.backdropPath,
      'vote_average': m.voteAverage,
      'release_date': m.releaseDate,
    }).toList();
    
    await prefs.setString('watchlist', json.encode(encoded));
    notifyListeners();
  }

  bool isInWatchlist(int movieId) {
    return _watchlist.any((m) => m.id == movieId);
  }

  Future<void> clearWatchlist() async {
    _watchlist.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watchlist');
    notifyListeners();
  }
}
