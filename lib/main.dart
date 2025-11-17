import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'screens/scanner_screen.dart';
import 'screens/qr_generator_screen.dart';
import 'screens/barcode_generator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/guide_screen.dart';
import 'services/settings_service.dart';
import 'services/theme_service.dart';
import 'utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: ThemeProvider(
        currentTheme: _currentTheme,
        themeMode: _themeMode,
        colorTheme: _colorTheme,
        updateThemeMode: updateTheme,
        updateColorTheme: updateColorTheme,
        child: const SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> _buildScreens(BuildContext context) {
    // Don't use const so screens can rebuild when theme changes
    return [
      ScannerScreen(),
      QRGeneratorScreen(),
      HistoryScreen(),
      BarcodeGeneratorScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    // Use theme as key to force rebuild when theme changes
    final themeKey = themeProvider != null 
        ? '${themeProvider.colorTheme}_${themeProvider.themeMode}'
        : 'default';
    
    final screens = _buildScreens(context);
    return Scaffold(
      body: IndexedStack(
        key: ValueKey(themeKey),
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, screens),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, List<Widget> screens) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider?.currentTheme.primaryColor ?? Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
    
    try {
      return ConvexAppBar(
        style: TabStyle.reactCircle,
        items: const [
          TabItem(icon: Icons.qr_code_scanner, title: 'Scan'),
          TabItem(icon: Icons.qr_code_2, title: 'QR'),
          TabItem(icon: Icons.history, title: 'History'),
          TabItem(icon: Icons.barcode_reader, title: 'Barcode'),
          TabItem(icon: Icons.settings, title: 'Settings'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          if (mounted && index >= 0 && index < screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        backgroundColor: backgroundColor,
        color: isDark ? Colors.grey.shade600 : Colors.grey,
        activeColor: primaryColor,
        curveSize: 80,
        height: 65,
        top: -25,
        elevation: 4,
      );
    } catch (e) {
      debugPrint('ConvexAppBar error: $e');
      // Fallback to simple bottom navigation if ConvexAppBar fails
      return BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (mounted && index >= 0 && index < screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: 'QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.barcode_reader),
            label: 'Barcode',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      );
    }
  }
}
