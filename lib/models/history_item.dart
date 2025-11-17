import 'package:flutter/material.dart';

class HistoryItem {
  final String id;
  final String data;
  final String type; // 'Scanned' or 'Generated'
  final String category; // 'URL', 'Text', 'Email', 'Phone', 'SMS', 'WiFi', 'Barcode'
  final DateTime timestamp;
  final bool isFavorite;
  final String? qrCodeType; // For generated QR codes

  HistoryItem({
    required this.id,
    required this.data,
    required this.type,
    required this.category,
    required this.timestamp,
    this.isFavorite = false,
    this.qrCodeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'type': type,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
      'qrCodeType': qrCodeType,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      data: json['data'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      qrCodeType: json['qrCodeType'] as String?,
    );
  }

  HistoryItem copyWith({
    String? id,
    String? data,
    String? type,
    String? category,
    DateTime? timestamp,
    bool? isFavorite,
    String? qrCodeType,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      data: data ?? this.data,
      type: type ?? this.type,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      qrCodeType: qrCodeType ?? this.qrCodeType,
    );
  }

  String get displayTitle {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      try {
        final uri = Uri.parse(data);
        return uri.host;
      } catch (e) {
        return data.length > 30 ? '${data.substring(0, 30)}...' : data;
      }
    }
    if (data.startsWith('mailto:')) {
      return data.replaceFirst('mailto:', '');
    }
    if (data.startsWith('tel:')) {
      return data.replaceFirst('tel:', '');
    }
    if (data.startsWith('sms:')) {
      return data.replaceFirst('sms:', '');
    }
    return data.length > 30 ? '${data.substring(0, 30)}...' : data;
  }

  String get displayType {
    if (category == 'URL' || data.startsWith('http://') || data.startsWith('https://')) {
      return 'Website Link';
    }
    return category;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (category) {
      case 'URL':
        return Icons.link;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      case 'SMS':
        return Icons.sms;
      case 'WiFi':
        return Icons.wifi;
      case 'Text':
        return Icons.text_fields;
      case 'Barcode':
        return Icons.qr_code_scanner;
      default:
        return Icons.qr_code;
    }
  }

  // Get icon color based on theme
  Color getIconColor(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Use theme primary color for all categories to maintain consistency
    return primaryColor;
  }
}

