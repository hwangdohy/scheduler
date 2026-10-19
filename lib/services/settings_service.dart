import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize { small, medium, large }

extension AppFontSizeScale on AppFontSize {
  double get scale {
    switch (this) {
      case AppFontSize.small:
        return 0.9;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.15;
    }
  }

  String get label {
    switch (this) {
      case AppFontSize.small:
        return '작게';
      case AppFontSize.medium:
        return '보통';
      case AppFontSize.large:
        return '크게';
    }
  }
}

/// Persists user-configurable app settings. Notifies listeners so the
/// root widget can rebuild the theme / notification schedule live.
class SettingsService extends ChangeNotifier {
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kNotificationHour = 'notification_hour';
  static const _kNotificationMinute = 'notification_minute';
  static const _kFontSize = 'font_size';
  static const _kGeminiApiKey = 'gemini_api_key';

  bool notificationsEnabled = true;
  // Default reminder time: 9:00 PM, when the day is winding down.
  TimeOfDay notificationTime = const TimeOfDay(hour: 21, minute: 0);
  AppFontSize fontSize = AppFontSize.medium;
  String geminiApiKey = '';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
    notificationTime = TimeOfDay(
      hour: prefs.getInt(_kNotificationHour) ?? 21,
      minute: prefs.getInt(_kNotificationMinute) ?? 0,
    );
    fontSize = AppFontSize.values[prefs.getInt(_kFontSize) ?? 1];
    geminiApiKey = prefs.getString(_kGeminiApiKey) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    notificationTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotificationHour, time.hour);
    await prefs.setInt(_kNotificationMinute, time.minute);
    notifyListeners();
  }

  Future<void> setFontSize(AppFontSize size) async {
    fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFontSize, size.index);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiApiKey, key);
    notifyListeners();
  }
}
