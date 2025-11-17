import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'app_detection_service.dart';

/// Service for detecting code types and providing smart actions
class CodeActionService {
  /// Detect the type/category of a scanned code
  static String detectCategory(String data) {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return 'URL';
    } else if (data.startsWith('mailto:')) {
      return 'Email';
    } else if (data.startsWith('tel:')) {
      return 'Phone';
    } else if (data.startsWith('sms:')) {
      return 'SMS';
    } else if (data.startsWith('WIFI:') || data.startsWith('wifi:')) {
      return 'WiFi';
    } else if (_isPaymentCode(data)) {
      return 'Payment';
    } else if (_isContactCard(data)) {
      return 'Contact';
    } else if (_isLocation(data)) {
      return 'Location';
    } else if (_isEvent(data)) {
      return 'Event';
    } else {
      return 'Text';
    }
  }

  /// Check if code is a payment code (UPI, PayPal, etc.)
  static bool _isPaymentCode(String data) {
    final lowerData = data.toLowerCase();
    
    // Check for UPI codes (most common in India)
    final isUPI = lowerData.contains('upi://') ||
        lowerData.contains('upi') ||
        (RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(data) &&
         (lowerData.contains('pay') || lowerData.contains('upi') || 
          lowerData.contains('@paytm') || lowerData.contains('@phonepe') ||
          lowerData.contains('@ybl') || lowerData.contains('@axl') ||
          lowerData.contains('@okicici') || lowerData.contains('@okaxis')));
    
    // Check for other payment schemes
    final isOtherPayment = lowerData.contains('paytm://') ||
        lowerData.contains('phonepe://') ||
        lowerData.contains('gpay://') ||
        lowerData.contains('paypal.me/') ||
        lowerData.contains('venmo.com/') ||
        lowerData.contains('razorpay://') ||
        lowerData.contains('amazonpay://') ||
        lowerData.contains('mobikwik://') ||
        lowerData.contains('freecharge://') ||
        lowerData.contains('bhim://');
    
    return isUPI || isOtherPayment;
  }

  /// Check if code is a contact card (vCard format)
  static bool _isContactCard(String data) {
    return data.startsWith('BEGIN:VCARD') || data.startsWith('vcard');
  }

  /// Check if code is a location (geo coordinates)
  static bool _isLocation(String data) {
    return data.startsWith('geo:') ||
        data.contains('maps.google.com') ||
        data.contains('google.com/maps') ||
        (data.contains(',') && RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(data));
  }

  /// Check if code is an event (iCalendar format)
  static bool _isEvent(String data) {
    return data.startsWith('BEGIN:VEVENT') || data.startsWith('vevent');
  }

  /// Get available actions for a code type
  static Future<List<CodeAction>> getAvailableActions(String data, String category) async {
    return await getActions(category, data);
  }

  /// Get actions for a specific category
  static Future<List<CodeAction>> getActions(String category, String data) async {
    final List<CodeAction> actions = [];

    switch (category) {
      case 'URL':
        actions.add(CodeAction(
          type: ActionType.open,
          label: 'Open Link',
          icon: 'open_in_browser',
        ));
        actions.add(CodeAction(
          type: ActionType.share,
          label: 'Share Link',
          icon: 'share',
        ));
        break;

      case 'Email':
        actions.add(CodeAction(
          type: ActionType.email,
          label: 'Send Email',
          icon: 'email',
        ));
        break;

      case 'Phone':
        actions.add(CodeAction(
          type: ActionType.call,
          label: 'Call',
          icon: 'call',
        ));
        actions.add(CodeAction(
          type: ActionType.message,
          label: 'Message',
          icon: 'message',
        ));
        break;

      case 'SMS':
        actions.add(CodeAction(
          type: ActionType.message,
          label: 'Send SMS',
          icon: 'sms',
        ));
        break;

      case 'Payment':
        // Show single "Pay" button - will show payment apps dialog on click
        actions.add(CodeAction(
          type: ActionType.pay,
          label: 'Pay',
          icon: 'payment',
        ));
        actions.add(CodeAction(
          type: ActionType.share,
          label: 'Share',
          icon: 'share',
        ));
        break;

      case 'WiFi':
        actions.add(CodeAction(
          type: ActionType.connect,
          label: 'Connect',
          icon: 'wifi',
        ));
        break;

      case 'Contact':
        actions.add(CodeAction(
          type: ActionType.save,
          label: 'Save Contact',
          icon: 'person_add',
        ));
        break;

      case 'Location':
        actions.add(CodeAction(
          type: ActionType.open,
          label: 'Open in Maps',
          icon: 'map',
        ));
        break;

      case 'Event':
        actions.add(CodeAction(
          type: ActionType.save,
          label: 'Add to Calendar',
          icon: 'event',
        ));
        break;
    }

    // Always add copy action
    actions.add(CodeAction(
      type: ActionType.copy,
      label: 'Copy',
      icon: 'content_copy',
    ));

    return actions;
  }

  /// Execute an action
  static Future<bool> executeAction(CodeAction action, String data) async {
    try {
      bool result = false;
      switch (action.type) {
        case ActionType.open:
          // Check if it's a location that needs special handling
          if (data.startsWith('geo:') || 
              (data.contains(',') && RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(data))) {
            result = await _openLocation(data);
          } else {
            result = await _openUrl(data);
          }
          break;
        case ActionType.email:
          result = await _openEmail(data);
          break;
        case ActionType.call:
          result = await _makeCall(data);
          break;
        case ActionType.message:
          result = await _sendMessage(data);
          break;
        case ActionType.pay:
          result = await _openPayment(data, action.packageName, action.scheme);
          break;
        case ActionType.connect:
          result = await _connectWiFi(data);
          break;
        case ActionType.save:
          // These require platform-specific implementations
          // For now, just return false (can be implemented later)
          result = false;
          break;
        case ActionType.share:
          // Share is handled by the UI layer
          result = false;
          break;
        case ActionType.copy:
          await Clipboard.setData(ClipboardData(text: data));
          result = true;
          break;
      }
      return result;
    } catch (e) {
      // Log error for debugging (in production, you might want to use a logging service)
      debugPrint('Error executing action ${action.type}: $e');
      return false;
    }
  }

  static Future<bool> _openLocation(String location) async {
    try {
      String url;
      
      if (location.startsWith('geo:')) {
        // Convert geo: URI to Google Maps URL
        final geoData = location.replaceFirst('geo:', '');
        final coords = geoData.split(',');
        if (coords.length >= 2) {
          final lat = coords[0].trim();
          final lon = coords[1].trim();
          url = 'https://www.google.com/maps?q=$lat,$lon';
        } else {
          return false;
        }
      } else if (location.contains(',')) {
        // Assume it's lat,lon format
        final coords = location.split(',');
        if (coords.length >= 2) {
          final lat = coords[0].trim();
          final lon = coords[1].trim();
          url = 'https://www.google.com/maps?q=$lat,$lon';
        } else {
          return false;
        }
      } else if (location.contains('maps.google.com') || location.contains('google.com/maps')) {
        url = location;
      } else {
        return false;
      }
      
      return await _openUrl(url);
    } catch (e) {
      debugPrint('Error opening location: $e');
      return false;
    }
  }

  static Future<bool> _openUrl(String url) async {
    try {
      // Clean and prepare URL
      String cleanUrl = url.trim();
      
      // Remove any whitespace or newlines
      cleanUrl = cleanUrl.replaceAll(RegExp(r'\s+'), '');
      
      // Remove common prefixes that might cause issues
      if (cleanUrl.startsWith('www.')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      // Add protocol if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        // Check if it looks like a domain
        if (cleanUrl.contains('.') && !cleanUrl.contains(' ')) {
          cleanUrl = 'https://$cleanUrl';
        } else {
          // Not a valid URL format
          return false;
        }
      }
      
      // Parse URI
      Uri uri;
      try {
        uri = Uri.parse(cleanUrl);
      } catch (e) {
        // Try encoding the URL if parsing fails
        try {
          final encodedUrl = Uri.encodeFull(cleanUrl);
          uri = Uri.parse(encodedUrl);
        } catch (e2) {
          debugPrint('Failed to parse URL: $cleanUrl');
          return false;
        }
      }
      
      // Validate URI
      if (uri.scheme.isEmpty || (!uri.hasScheme && !uri.hasAuthority)) {
        debugPrint('Invalid URI scheme or authority: $uri');
        return false;
      }
      
      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        debugPrint('Cannot launch URL: $uri');
        // Try with platformDefault as fallback
        try {
          return await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          debugPrint('Failed to launch URL with platformDefault: $e');
          return false;
        }
      }
      
      // Try to launch URL with external application mode
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return launched;
      } catch (e) {
        debugPrint('Failed to launch URL with externalApplication: $e');
        // Fallback: try with platformDefault mode
        try {
          return await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          debugPrint('Failed to launch URL with platformDefault: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error in _openUrl: $e');
      return false;
    }
  }

  static Future<bool> _openEmail(String email) async {
    String emailAddress = email;
    if (email.startsWith('mailto:')) {
      emailAddress = email.substring(7);
    }
    final uri = Uri.parse('mailto:$emailAddress');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<bool> _makeCall(String phone) async {
    String phoneNumber = phone;
    if (phone.startsWith('tel:')) {
      phoneNumber = phone.substring(4);
    }
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<bool> _sendMessage(String sms) async {
    String phoneNumber = sms;
    if (sms.startsWith('sms:')) {
      phoneNumber = sms.substring(4).split(':').first;
    }
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<bool> _openPayment(String paymentData, String? packageName, String? scheme) async {
    try {
      String paymentUrl = paymentData;
      
      // If we have a specific app package and scheme, try to use it
      if (packageName != null && scheme != null && scheme.isNotEmpty) {
        // For UPI codes, try to construct app-specific URL
        if (paymentData.contains('@') || paymentData.contains('upi://') || paymentData.contains('upi')) {
          // UPI ID format (e.g., merchant@paytm)
          if (paymentData.contains('@') && !paymentData.startsWith('upi://')) {
            // Try app-specific UPI scheme
            paymentUrl = 'upi://pay?pa=$paymentData&pn=Merchant&mc=0000';
          } else if (paymentData.startsWith('upi://')) {
            // Already in UPI format, use as is
            paymentUrl = paymentData;
          } else {
            // Try with app scheme
            paymentUrl = '$scheme$paymentData';
          }
        } else {
          // For other payment schemes, use the app's scheme
          paymentUrl = '$scheme$paymentData';
        }
      }
      
      // Try to launch the payment URL
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
      
      // Fallback: try original payment data as UPI
      if (paymentData.contains('@') || paymentData.contains('upi')) {
        final upiUri = Uri.parse('upi://pay?pa=$paymentData&pn=Merchant&mc=0000');
        if (await canLaunchUrl(upiUri)) {
          return await launchUrl(upiUri, mode: LaunchMode.externalApplication);
        }
      }
      
      // Last fallback: try original payment data
      final fallbackUri = Uri.parse(paymentData);
      if (await canLaunchUrl(fallbackUri)) {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error opening payment app: $e');
      return false;
    }
  }

  static Future<bool> _connectWiFi(String wifiData) async {
    // WiFi connection requires platform-specific implementation
    // For now, just return false
    return false;
  }

  /// Get display title for a code
  static String getDisplayTitle(String data, String category) {
    switch (category) {
      case 'URL':
        try {
          final uri = Uri.parse(data);
          return uri.host.isNotEmpty ? uri.host : data;
        } catch (e) {
          return data.length > 30 ? '${data.substring(0, 30)}...' : data;
        }
      case 'Email':
        return data.replaceFirst(RegExp(r'^mailto:'), '');
      case 'Phone':
        return data.replaceFirst(RegExp(r'^tel:'), '');
      case 'SMS':
        return data.replaceFirst(RegExp(r'^sms:'), '').split(':').first;
      case 'Payment':
        if (data.contains('@')) {
          return data.split('@').first;
        }
        return 'Payment Code';
      default:
        return data.length > 30 ? '${data.substring(0, 30)}...' : data;
    }
  }
}

/// Represents an action that can be performed on a code
class CodeAction {
  final ActionType type;
  final String label;
  final String icon;
  final String? packageName;
  final String? scheme;

  CodeAction({
    required this.type,
    required this.label,
    required this.icon,
    this.packageName,
    this.scheme,
  });
}

/// Types of actions available
enum ActionType {
  open,
  email,
  call,
  message,
  pay,
  connect,
  save,
  share,
  copy,
}

