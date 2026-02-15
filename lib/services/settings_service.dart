import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _continuousScanKey = 'continuous_scan';
  static const String _beepOnScanKey = 'beep_on_scan';
  static const String _vibrateOnScanKey = 'vibrate_on_scan';
  static const String _autoCopyKey = 'auto_copy';
  static const String _useFrontCameraKey = 'use_front_camera';
  static const String _themeModeKey = 'theme_mode'; // 'light', 'dark', 'system'

  // Default values
  static const bool _defaultContinuousScan = false;
  static const bool _defaultBeepOnScan = true;
  static const bool _defaultVibrateOnScan = true;
  static const bool _defaultAutoCopy = false;
  static const bool _defaultUseFrontCamera = false;
  static const String _defaultThemeMode = 'system';

  // Getters
  Future<bool> getContinuousScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_continuousScanKey) ?? _defaultContinuousScan;
  }

  Future<bool> getBeepOnScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_beepOnScanKey) ?? _defaultBeepOnScan;
  }

  Future<bool> getVibrateOnScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrateOnScanKey) ?? _defaultVibrateOnScan;
  }

  Future<bool> getAutoCopy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCopyKey) ?? _defaultAutoCopy;
  }

  Future<bool> getUseFrontCamera() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFrontCameraKey) ?? _defaultUseFrontCamera;
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? _defaultThemeMode;
  }

  // Setters
  Future<void> setContinuousScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_continuousScanKey, value);
  }

  Future<void> setBeepOnScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_beepOnScanKey, value);
  }

  Future<void> setVibrateOnScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateOnScanKey, value);
  }

  Future<void> setAutoCopy(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCopyKey, value);
  }

  Future<void> setUseFrontCamera(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFrontCameraKey, value);
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value);
  }
}

