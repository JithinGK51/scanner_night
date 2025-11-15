import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  
  final HistoryService _historyService = HistoryService();
  bool _flashOn = false;
  bool _isFrontCamera = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _lastScannedCode;
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    // Prevent duplicate scans
    if (_lastScannedCode == barcode.rawValue) return;
    _lastScannedCode = barcode.rawValue;

    setState(() {
      _isProcessing = true;
      _isScanning = true;
    });

    // Vibrate on scan
    HapticFeedback.mediumImpact();

    // Trigger success animation
    _animationController?.forward(from: 0.0);

    // Add to history
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: barcode.rawValue!,
      type: 'Scanned',
      category: _detectCategory(barcode.rawValue!),
      timestamp: DateTime.now(),
    );
    await _historyService.addHistoryItem(historyItem);

    // Show result dialog
    if (mounted) {
      _showScanResult(barcode.rawValue!);
    }

    // Reset after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScanning = false;
        });
      }
    });
  }

  String _detectCategory(String data) {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return 'URL';
    } else if (data.startsWith('mailto:')) {
      return 'Email';
    } else if (data.startsWith('tel:')) {
      return 'Phone';
    } else if (data.startsWith('sms:')) {
      return 'SMS';
    } else if (data.startsWith('WIFI:')) {
      return 'WiFi';
    } else {
      return 'Text';
    }
  }

  void _showScanResult(String data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scan Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                data,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final scanningFrameSize = 280.0;
    final scanningFrameTop = screenHeight * 0.2;
    final scanningFrameBottom = scanningFrameTop + scanningFrameSize;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera preview
          SizedBox.expand(
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),
          ),
          // Dark overlay with hole for scanning frame - full screen
          SizedBox.expand(
            child: CustomPaint(
              painter: ScannerOverlayPainter(
                scanningFrameTop: scanningFrameTop,
                scanningFrameSize: scanningFrameSize,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            ),
          ),
          // Scanning frame
          Positioned(
            top: scanningFrameTop,
            left: (screenWidth - scanningFrameSize) / 2,
            child: Container(
              width: scanningFrameSize,
              height: scanningFrameSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanning ? Colors.green : Colors.grey.shade300,
                  width: _isScanning ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Animated scanning dot
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _animationController != null
                          ? AnimatedBuilder(
                              animation: _animationController!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isScanning
                                      ? (_scaleAnimation?.value ?? 1.0)
                                      : (_pulseAnimation?.value ?? 1.0),
                                  child: Container(
                                    width: _isScanning ? 16 : 8,
                                    height: _isScanning ? 16 : 8,
                                    decoration: BoxDecoration(
                                      color: _isScanning ? Colors.green : Colors.blue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isScanning ? Colors.green : Colors.blue)
                                              .withOpacity(0.6),
                                          blurRadius: _isScanning ? 20 : 10,
                                          spreadRadius: _isScanning ? 5 : 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top controls
          Positioned(
            top: scanningFrameTop - 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopControlButton(
                    icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () {
                      setState(() => _flashOn = !_flashOn);
                      _controller.toggleTorch();
                    },
                  ),
                  _buildTopControlButton(
                    icon: Icons.cameraswitch,
                    onTap: () {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      _controller.switchCamera();
                    },
                  ),
                ],
              ),
            ),
          ),
          // White buttons aligned with scanning frame bottom
          Positioned(
            top: scanningFrameBottom - 22,
            left: 20,
            child: _buildBottomButton(
              Icons.edit,
              Colors.white,
              Colors.black,
              () {
                // Manual input functionality
                _showManualInputDialog();
              },
            ),
          ),
          Positioned(
            top: scanningFrameBottom - 22,
            right: 20,
            child: _buildBottomButton(
              Icons.lightbulb_outline,
              Colors.white,
              Colors.black,
              () {
                setState(() => _flashOn = !_flashOn);
                _controller.toggleTorch();
              },
            ),
          ),
          // Bottom controls - positioned at bottom of screen
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildScanButton(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomButton(
                        Icons.image,
                        Colors.black.withOpacity(0.7),
                        Colors.white,
                        () {
                          // Pick image from gallery
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image picker coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Code Manually'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter QR code or barcode data',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _handleManualInput(controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleManualInput(String data) async {
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: data,
      type: 'Scanned',
      category: _detectCategory(data),
      timestamp: DateTime.now(),
    );
    await _historyService.addHistoryItem(historyItem);
    
    if (mounted) {
      _showScanResult(data);
    }
  }

  Widget _buildTopControlButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomButton(
    IconData icon,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay with hole
class ScannerOverlayPainter extends CustomPainter {
  final double scanningFrameTop;
  final double scanningFrameSize;
  final double screenWidth;
  final double screenHeight;

  ScannerOverlayPainter({
    required this.scanningFrameTop,
    required this.scanningFrameSize,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final framePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (screenWidth - scanningFrameSize) / 2,
            scanningFrameTop,
            scanningFrameSize,
            scanningFrameSize,
          ),
          const Radius.circular(20),
        ),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      path,
      framePath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for abstract colorful background
class AbstractBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFF4ECDC4),
      const Color(0xFFFF3838),
    ];

    for (int i = 0; i < 8; i++) {
      paint.color = colors[i % colors.length].withOpacity(0.6);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final startX = (i * 73.7) % size.width;
      final startY = size.height * 0.2 + (i * 47.3) % (size.height * 0.6);

      final path = Path();
      path.moveTo(startX, startY);

      for (int j = 0; j < 3; j++) {
        final angle = (i + j) * 0.8;
        final length = 80 + (j * 40);
        final endX = startX + length * (angle.cos());
        final endY = startY + length * (angle.sin());
        path.lineTo(endX, endY);
      }

      canvas.drawPath(path, paint);
    }

    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      paint.color = colors[i % colors.length].withOpacity(0.2);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      final x = (i * 120.5) % size.width;
      final y = size.height * 0.3 + (i * 80.3) % (size.height * 0.5);

      canvas.drawCircle(Offset(x, y), 30 + (i % 3) * 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on double {
  double cos() => math.cos(this);
  double sin() => math.sin(this);
}
