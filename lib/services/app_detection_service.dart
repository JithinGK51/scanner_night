import 'package:flutter/services.dart';
import 'dart:io';

/// Service to detect installed apps on the device
class AppDetectionService {
  static const MethodChannel _channel = MethodChannel('app_detection');

  /// Payment app package names and their display names
  static const Map<String, Map<String, String>> _paymentApps = {
    // Indian Payment Apps
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
    'com.bhimupi': {
      'name': 'BHIM UPI',
      'scheme': 'bhim://',
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
    'com.airtel.money': {
      'name': 'Airtel Thanks',
      'scheme': 'airtel://',
      'icon': 'payment',
    },
    'com.cashfree.cashfree': {
      'name': 'Cashfree',
      'scheme': 'cashfree://',
      'icon': 'payment',
    },
    'com.axis.mobile': {
      'name': 'Axis Pay',
      'scheme': 'axis://',
      'icon': 'payment',
    },
    'com.hdfc.bank': {
      'name': 'HDFC PayZapp',
      'scheme': 'hdfc://',
      'icon': 'payment',
    },
    'com.icici.bank': {
      'name': 'iMobile Pay',
      'scheme': 'icici://',
      'icon': 'payment',
    },
    'com.sbi.sbiplus': {
      'name': 'SBI Pay',
      'scheme': 'sbi://',
      'icon': 'payment',
    },
    'com.kotak.mobilebanking': {
      'name': 'Kotak Pay',
      'scheme': 'kotak://',
      'icon': 'payment',
    },
    // International Payment Apps
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
    'com.squareup.cash': {
      'name': 'Cash App',
      'scheme': 'squarecash://',
      'icon': 'payment',
    },
    'com.zellepay.zelle': {
      'name': 'Zelle',
      'scheme': 'zelle://',
      'icon': 'payment',
    },
    'com.stripe.stripe': {
      'name': 'Stripe',
      'scheme': 'stripe://',
      'icon': 'payment',
    },
    'com.alipay.android.phone.mobilecommon.alipayclient': {
      'name': 'Alipay',
      'scheme': 'alipay://',
      'icon': 'payment',
    },
    'com.tencent.mm': {
      'name': 'WeChat Pay',
      'scheme': 'weixin://',
      'icon': 'payment',
    },
    'com.samsung.android.spay': {
      'name': 'Samsung Pay',
      'scheme': 'samsungpay://',
      'icon': 'payment',
    },
    'com.apple.passbook': {
      'name': 'Apple Pay',
      'scheme': 'applepay://',
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

    // Check if it's a UPI payment code (most common in India)
    final isUPI = lowerData.contains('upi://') || 
                  lowerData.contains('upi?') ||
                  lowerData.contains('upi&') ||
                  lowerData.contains('upi=') ||
                  (lowerData.contains('@') && 
                   (lowerData.contains('@paytm') || 
                    lowerData.contains('@phonepe') ||
                    lowerData.contains('@ybl') || 
                    lowerData.contains('@axl') ||
                    lowerData.contains('@okicici') || 
                    lowerData.contains('@okaxis') ||
                    lowerData.contains('@okhdfcbank') ||
                    lowerData.contains('@okaxis') ||
                    lowerData.contains('@okkotak') ||
                    lowerData.contains('@oksbi') ||
                    RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(paymentData)));

    // For UPI codes, return ALL installed payment apps (they can all handle UPI)
    if (isUPI) {
      return installedApps;
    }

    // Check for PayPal
    if (lowerData.contains('paypal.me/') || 
        lowerData.contains('paypal.com/') ||
        lowerData.startsWith('paypal://')) {
      for (final app in installedApps) {
        if (app.packageName.contains('paypal')) {
          compatibleApps.add(app);
        }
      }
      if (compatibleApps.isNotEmpty) return compatibleApps;
    }

    // Check for Venmo
    if (lowerData.contains('venmo.com/') || 
        lowerData.startsWith('venmo://')) {
      for (final app in installedApps) {
        if (app.packageName.contains('venmo')) {
          compatibleApps.add(app);
        }
      }
      if (compatibleApps.isNotEmpty) return compatibleApps;
    }

    // For specific payment schemes, check compatibility
    for (final app in installedApps) {
      final schemeWithoutProtocol = app.scheme.replaceAll('://', '');
      if (lowerData.contains(schemeWithoutProtocol) || 
          lowerData.startsWith(app.scheme) ||
          lowerData.contains('$schemeWithoutProtocol://')) {
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
    
    // UPI patterns
    final isUPI = lowerData.contains('upi') ||
        lowerData.contains('paytm') ||
        lowerData.contains('phonepe') ||
        lowerData.contains('gpay') ||
        lowerData.contains('bhim') ||
        lowerData.contains('@paytm') ||
        lowerData.contains('@phonepe') ||
        lowerData.contains('@ybl') ||
        lowerData.contains('@axl') ||
        lowerData.contains('@okicici') ||
        lowerData.contains('@okaxis') ||
        lowerData.contains('@okhdfcbank') ||
        lowerData.contains('@okkotak') ||
        lowerData.contains('@oksbi');
    
    // International payment patterns
    final isInternational = lowerData.contains('paypal') ||
        lowerData.contains('venmo') ||
        lowerData.contains('cashapp') ||
        lowerData.contains('zelle') ||
        lowerData.contains('stripe') ||
        lowerData.contains('alipay') ||
        lowerData.contains('wechat') ||
        lowerData.contains('weixin') ||
        lowerData.contains('samsungpay') ||
        lowerData.contains('applepay');
    
    // Other payment patterns
    final isOther = lowerData.contains('razorpay') ||
        lowerData.contains('amazonpay') ||
        lowerData.contains('mobikwik') ||
        lowerData.contains('freecharge') ||
        lowerData.contains('cashfree') ||
        lowerData.contains('axis') ||
        lowerData.contains('hdfc') ||
        lowerData.contains('icici') ||
        lowerData.contains('sbi') ||
        lowerData.contains('kotak');
    
    // Email-like patterns that might be UPI
    final isEmailLike = lowerData.contains('@') && 
        (lowerData.contains('pay') || 
         lowerData.contains('upi') ||
         RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(data));
    
    return isUPI || isInternational || isOther || isEmailLike;
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

