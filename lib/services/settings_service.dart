import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _continuousScanKey = 'continuous_scan';
  static const String _beepOnScanKey = 'beep_on_scan';
  static const String _vibrateOnScanKey = 'vibrate_on_scan';
  static const String _autoCopyKey = 'auto_copy';
  static const String _useFrontCameraKey = 'use_front_camera';
  static const String _themeModeKey = 'theme_mode'; // 'light', 'dark', 'system'
  static const String _scanProfileKey = 'scan_profile'; // 'fast' or 'high_accuracy'
  static const String _storeWifiPasswordsKey = 'store_wifi_passwords';
  static const String _requireBiometricKey = 'require_biometric';

  // Default values
  static const bool _defaultContinuousScan = false;
  static const bool _defaultBeepOnScan = true;
  static const bool _defaultVibrateOnScan = true;
  static const bool _defaultAutoCopy = false;
  static const bool _defaultUseFrontCamera = false;
  static const String _defaultThemeMode = 'system';
  static const String _defaultScanProfile = 'fast'; // Default to fast mode
  static const bool _defaultStoreWifiPasswords = false;
  static const bool _defaultRequireBiometric = false;

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

  Future<String> getScanProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scanProfileKey) ?? _defaultScanProfile;
  }

  Future<bool> isFastMode() async {
    final profile = await getScanProfile();
    return profile == 'fast';
  }

  Future<bool> isHighAccuracyMode() async {
    final profile = await getScanProfile();
    return profile == 'high_accuracy';
  }

  Future<bool> getStoreWifiPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_storeWifiPasswordsKey) ?? _defaultStoreWifiPasswords;
  }

  Future<bool> getRequireBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_requireBiometricKey) ?? _defaultRequireBiometric;
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

  Future<void> setScanProfile(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanProfileKey, value);
  }

  Future<void> setFastMode(bool enabled) async {
    if (enabled) {
      await setScanProfile('fast');
    }
  }

  Future<void> setHighAccuracyMode(bool enabled) async {
    if (enabled) {
      await setScanProfile('high_accuracy');
    }
  }

  Future<void> setStoreWifiPasswords(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storeWifiPasswordsKey, value);
  }

  Future<void> setRequireBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requireBiometricKey, value);
  }
}

