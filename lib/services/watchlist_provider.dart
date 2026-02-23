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
        
        // Merge with local items (prioritize server)
        for (var item in serverItems) {
          if (!_items.any((i) => i.id == item.id)) {
            _items.add(item);
          }
        }
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final index = _items.indexWhere((item) => item.id == movie.id);
    if (index >= 0) {
      _items.removeAt(index);
      if (_authService?.isLoggedIn == true && _authService?.user != null) {
        _callApi('remove', movie);
      }
    } else {
      _items.add(movie);
      if (_authService?.isLoggedIn == true && _authService?.user != null) {
        _callApi('add', movie);
      }
    }
    _saveToPrefs();
    notifyListeners();
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
  }
}
