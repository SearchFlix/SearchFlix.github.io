import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isTestMode = false;

  bool get isLoggedIn => _isLoggedIn || _isTestMode;
  bool get isTestMode => _isTestMode;

  AuthService() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isTestMode = prefs.getBool('isTestMode') ?? false;
    notifyListeners();
  }

  Future<void> login() async {
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isTestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isTestMode', false);
    notifyListeners();
  }

  Future<void> toggleTestMode() async {
    _isTestMode = !_isTestMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTestMode', _isTestMode);
    notifyListeners();
  }
}
