import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyFullBinAlerts = 'full_bin_alerts';
  static const String _keyDailySummary = 'daily_summary';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyAlertThreshold = 'alert_threshold';
  static const String _keyThemeMode = 'theme_mode';

  bool _notificationsEnabled = true;
  bool _fullBinAlerts = true;
  bool _dailySummary = false;
  bool _soundEnabled = true;
  int _alertThreshold = 80;
  ThemeMode _themeMode = ThemeMode.light;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get fullBinAlerts => _fullBinAlerts;
  bool get dailySummary => _dailySummary;
  bool get soundEnabled => _soundEnabled;
  int get alertThreshold => _alertThreshold;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled = _prefs?.getBool(_keyNotificationsEnabled) ?? true;
    _fullBinAlerts = _prefs?.getBool(_keyFullBinAlerts) ?? true;
    _dailySummary = _prefs?.getBool(_keyDailySummary) ?? false;
    _soundEnabled = _prefs?.getBool(_keySoundEnabled) ?? true;
    _alertThreshold = _prefs?.getInt(_keyAlertThreshold) ?? 80;
    
    final themeModeString = _prefs?.getString(_keyThemeMode) ?? 'light';
    _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setFullBinAlerts(bool value) async {
    _fullBinAlerts = value;
    await _prefs?.setBool(_keyFullBinAlerts, value);
    notifyListeners();
  }

  Future<void> setDailySummary(bool value) async {
    _dailySummary = value;
    await _prefs?.setBool(_keyDailySummary, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool(_keySoundEnabled, value);
    notifyListeners();
  }

  Future<void> setAlertThreshold(int value) async {
    _alertThreshold = value.clamp(0, 100);
    await _prefs?.setInt(_keyAlertThreshold, _alertThreshold);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final themeModeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs?.setString(_keyThemeMode, themeModeString);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final themeModeString = mode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs?.setString(_keyThemeMode, themeModeString);
    notifyListeners();
  }

  bool shouldAlert(int fillLevel) {
    return _notificationsEnabled && 
           _fullBinAlerts && 
           fillLevel >= _alertThreshold;
  }

  Future<void> resetToDefaults() async {
    await _prefs?.clear();
    _notificationsEnabled = true;
    _fullBinAlerts = true;
    _dailySummary = false;
    _soundEnabled = true;
    _alertThreshold = 80;
    _themeMode = ThemeMode.light;
    notifyListeners();
  }
}
