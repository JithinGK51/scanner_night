import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

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
    return lowerData.contains('upi://') ||
        lowerData.contains('paytm://') ||
        lowerData.contains('phonepe://') ||
        lowerData.contains('gpay://') ||
        lowerData.contains('paypal.me/') ||
        lowerData.contains('venmo.com/') ||
        lowerData.startsWith('upi://') ||
        RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(data) &&
            (lowerData.contains('pay') || lowerData.contains('upi'));
  }

  /// Check if code is a contact card (vCard format)
  static bool _isContactCard(String data) {
    return data.startsWith('BEGIN:VCARD') || data.startsWith('vcard');
  }

  /// Check if code is a location (geo coordinates)
  static bool _isLocation(String data) {
    return data.startsWith('geo:') ||
        data.startsWith('http://maps.google.com') ||
        data.startsWith('https://maps.google.com') ||
        data.startsWith('http://www.google.com/maps') ||
        data.startsWith('https://www.google.com/maps');
  }

  /// Check if code is an event (iCalendar format)
  static bool _isEvent(String data) {
    return data.startsWith('BEGIN:VEVENT') || data.startsWith('vevent');
  }

  /// Get available actions for a code type
  static List<CodeAction> getAvailableActions(String data, String category) {
    final actions = <CodeAction>[];

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
      switch (action.type) {
        case ActionType.open:
          return await _openUrl(data);
        case ActionType.email:
          return await _openEmail(data);
        case ActionType.call:
          return await _makeCall(data);
        case ActionType.message:
          return await _sendMessage(data);
        case ActionType.pay:
          return await _openPayment(data);
        case ActionType.connect:
          return await _connectWiFi(data);
        case ActionType.save:
          // These require platform-specific implementations
          return false;
        case ActionType.share:
          // Share is handled by the UI layer
          return false;
        case ActionType.copy:
          await Clipboard.setData(ClipboardData(text: data));
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _openUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
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

  static Future<bool> _openPayment(String paymentData) async {
    final uri = Uri.parse(paymentData);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
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

  CodeAction({
    required this.type,
    required this.label,
    required this.icon,
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

