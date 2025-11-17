import 'package:flutter/services.dart';
import 'dart:io';

/// Service to detect installed apps on the device
class AppDetectionService {
  static const MethodChannel _channel = MethodChannel('app_detection');

  /// Payment app package names and their display names
  static const Map<String, Map<String, String>> _paymentApps = {
    'com.phonepe.app': {
      'name': 'PhonePe',
      'scheme': 'phonepe://',
      'icon': 'payment',
    },
    'net.one97.paytm': {
      'name': 'Paytm',
      'scheme': 'paytm://',
      'icon': 'payment',
    },
    'com.google.android.apps.nfc.payment': {
      'name': 'Google Pay',
      'scheme': 'gpay://',
      'icon': 'payment',
    },
    'com.tez': {
      'name': 'Google Pay (Tez)',
      'scheme': 'tez://',
      'icon': 'payment',
    },
    'com.razorpay': {
      'name': 'Razorpay',
      'scheme': 'razorpay://',
      'icon': 'payment',
    },
    'com.amazon.pay': {
      'name': 'Amazon Pay',
      'scheme': 'amazonpay://',
      'icon': 'payment',
    },
    'com.mobikwik': {
      'name': 'MobiKwik',
      'scheme': 'mobikwik://',
      'icon': 'payment',
    },
    'com.freecharge.android': {
      'name': 'Freecharge',
      'scheme': 'freecharge://',
      'icon': 'payment',
    },
    'com.bhimupi': {
      'name': 'BHIM UPI',
      'scheme': 'bhim://',
      'icon': 'payment',
    },
    'com.paypal.android.p2pmobile': {
      'name': 'PayPal',
      'scheme': 'paypal://',
      'icon': 'payment',
    },
    'com.venmo': {
      'name': 'Venmo',
      'scheme': 'venmo://',
      'icon': 'payment',
    },
    'com.cashfree.cashfree': {
      'name': 'Cashfree',
      'scheme': 'cashfree://',
      'icon': 'payment',
    },
    'com.airtel.money': {
      'name': 'Airtel Thanks',
      'scheme': 'airtel://',
      'icon': 'payment',
    },
  };

  /// Check if a specific app is installed
  static Future<bool> isAppInstalled(String packageName) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>(
          'isAppInstalled',
          {'packageName': packageName},
        );
        return result ?? false;
      } catch (e) {
        // If method channel fails, assume app might be installed
        // This allows the app to try launching it anyway
        // The launch will fail gracefully if app is not installed
        return true; // Optimistic approach - let url_launcher handle it
      }
    } else if (Platform.isIOS) {
      // For iOS, we can check using URL schemes
      return await _checkIOSAppInstalled(packageName);
    }
    return false;
  }

  /// Alternative method to check if app is installed (Android)
  static Future<bool> _checkAppInstalledAlternative(String packageName) async {
    try {
      // Try to launch the app's URL scheme
      // This is a fallback method
      return false; // Will be implemented with url_launcher
    } catch (e) {
      return false;
    }
  }

  /// Check if app is installed on iOS using URL schemes
  static Future<bool> _checkIOSAppInstalled(String packageName) async {
    // iOS implementation would use canLaunchUrl
    return false;
  }

  /// Get list of installed payment apps
  static Future<List<PaymentApp>> getInstalledPaymentApps() async {
    final List<PaymentApp> installedApps = [];

    for (final entry in _paymentApps.entries) {
      final packageName = entry.key;
      final appInfo = entry.value;
      
      final isInstalled = await isAppInstalled(packageName);
      if (isInstalled) {
        installedApps.add(PaymentApp(
          packageName: packageName,
          name: appInfo['name']!,
          scheme: appInfo['scheme']!,
          icon: appInfo['icon']!,
        ));
      }
    }

    return installedApps;
  }

  /// Get payment apps that can handle a specific payment URL
  static Future<List<PaymentApp>> getCompatiblePaymentApps(String paymentData) async {
    final installedApps = await getInstalledPaymentApps();
    final List<PaymentApp> compatibleApps = [];

    final lowerData = paymentData.toLowerCase();

    // Check if it's a UPI payment code
    final isUPI = lowerData.contains('upi://') || 
                  lowerData.contains('upi') ||
                  (lowerData.contains('@') && RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(paymentData));

    // For UPI codes, return ALL installed payment apps (they can all handle UPI)
    if (isUPI) {
      return installedApps;
    }

    // For specific payment schemes, check compatibility
    for (final app in installedApps) {
      final schemeWithoutProtocol = app.scheme.replaceAll('://', '');
      if (lowerData.contains(schemeWithoutProtocol) || 
          lowerData.startsWith(app.scheme)) {
        compatibleApps.add(app);
      }
    }

    // If no specific match but it's a payment code, return all installed apps
    if (compatibleApps.isEmpty && _isPaymentCode(paymentData)) {
      return installedApps;
    }

    return compatibleApps;
  }

  /// Check if data is a payment code
  static bool _isPaymentCode(String data) {
    final lowerData = data.toLowerCase();
    return lowerData.contains('upi') ||
        lowerData.contains('paytm') ||
        lowerData.contains('phonepe') ||
        lowerData.contains('gpay') ||
        lowerData.contains('paypal') ||
        lowerData.contains('venmo') ||
        lowerData.contains('razorpay') ||
        lowerData.contains('amazonpay') ||
        lowerData.contains('mobikwik') ||
        lowerData.contains('freecharge') ||
        lowerData.contains('bhim') ||
        (lowerData.contains('@') && (lowerData.contains('pay') || lowerData.contains('upi')));
  }
}

/// Represents a payment app
class PaymentApp {
  final String packageName;
  final String name;
  final String scheme;
  final String icon;

  PaymentApp({
    required this.packageName,
    required this.name,
    required this.scheme,
    required this.icon,
  });
}

