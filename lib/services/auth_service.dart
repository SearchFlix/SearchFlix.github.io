import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isTestMode = false;
  Map<String, dynamic>? _user;
  static const String _baseUrl = 'https://searchflix.github.io/server/api'; // Adjust for local vs production

  bool get isLoggedIn => _isLoggedIn || _isTestMode;
  bool get isTestMode => _isTestMode;
  Map<String, dynamic>? get user => _user;

  AuthService() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isTestMode = prefs.getBool('isTestMode') ?? false;
    final userData = prefs.getString('user');
    if (userData != null) {
      _user = json.decode(userData);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        body: json.encode({'email': email, 'password': password}),
      );
      
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _isLoggedIn = true;
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user', json.encode(_user));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  void logout() async {
    _isLoggedIn = false;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user');
    notifyListeners();
  }

  void toggleTestMode() async {
    _isTestMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTestMode', true);
    notifyListeners();
  }

  // Fallback for secret login without credentials
  void forceLogin() {
    _isLoggedIn = true;
    notifyListeners();
  }
}
