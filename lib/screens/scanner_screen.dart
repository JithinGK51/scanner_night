import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../services/code_action_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final HistoryService _historyService = HistoryService();
  final SettingsService _settingsService = SettingsService();
  MobileScannerController? _controller;
  
  bool _flashOn = false;
  bool _isFrontCamera = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _lastScannedCode;
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _scaleAnimation;
  
  bool _continuousScan = false;
  bool _beepOnScan = true;
  bool _vibrateOnScan = true;
  bool _autoCopy = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useFrontCamera = await _settingsService.getUseFrontCamera();
    final continuousScan = await _settingsService.getContinuousScan();
    final beepOnScan = await _settingsService.getBeepOnScan();
    final vibrateOnScan = await _settingsService.getVibrateOnScan();
    final autoCopy = await _settingsService.getAutoCopy();
    final scanProfile = await _settingsService.getScanProfile();

    // Set detection speed based on scan profile
    // Fast mode: noDuplicates (faster, less accurate)
    // High accuracy mode: normal (slower, more accurate)
    final detectionSpeed = scanProfile == 'fast' 
        ? DetectionSpeed.noDuplicates 
        : DetectionSpeed.normal;

    _controller = MobileScannerController(
      detectionSpeed: detectionSpeed,
      facing: useFrontCamera ? CameraFacing.front : CameraFacing.back,
      autoStart: true,
    );

    setState(() {
      _isFrontCamera = useFrontCamera;
      _continuousScan = continuousScan;
      _beepOnScan = beepOnScan;
      _vibrateOnScan = vibrateOnScan;
      _autoCopy = autoCopy;
    });
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
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    // Prevent duplicate scans if not continuous (only block if same code within 2 seconds)
    if (!_continuousScan) {
      if (_lastScannedCode == barcode.rawValue && _isProcessing) {
        return; // Still processing the same code
      }
    }
    
    // Mark as processing to prevent duplicate handling
    if (_isProcessing && !_continuousScan) {
      return;
    }
    
    _lastScannedCode = barcode.rawValue;

    setState(() {
      _isProcessing = true;
      _isScanning = true;
    });

    // Vibrate on scan (if enabled)
    if (_vibrateOnScan) {
      HapticFeedback.mediumImpact();
    }

    // Beep on scan (if enabled) - using system sound
    if (_beepOnScan) {
      SystemSound.play(SystemSoundType.alert);
    }

    // Auto copy to clipboard (if enabled)
    if (_autoCopy) {
      await Clipboard.setData(ClipboardData(text: barcode.rawValue!));
    }

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

    // Reset after delay (only if not continuous scan)
    // Allow auto-detection to work by resetting processing state faster
    if (!_continuousScan) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isScanning = false;
            _lastScannedCode = null; // Allow rescanning after delay
          });
        }
      });
    } else {
      // For continuous scan, reset immediately
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isScanning = false;
          });
        }
      });
    }
  }

  String _detectCategory(String data) {
    return CodeActionService.detectCategory(data);
  }

  void _showScanResult(String data) {
    final category = CodeActionService.detectCategory(data);
    final actions = CodeActionService.getAvailableActions(data, category);
    final displayTitle = CodeActionService.getDisplayTitle(data, category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Successful!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category != 'Text')
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayTitle != data)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SelectableText(
                    data,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Smart action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((action) {
                return _buildActionButton(action, data);
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(CodeAction action, String data) {
    IconData iconData;
    Color? buttonColor;

    switch (action.type) {
      case ActionType.open:
        iconData = Icons.open_in_browser;
        buttonColor = Colors.blue;
        break;
      case ActionType.email:
        iconData = Icons.email;
        buttonColor = Colors.red;
        break;
      case ActionType.call:
        iconData = Icons.call;
        buttonColor = Colors.green;
        break;
      case ActionType.message:
        iconData = Icons.message;
        buttonColor = Colors.orange;
        break;
      case ActionType.pay:
        iconData = Icons.payment;
        buttonColor = Colors.purple;
        break;
      case ActionType.connect:
        iconData = Icons.wifi;
        buttonColor = Colors.indigo;
        break;
      case ActionType.save:
        iconData = Icons.save;
        buttonColor = Colors.teal;
        break;
      case ActionType.share:
        iconData = Icons.share;
        buttonColor = Colors.blueGrey;
        break;
      case ActionType.copy:
        iconData = Icons.copy;
        buttonColor = Theme.of(context).colorScheme.primary;
        break;
    }

    return ElevatedButton.icon(
      onPressed: () async {
        if (action.type == ActionType.share) {
          // Share functionality
          Navigator.pop(context);
          // Share will be handled by the UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Share functionality coming soon'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          // Show loading indicator
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final success = await CodeActionService.executeAction(action, data);
          
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);
          }
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${action.label} executed successfully'
                      : 'Failed to ${action.label.toLowerCase()}. Please check if the app is installed or try again.',
                ),
                backgroundColor: success
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      icon: Icon(iconData, size: 18),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  _controller != null
                      ? SizedBox.expand(
                          child: MobileScanner(
                            controller: _controller!,
                            onDetect: _handleBarcode,
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
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
                  color: _isScanning ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
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
                                      color: _isScanning ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isScanning ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary)
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
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
                      _controller?.toggleTorch();
                    },
                  ),
                          _buildTopControlButton(
                            icon: Icons.cameraswitch,
                            onTap: () async {
                              setState(() => _isFrontCamera = !_isFrontCamera);
                              _controller?.switchCamera();
                              await _settingsService.setUseFrontCamera(_isFrontCamera);
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
                _controller?.toggleTorch();
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
                          _pickImageFromGallery();
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

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Use mobile_scanner to scan the image
      if (_controller != null) {
        try {
          final file = File(image.path);
          final result = await _controller!.analyzeImage(file.path);
          
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);
          }
          
          if (result != null && result.barcodes.isNotEmpty) {
            final barcode = result.barcodes.first;
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              await _processScannedCode(barcode.rawValue!);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No code found in image'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No code found in image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          // Close loading dialog if still open
          if (mounted) {
            Navigator.pop(context);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error scanning image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processScannedCode(String data) async {
    // Add to history
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: data,
      type: 'Scanned',
      category: _detectCategory(data),
      timestamp: DateTime.now(),
    );
    await _historyService.addHistoryItem(historyItem);

    // Show result dialog
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
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
