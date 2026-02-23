import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import 'auth_service.dart';

class WatchlistProvider with ChangeNotifier {
  List<Movie> _items = [];
  AuthService? _authService;
  static const String _baseUrl = 'https://searchflix.github.io/server/api';

  List<Movie> get items => _items;

  void update(AuthService authService) {
    _authService = authService;
    if (_authService?.isLoggedIn == true) {
      _syncWithServer();
    }
  }

  WatchlistProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? watchlistData = prefs.getString('watchlist');
    if (watchlistData != null) {
      final List decoded = json.decode(watchlistData);
      _items = decoded.map((item) => Movie.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _syncWithServer() async {
    if (_authService?.user == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/watchlist.php'),
        body: json.encode({'user_id': _authService!.user!['id'], 'action': 'get'}),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final List results = data['data'];
        final List<Movie> serverItems = results.map((r) => Movie.fromJson(json.decode(r['movie_data']))).toList();
        
        // Exact mirror from server
        _items = serverItems;
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }


  Future<void> toggleWatchlist(Movie movie) async {
    final index = _items.indexWhere((item) => item.id == movie.id);
    String action;
    if (index >= 0) {
      _items.removeAt(index);
      action = 'remove';
    } else {
      _items.add(movie);
      action = 'add';
    }
    _saveToPrefs();
    notifyListeners();

    if (_authService?.user != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/watchlist.php'),
          body: json.encode({
            'user_id': _authService!.user!['id'],
            'action': action,
            'movie_id': movie.id,
            if (action == 'add') 'movie_data': movie.toJson(),
          }),
        );
      } catch (e) {
        print('Sync toggle error: $e');
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watchlist', json.encode(_items.map((i) => i.toJson()).toList()));
  }

  bool isInWatchlist(int movieId) {
    return _items.any((m) => m.id == movieId);
  }

  Future<void> clearWatchlist() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watchlist');
    notifyListeners();

    if (_authService?.user != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/watchlist.php'),
          body: json.encode({
            'user_id': _authService!.user!['id'],
            'action': 'clear',
          }),
        );
      } catch (e) {
        print('Sync clear error: $e');
    }
  }

  Future<void> clearLocalWatchlist() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watchlist');
    notifyListeners();
  }
}


