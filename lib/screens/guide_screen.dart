import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../utils/theme_provider.dart';
import '../main.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const String _introKey = 'intro_completed';

  static Future<bool> shouldShowIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_introKey) ?? false);
  }

  static Future<void> completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return IntroductionScreen(
      pages: [
        _buildPage(
          title: 'Welcome to Scanner App',
          body: 'Scan QR codes and barcodes instantly with our powerful scanner. Fast, accurate, and easy to use.',
          image: Icons.qr_code_scanner,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
        _buildPage(
          title: 'Scan Anything',
          body: 'Point your camera at any QR code or barcode. Our scanner supports 13+ formats including EAN, UPC, Code-128, and more.',
          image: Icons.camera_alt,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
          showArrow: true,
          arrowDirection: 'down',
        ),
        _buildPage(
          title: 'Generate Codes',
          body: 'Create your own QR codes and barcodes. Share contact info, WiFi passwords, URLs, and more with just a few taps.',
          image: Icons.qr_code_2,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
          showArrow: true,
          arrowDirection: 'right',
        ),
        _buildPage(
          title: 'Smart Actions',
          body: 'Automatically detect code types and get smart actions. Open URLs, call numbers, send emails, connect to WiFi, and more.',
          image: Icons.auto_awesome,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
          showArrow: true,
          arrowDirection: 'up',
        ),
        _buildPage(
          title: 'Ready to Start!',
          body: 'You\'re all set! Start scanning and generating codes. Your scan history is automatically saved for easy access.',
          image: Icons.check_circle,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
      ],
      onDone: () async {
        await GuideScreen.completeIntro();
        if (context.mounted) {
          // Get ThemeProvider from context before navigation
          final themeProvider = ThemeProvider.of(context);
          if (themeProvider != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ThemeProvider(
                  currentTheme: themeProvider.currentTheme,
                  themeMode: themeProvider.themeMode,
                  colorTheme: themeProvider.colorTheme,
                  updateThemeMode: themeProvider.updateThemeMode,
                  updateColorTheme: themeProvider.updateColorTheme,
                  child: const MainScreen(),
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          }
        }
      },
      showSkipButton: true,
      skip: Text(
        'Skip',
        style: TextStyle(
          color: subtitleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: primaryColor,
      ),
      done: Text(
        'Done',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: primaryColor,
        color: subtitleColor,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      globalBackgroundColor: backgroundColor,
    );
  }

  static PageViewModel _buildPage({
    required String title,
    required String body,
    required IconData image,
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
    required Color subtitleColor,
    bool showArrow = false,
    String arrowDirection = 'down',
  }) {
    return PageViewModel(
      title: title,
      body: body,
      image: _buildAnimatedIcon(
        image,
        primaryColor,
        showArrow: showArrow,
        arrowDirection: arrowDirection,
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16,
          color: subtitleColor,
        ),
        imagePadding: const EdgeInsets.only(bottom: 40),
        pageColor: backgroundColor,
      ),
    );
  }

  static Widget _buildAnimatedIcon(
    IconData icon,
    Color color, {
    bool showArrow = false,
    String arrowDirection = 'down',
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 0.5 + (0.5 * value),
              child: Transform.rotate(
                angle: (1 - value) * 0.5,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3 * value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (showArrow)
              Positioned(
                top: arrowDirection == 'down' ? 180 : null,
                bottom: arrowDirection == 'up' ? 180 : null,
                left: arrowDirection == 'right' ? 180 : null,
                right: arrowDirection == 'left' ? 180 : null,
                child: Opacity(
                  opacity: value,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, arrowValue, child) {
                      return Transform.translate(
                        offset: Offset(
                          arrowDirection == 'right'
                              ? 10 * (1 - arrowValue)
                              : arrowDirection == 'left'
                                  ? -10 * (1 - arrowValue)
                                  : 0,
                          arrowDirection == 'down'
                              ? 10 * (1 - arrowValue)
                              : arrowDirection == 'up'
                                  ? -10 * (1 - arrowValue)
                                  : 0,
                        ),
                        child: Icon(
                          arrowDirection == 'down'
                              ? Icons.keyboard_arrow_down
                              : arrowDirection == 'up'
                                  ? Icons.keyboard_arrow_up
                                  : arrowDirection == 'right'
                                      ? Icons.keyboard_arrow_right
                                      : Icons.keyboard_arrow_left,
                          size: 40,
                          color: color,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

