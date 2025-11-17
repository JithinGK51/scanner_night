import 'package:barcode/barcode.dart';

/// Service for barcode validation and checksum calculation
class BarcodeValidationService {
  /// Calculate EAN-13 checksum
  static int calculateEAN13Checksum(String digits) {
    if (digits.length != 12) return -1;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(digits[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Calculate EAN-8 checksum
  static int calculateEAN8Checksum(String digits) {
    if (digits.length != 7) return -1;
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(digits[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Calculate UPC-A checksum
  static int calculateUPCChecksum(String digits) {
    if (digits.length != 11) return -1;
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(digits[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Fix checksum for formats that require it
  static String fixChecksum(String input, String format) {
    if (!RegExp(r'^\d+$').hasMatch(input)) return input;

    switch (format) {
      case 'EAN-13':
        if (input.length == 12) {
          int checksum = calculateEAN13Checksum(input);
          return '$input$checksum';
        } else if (input.length == 13) {
          String base = input.substring(0, 12);
          int correctChecksum = calculateEAN13Checksum(base);
          return '$base$correctChecksum';
        }
        break;
      case 'EAN-8':
        if (input.length == 7) {
          int checksum = calculateEAN8Checksum(input);
          return '$input$checksum';
        } else if (input.length == 8) {
          String base = input.substring(0, 7);
          int correctChecksum = calculateEAN8Checksum(base);
          return '$base$correctChecksum';
        }
        break;
      case 'UPC-A':
        if (input.length == 11) {
          int checksum = calculateUPCChecksum(input);
          return '$input$checksum';
        } else if (input.length == 12) {
          String base = input.substring(0, 11);
          int correctChecksum = calculateUPCChecksum(base);
          return '$base$correctChecksum';
        }
        break;
    }
    return input;
  }

  /// Validate input for a specific barcode format
  static bool validateInput(String input, String format) {
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      if (format == 'Code-128' || format == 'Code-39' || format == 'Code-93') {
        return input.isNotEmpty;
      }
      if (format == 'Codabar') {
        return input.isNotEmpty && RegExp(r'^[0-9A-D\-\$:/.+]+$').hasMatch(input);
      }
      return false;
    }

    switch (format) {
      case 'EAN-13':
        return input.length == 12 || input.length == 13;
      case 'EAN-8':
        return input.length == 7 || input.length == 8;
      case 'UPC-A':
        return input.length == 11 || input.length == 12;
      case 'UPC-E':
        return input.length >= 6 && input.length <= 8;
      case 'ITF-14':
        return input.length == 14;
      case 'Code-128':
      case 'Code-39':
      case 'Code-93':
        return input.isNotEmpty;
      case 'Codabar':
        return input.isNotEmpty && RegExp(r'^[0-9A-D\-\$:/.+]+$').hasMatch(input);
      default:
        return input.isNotEmpty;
    }
  }

  /// Get hint text for a barcode format
  static String getHintText(String format) {
    switch (format) {
      case 'EAN-13':
        return '12 or 13 digits (checksum auto-calculated)';
      case 'EAN-8':
        return '7 or 8 digits (checksum auto-calculated)';
      case 'UPC-A':
        return '11 or 12 digits (checksum auto-calculated)';
      case 'UPC-E':
        return '6-8 digits required';
      case 'Code-128':
        return 'Alphanumeric characters';
      case 'Code-39':
        return 'Alphanumeric characters';
      case 'Code-93':
        return 'Alphanumeric characters';
      case 'ITF-14':
        return '14 digits required';
      case 'Codabar':
        return 'Numeric with start/stop';
      default:
        return 'Enter barcode data';
    }
  }

  /// Get Barcode object for a format
  static Barcode getBarcode(String format) {
    switch (format) {
      case 'EAN-13':
        return Barcode.ean13();
      case 'EAN-8':
        return Barcode.ean8();
      case 'UPC-A':
        return Barcode.upcA();
      case 'UPC-E':
        return Barcode.upcE();
      case 'Code-128':
        return Barcode.code128();
      case 'Code-39':
        return Barcode.code39();
      case 'Code-93':
        return Barcode.code93();
      case 'ITF-14':
        return Barcode.itf14();
      case 'Codabar':
        return Barcode.codabar();
      default:
        return Barcode.code128();
    }
  }
}

