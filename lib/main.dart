import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/scanner_screen.dart';
import 'screens/qr_generator_screen.dart';
import 'screens/barcode_generator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  String _themeMode = 'system';
  String _colorTheme = 'Teal';
  AppTheme _currentTheme = ThemeService.defaultTheme;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final themeMode = await _settingsService.getThemeMode();
    final colorTheme = await _themeService.getColorTheme();
    setState(() {
      _themeMode = themeMode;
      _colorTheme = colorTheme;
      _currentTheme = _themeService.getCurrentTheme(colorTheme);
    });
  }

  void updateTheme(String themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void updateColorTheme(String colorTheme) {
    setState(() {
      _colorTheme = colorTheme;
      _currentTheme = _themeService.getCurrentTheme(colorTheme);
    });
  }

  ThemeMode get _themeModeEnum {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: _currentTheme.colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _currentTheme.backgroundColor,
        brightness: Brightness.light,
        cardColor: _currentTheme.cardColor,
        primaryColor: _currentTheme.primaryColor,
      ),
      darkTheme: ThemeData(
        colorScheme: _currentTheme.darkColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        cardColor: Colors.grey.shade800,
        primaryColor: _currentTheme.primaryColor,
      ),
      themeMode: _themeModeEnum,
      home: MainScreen(
        updateThemeCallback: updateTheme,
        updateColorThemeCallback: updateColorTheme,
        currentTheme: _currentTheme,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(String)? updateThemeCallback;
  final Function(String)? updateColorThemeCallback;
  final AppTheme currentTheme;
  
  const MainScreen({
    super.key,
    this.updateThemeCallback,
    this.updateColorThemeCallback,
    required this.currentTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const ScannerScreen(),
    const QRGeneratorScreen(),
    const HistoryScreen(),
    const BarcodeGeneratorScreen(),
    SettingsScreen(
      updateThemeCallback: widget.updateThemeCallback,
      updateColorThemeCallback: widget.updateColorThemeCallback,
      currentTheme: widget.currentTheme,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.qr_code_scanner, 'QR', 0),
              _buildNavItem(Icons.qr_code_2, 'QR', 1),
              _buildNavItem(Icons.history, 'History', 2),
              _buildNavItem(Icons.barcode_reader, 'Barcode', 3),
              _buildNavItem(Icons.settings, 'Settings', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    final bool isSpecial = index == 0 || index == 1 || index == 2 || index == 3; // Scan, QR, History, Barcode
    final bool isSettings = index == 4;
    
    // Use theme colors
    final Color highlightColor = widget.currentTheme.primaryColor;

    if (isSpecial && isSelected) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: highlightColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isSettings && isSelected) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: highlightColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? highlightColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? highlightColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
