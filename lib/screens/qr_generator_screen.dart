import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  String _selectedType = 'URL';
  final TextEditingController _inputController = TextEditingController();
  String? _generatedData;
  final GlobalKey _qrKey = GlobalKey();
  bool _isGenerating = false;
  final HistoryService _historyService = HistoryService();

  final List<String> _qrTypes = [
    'URL',
    'Phone',
    'SMS',
    'Email',
    'Contact',
    'WiFi',
    'Location',
    'Text',
    'Event',
    'Payment',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _getHintText() {
    switch (_selectedType) {
      case 'URL':
        return 'Enter URL (e.g., https://example.com)';
      case 'Text':
        return 'Enter text';
      case 'Email':
        return 'Enter email address';
      case 'Phone':
        return 'Enter phone number';
      case 'SMS':
        return 'Enter phone number';
      case 'WiFi':
        return 'Enter WiFi SSID (Network Name)';
      case 'Contact':
        return 'Enter contact name';
      case 'Location':
        return 'Enter location (latitude,longitude)';
      case 'Event':
        return 'Enter event title';
      case 'Payment':
        return 'Enter payment UPI ID or link';
      default:
        return 'Enter data';
    }
  }

  bool _validateInput(String input) {
    switch (_selectedType) {
      case 'Email':
        if (!input.contains('@') || !input.contains('.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid email address'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return false;
        }
        break;
      case 'Phone':
      case 'SMS':
        if (input.length < 7) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid phone number'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return false;
        }
        break;
      case 'Location':
        // Check if it's in lat,lon format
        final coords = input.split(',');
        if (coords.length == 2) {
          try {
            final lat = double.parse(coords[0].trim());
            final lon = double.parse(coords[1].trim());
            if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Invalid coordinates. Use format: latitude,longitude'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              return false;
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid coordinates. Use format: latitude,longitude'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return false;
          }
        } else if (!input.contains('maps.google.com') && !input.contains('google.com/maps')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enter coordinates as: latitude,longitude (e.g., 40.7128,-74.0060)'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return false;
        }
        break;
      case 'Payment':
        // Validate payment format
        if (!input.contains('@') && 
            !input.startsWith('upi://') && 
            !input.startsWith('paytm://') &&
            !input.startsWith('phonepe://') &&
            !input.startsWith('gpay://') &&
            !input.contains('paypal.me/')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enter a valid UPI ID (e.g., name@paytm) or payment link'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return false;
        }
        break;
    }
    return true;
  }

  String _formatQRData(String input) {
    switch (_selectedType) {
      case 'URL':
        if (!input.startsWith('http://') && !input.startsWith('https://')) {
          return 'https://$input';
        }
        return input;
      case 'Email':
        return 'mailto:$input';
      case 'Phone':
        return 'tel:$input';
      case 'SMS':
        return 'sms:$input';
      case 'WiFi':
        // WiFi format: WIFI:T:WPA;S:SSID;P:Password;;
        // For simplicity, using input as SSID with empty password
        // In production, you might want separate fields for SSID and password
        return 'WIFI:T:WPA;S:$input;P:;;';
      case 'Contact':
        // vCard format - basic implementation
        // Format: BEGIN:VCARD\nVERSION:3.0\nFN:Name\nEND:VCARD
        return 'BEGIN:VCARD\nVERSION:3.0\nFN:$input\nEND:VCARD';
      case 'Location':
        // geo: URI format - expects latitude,longitude
        // Format: geo:latitude,longitude
        final coords = input.split(',');
        if (coords.length == 2) {
          final lat = coords[0].trim();
          final lon = coords[1].trim();
          return 'geo:$lat,$lon';
        } else {
          // If not in lat,lon format, try to parse as Google Maps URL or return as-is
          if (input.contains('maps.google.com') || input.contains('google.com/maps')) {
            return input;
          }
          return 'geo:$input';
        }
      case 'Event':
        // iCalendar format - basic implementation
        // Format: BEGIN:VEVENT\nSUMMARY:Event Title\nDTSTART:YYYYMMDDTHHMMSS\nDTEND:YYYYMMDDTHHMMSS\nEND:VEVENT
        final now = DateTime.now();
        final start = now.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0];
        final end = now.add(const Duration(hours: 1)).toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0];
        return 'BEGIN:VEVENT\nSUMMARY:$input\nDTSTART:$start\nDTEND:$end\nEND:VEVENT';
      case 'Payment':
        // Payment QR format - supports UPI, PayPal, etc.
        // If it's already a payment URL, use it as-is
        if (input.startsWith('upi://') || 
            input.startsWith('paytm://') || 
            input.startsWith('phonepe://') ||
            input.startsWith('gpay://') ||
            input.contains('paypal.me/') ||
            input.contains('@')) {
          // If it's a UPI ID (contains @), format it as UPI payment
          if (input.contains('@') && !input.startsWith('upi://')) {
            return 'upi://pay?pa=$input&pn=Payment&am=&cu=INR';
          }
          return input;
        }
        // Otherwise, treat as payment link
        return input;
      default:
        return input;
    }
  }

  void _generateQRCode() async {
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter data to generate QR code'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate input based on type
    final input = _inputController.text.trim();
    if (!_validateInput(input)) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedData = _formatQRData(input);
    });

    // Add to history
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: _generatedData!,
      type: 'Generated',
      category: _selectedType,
      timestamp: DateTime.now(),
      qrCodeType: _selectedType,
    );
    await _historyService.addHistoryItem(historyItem);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    });
  }

  Future<void> _copyToClipboard() async {
    if (_generatedData == null) return;
    
    await Clipboard.setData(ClipboardData(text: _generatedData!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveQRCode() async {
    if (_generatedData == null) return;

    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] == true
                ? 'QR code saved to gallery'
                : 'Failed to save QR code'),
            backgroundColor:
                result['isSuccess'] == true ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving QR code: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    if (_generatedData == null) return;

    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code: $_generatedData',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showQRTypeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _qrTypes.map((type) {
              return ListTile(
                leading: Icon(
                  _getTypeIcon(type),
                  color: _selectedType == type ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                title: Text(
                  type,
                  style: TextStyle(
                    fontWeight: _selectedType == type
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedType == type ? Theme.of(context).colorScheme.primary : Colors.black87,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedType = type;
                    _inputController.clear();
                    _generatedData = null;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'URL':
        return Icons.link;
      case 'Text':
        return Icons.text_fields;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      case 'SMS':
        return Icons.sms;
      case 'WiFi':
        return Icons.wifi;
      case 'Contact':
        return Icons.person;
      case 'Location':
        return Icons.location_on;
      case 'Event':
        return Icons.event;
      case 'Payment':
        return Icons.payment;
      default:
        return Icons.qr_code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'QR Generator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          // 3-dot menu for QR types
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            tooltip: 'QR Code Types',
            onSelected: (String type) {
              setState(() {
                _selectedType = type;
                _inputController.clear();
                _generatedData = null;
              });
            },
            itemBuilder: (BuildContext context) {
              return _qrTypes.map((String type) {
                return PopupMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        color: _selectedType == type
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type,
                        style: TextStyle(
                          fontWeight: _selectedType == type
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedType == type
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                        ),
                      ),
                      if (_selectedType == type)
                        const Spacer(),
                      if (_selectedType == type)
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          if (_generatedData != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _generatedData = null;
                  _inputController.clear();
                });
              },
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Type Selection
            GestureDetector(
              onTap: _showQRTypeDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 8,
                              child: CustomPaint(
                                size: const Size(8, 8),
                                painter: TrianglePainter(),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Code Type',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black87),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black87, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: _getHintText(),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                keyboardType: _selectedType == 'Email' || _selectedType == 'Payment'
                    ? TextInputType.emailAddress
                    : _selectedType == 'Phone' || _selectedType == 'SMS'
                        ? TextInputType.phone
                        : _selectedType == 'Location'
                            ? TextInputType.number
                            : TextInputType.text,
              ),
            ),
            const SizedBox(height: 30),
            // Generate QR Code Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Generate QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            // Generated QR Code Display
            if (_generatedData != null) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _generatedData!,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy,
                          label: 'Copy',
                          onTap: _copyToClipboard,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _buildActionButton(
                          icon: Icons.save_alt,
                          label: 'Save',
                          onTap: _saveQRCode,
                          color: const Color(0xFF4CAF50),
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: _shareQRCode,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for triangle shape
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
