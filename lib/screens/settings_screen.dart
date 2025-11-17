import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../services/backup_service.dart';
import '../services/history_service.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)? updateThemeCallback;
  final Function(String)? updateColorThemeCallback;
  final AppTheme currentTheme;
  
  const SettingsScreen({
    super.key,
    this.updateThemeCallback,
    this.updateColorThemeCallback,
    required this.currentTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  final BackupService _backupService = BackupService();
  final HistoryService _historyService = HistoryService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _continuousScan = false;
  bool _beepOnScan = true;
  bool _vibrateOnScan = true;
  bool _autoCopyToClipboard = false;
  bool _useFrontCamera = false;
  String _themeMode = 'system';
  String _colorTheme = 'Teal';
  bool _isLoading = true;
  String _scanProfile = 'fast'; // 'fast' or 'high_accuracy'
  bool _storeWifiPasswords = false;
  bool _requireBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final continuousScan = await _settingsService.getContinuousScan();
    final beepOnScan = await _settingsService.getBeepOnScan();
    final vibrateOnScan = await _settingsService.getVibrateOnScan();
    final autoCopy = await _settingsService.getAutoCopy();
    final useFrontCamera = await _settingsService.getUseFrontCamera();
    final themeMode = await _settingsService.getThemeMode();
    final scanProfile = await _settingsService.getScanProfile();
    final colorTheme = await _themeService.getColorTheme();
    final storeWifiPasswords = await _settingsService.getStoreWifiPasswords();
    final requireBiometric = await _settingsService.getRequireBiometric();

    setState(() {
      _continuousScan = continuousScan;
      _beepOnScan = beepOnScan;
      _vibrateOnScan = vibrateOnScan;
      _autoCopyToClipboard = autoCopy;
      _useFrontCamera = useFrontCamera;
      _themeMode = themeMode;
      _colorTheme = colorTheme;
      _scanProfile = scanProfile;
      _storeWifiPasswords = storeWifiPasswords;
      _requireBiometric = requireBiometric;
      _isLoading = false;
    });
  }

  Future<void> _updateContinuousScan(bool value) async {
    await _settingsService.setContinuousScan(value);
    setState(() {
      _continuousScan = value;
    });
  }

  Future<void> _updateBeepOnScan(bool value) async {
    await _settingsService.setBeepOnScan(value);
    setState(() {
      _beepOnScan = value;
    });
  }

  Future<void> _updateVibrateOnScan(bool value) async {
    await _settingsService.setVibrateOnScan(value);
    setState(() {
      _vibrateOnScan = value;
    });
  }

  Future<void> _updateAutoCopy(bool value) async {
    await _settingsService.setAutoCopy(value);
    setState(() {
      _autoCopyToClipboard = value;
    });
  }

  Future<void> _updateUseFrontCamera(bool value) async {
    await _settingsService.setUseFrontCamera(value);
    setState(() {
      _useFrontCamera = value;
    });
  }

  Future<void> _updateThemeMode(String value) async {
    await _settingsService.setThemeMode(value);
    setState(() {
      _themeMode = value;
    });
    if (widget.updateThemeCallback != null) {
      widget.updateThemeCallback!(value);
    }
  }

  Future<void> _updateColorTheme(String value) async {
    await _themeService.setColorTheme(value);
    setState(() {
      _colorTheme = value;
    });
    if (widget.updateColorThemeCallback != null) {
      widget.updateColorThemeCallback!(value);
    }
  }

  Future<void> _updateStoreWifiPasswords(bool value) async {
    await _settingsService.setStoreWifiPasswords(value);
    setState(() {
      _storeWifiPasswords = value;
    });
  }

  Future<void> _updateRequireBiometric(bool value) async {
    await _settingsService.setRequireBiometric(value);
    setState(() {
      _requireBiometric = value;
    });
  }

  Future<void> _handleClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to remove all scanned and generated items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared successfully')),
        );
      }
    }
  }

  Future<void> _handleBackupRestore() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Export Data'),
              subtitle: const Text('Export all app data'),
              onTap: () => Navigator.pop(context, 'export'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Import Data'),
              subtitle: const Text('Import all app data'),
              onTap: () => Navigator.pop(context, 'import'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == 'export') {
      final success = await _backupService.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Data exported successfully' : 'Failed to export data'),
          ),
        );
      }
    } else if (action == 'import') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text('This will replace all current data with the imported data. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _backupService.importAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Data imported successfully' : 'Failed to import data'),
            ),
          );
          if (success) {
            _loadSettings();
          }
        }
      }
    }
  }

  Future<void> _handleExportImportHistory() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export & Import History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export History'),
              subtitle: const Text('Export scan history'),
              onTap: () => Navigator.pop(context, 'export'),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import History'),
              subtitle: const Text('Import scan history'),
              onTap: () => Navigator.pop(context, 'import'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == 'export') {
      final success = await _backupService.exportHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'History exported successfully' : 'Failed to export history'),
          ),
        );
      }
    } else if (action == 'import') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import History'),
          content: const Text('This will replace all current history with the imported history. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _backupService.importHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'History imported successfully' : 'Failed to import history'),
            ),
          );
        }
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  _updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  _updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) {
                if (value != null) {
                  _updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName() {
    switch (_themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5);
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            _buildSectionHeader(
              'Appearance',
              Icons.palette,
              'Customize app appearance',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildThemeTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _buildColorThemeTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 32),
            // Scan Options Section
            _buildSectionHeader(
              'Scan Options',
              Icons.qr_code,
              'Configure scanning behavior',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Continuous Scan',
              'Keep scanning after successful detection',
              _continuousScan,
              _updateContinuousScan,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildSettingTile(
              'Beep on Scan',
              'Play sound when code is detected',
              _beepOnScan,
              _updateBeepOnScan,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildSettingTile(
              'Vibrate on Scan',
              'Vibrate when code is detected',
              _vibrateOnScan,
              _updateVibrateOnScan,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildSettingTile(
              'Auto Copy to Clipboard',
              'Automatically copy scanned content',
              _autoCopyToClipboard,
              _updateAutoCopy,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildSettingTile(
              'Use Front Camera',
              'Start with front camera instead of back',
              _useFrontCamera,
              _updateUseFrontCamera,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 32),
            // Scan Profiles Section
            _buildSectionHeader(
              'Scan Profiles',
              Icons.equalizer,
              'Configure scanning performance',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            // Fast Mode
            _buildScanProfileTile(
              'Fast Mode',
              'Lower accuracy, faster scanning (recommended for simple codes)',
              _scanProfile == 'fast',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onChanged: (value) {
                if (value) {
                  setState(() {
                    _scanProfile = 'fast';
                  });
                  _settingsService.setFastMode(true);
                }
                // Switches are mutually exclusive - turning one on automatically turns the other off
                // We don't allow turning off - one must always be selected
              },
            ),
            const SizedBox(height: 12),
            // High Accuracy Mode
            _buildScanProfileTile(
              'High Accuracy Mode',
              'Higher accuracy, slower scanning (recommended for complex codes)',
              _scanProfile == 'high_accuracy',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onChanged: (value) {
                if (value) {
                  setState(() {
                    _scanProfile = 'high_accuracy';
                  });
                  _settingsService.setHighAccuracyMode(true);
                }
                // Switches are mutually exclusive - turning one on automatically turns the other off
                // We don't allow turning off - one must always be selected
              },
            ),
            const SizedBox(height: 32),
            // Privacy & Security Section
            _buildSectionHeader(
              'Privacy & Security',
              Icons.security,
              'Manage your data and security',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Store Wi-Fi Passwords',
              'Save Wi-Fi passwords locally (encrypted)',
              _storeWifiPasswords,
              _updateStoreWifiPasswords,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildSettingTile(
              'Require Biometric for Sensitive Data',
              'Use fingerprint/face unlock for sensitive entries',
              _requireBiometric,
              _updateRequireBiometric,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            _buildActionTile(
              'Clear History',
              'Remove all scanned and generated items',
              Icons.delete_outline,
              _handleClearHistory,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Backup & Restore',
              'Export or import your data',
              Icons.cloud_upload_outlined,
              _handleBackupRestore,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Export & Import',
              'Export or import scan history',
              Icons.file_download_outlined,
              _handleExportImportHistory,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 20),
            // Test Ad Banner
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Test Ad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This is a 468x60 test ad.',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.ads_click, color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Nice job!',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    String subtitle, {
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile({
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: _showThemeDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.brightness_6, color: Colors.orange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getThemeDisplayName(),
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildColorThemeTile({
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: _showColorThemeDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.currentTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _colorTheme,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }

  void _showColorThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: ThemeService.availableThemes.length,
            itemBuilder: (context, index) {
              final themeName = ThemeService.availableThemes[index];
              final theme = ThemeService.getTheme(themeName);
              final isSelected = _colorTheme == themeName;

              return GestureDetector(
                onTap: () {
                  _updateColorTheme(themeName);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        themeName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.primaryColor
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    String title, {
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildScanProfileTile(
    String title,
    String description,
    bool isSelected, {
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isSelected,
            onChanged: onChanged,
            activeColor: widget.currentTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}
