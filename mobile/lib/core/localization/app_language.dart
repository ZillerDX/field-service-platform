import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  static final AppLanguage _instance = AppLanguage._internal();
  factory AppLanguage() => _instance;
  AppLanguage._internal();

  String _currentLang = 'th';
  static const String _prefKey = 'app_language_code';

  String get currentLang => _currentLang;
  bool get isThai => _currentLang == 'th';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLang = prefs.getString(_prefKey) ?? 'th';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    if (_currentLang == lang) return;
    _currentLang = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, lang);
    } catch (_) {}
  }

  void toggleLanguage() {
    setLanguage(_currentLang == 'th' ? 'en' : 'th');
  }

  String t(String th, String en) {
    return _currentLang == 'th' ? th : en;
  }
}
