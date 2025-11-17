import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import 'history_service.dart';
import 'settings_service.dart';
import 'theme_service.dart';

class BackupService {
  final HistoryService _historyService = HistoryService();
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();

  /// Export all app data (history + settings)
  Future<bool> exportAllData() async {
    try {
      final history = await _historyService.getHistory();
      final settings = await _getAllSettings();
      final theme = await _themeService.getColorTheme();

      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'history': history.map((item) => item.toJson()).toList(),
        'settings': settings,
        'theme': theme,
      };

      final jsonString = json.encode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${directory.path}/scanner_backup_$timestamp.json');

      await file.writeAsString(jsonString);

      // Share the file
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Scanner App Backup');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Export only scan history
  Future<bool> exportHistory() async {
    try {
      final history = await _historyService.getHistory();

      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'history_only',
        'history': history.map((item) => item.toJson()).toList(),
      };

      final jsonString = json.encode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${directory.path}/scanner_history_$timestamp.json');

      await file.writeAsString(jsonString);

      // Share the file
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Scanner History Export');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import all app data
  Future<bool> importAllData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Import history
      if (backupData.containsKey('history')) {
        final historyList = backupData['history'] as List<dynamic>;
        final history = historyList
            .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // Clear existing history and add imported items
        await _historyService.clearHistory();
        for (final item in history) {
          await _historyService.addHistoryItem(item);
        }
      }

      // Import settings
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        await _restoreSettings(settings);
      }

      // Import theme
      if (backupData.containsKey('theme')) {
        final theme = backupData['theme'] as String;
        await _themeService.setColorTheme(theme);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import only scan history
  Future<bool> importHistory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      if (!backupData.containsKey('history')) {
        return false;
      }

      final historyList = backupData['history'] as List<dynamic>;
      final history = historyList
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // Clear existing history and add imported items
      await _historyService.clearHistory();
      for (final item in history) {
        await _historyService.addHistoryItem(item);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all settings as a map
  Future<Map<String, dynamic>> _getAllSettings() async {
    return {
      'continuousScan': await _settingsService.getContinuousScan(),
      'beepOnScan': await _settingsService.getBeepOnScan(),
      'vibrateOnScan': await _settingsService.getVibrateOnScan(),
      'autoCopy': await _settingsService.getAutoCopy(),
      'useFrontCamera': await _settingsService.getUseFrontCamera(),
      'themeMode': await _settingsService.getThemeMode(),
      'scanProfile': await _settingsService.getScanProfile(),
      'storeWifiPasswords': await _settingsService.getStoreWifiPasswords(),
      'requireBiometric': await _settingsService.getRequireBiometric(),
    };
  }

  /// Restore settings from a map
  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('continuousScan')) {
      await _settingsService.setContinuousScan(settings['continuousScan'] as bool);
    }
    if (settings.containsKey('beepOnScan')) {
      await _settingsService.setBeepOnScan(settings['beepOnScan'] as bool);
    }
    if (settings.containsKey('vibrateOnScan')) {
      await _settingsService.setVibrateOnScan(settings['vibrateOnScan'] as bool);
    }
    if (settings.containsKey('autoCopy')) {
      await _settingsService.setAutoCopy(settings['autoCopy'] as bool);
    }
    if (settings.containsKey('useFrontCamera')) {
      await _settingsService.setUseFrontCamera(settings['useFrontCamera'] as bool);
    }
    if (settings.containsKey('themeMode')) {
      await _settingsService.setThemeMode(settings['themeMode'] as String);
    }
    if (settings.containsKey('scanProfile')) {
      await _settingsService.setScanProfile(settings['scanProfile'] as String);
    }
    if (settings.containsKey('storeWifiPasswords')) {
      await _settingsService.setStoreWifiPasswords(settings['storeWifiPasswords'] as bool);
    }
    if (settings.containsKey('requireBiometric')) {
      await _settingsService.setRequireBiometric(settings['requireBiometric'] as bool);
    }
  }
}

