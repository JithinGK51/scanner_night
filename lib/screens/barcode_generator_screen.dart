import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/barcode_validation_service.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  String _selectedFormat = 'EAN-13';
  final TextEditingController _barcodeController = TextEditingController();
  String? _generatedData;
  final GlobalKey _barcodeKey = GlobalKey();
  bool _isGenerating = false;
  final HistoryService _historyService = HistoryService();

  final List<Map<String, String>> _barcodeFormats = [
    {'name': 'EAN-13', 'hint': '12 or 13 digits (checksum auto-calculated)'},
    {'name': 'EAN-8', 'hint': '7 or 8 digits (checksum auto-calculated)'},
    {'name': 'UPC-A', 'hint': '11 or 12 digits (checksum auto-calculated)'},
    {'name': 'UPC-E', 'hint': '6-8 digits required'},
    {'name': 'Code-128', 'hint': 'Alphanumeric characters'},
    {'name': 'Code-39', 'hint': 'Alphanumeric characters'},
    {'name': 'Code-93', 'hint': 'Alphanumeric characters'},
    {'name': 'ITF-14', 'hint': '14 digits required'},
    {'name': 'Codabar', 'hint': 'Numeric with start/stop'},
  ];

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  String _getHintText() {
    return BarcodeValidationService.getHintText(_selectedFormat);
  }

  Barcode _getBarcode() {
    return BarcodeValidationService.getBarcode(_selectedFormat);
  }

  void _generateBarcode() async {
    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter data to generate barcode'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    String input = _barcodeController.text.trim();
    
    if (!BarcodeValidationService.validateInput(input, _selectedFormat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid input for $_selectedFormat. ${_getHintText()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Auto-fix checksum for formats that require it
    String processedData = BarcodeValidationService.fixChecksum(input, _selectedFormat);
    
    // Update controller if checksum was fixed
    if (processedData != input && RegExp(r'^\d+$').hasMatch(processedData)) {
      _barcodeController.text = processedData;
      input = processedData;
    }

    setState(() {
      _isGenerating = true;
    });

    // Set the data and let the widget handle validation
    setState(() {
      _generatedData = input;
      _isGenerating = false;
    });

    // Add to history
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: _generatedData!,
      type: 'Generated',
      category: 'Barcode',
      timestamp: DateTime.now(),
      qrCodeType: _selectedFormat,
    );
    await _historyService.addHistoryItem(historyItem);
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

  Future<void> _saveBarcode() async {
    if (_generatedData == null) return;

    try {
      final RenderRepaintBoundary boundary =
          _barcodeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'barcode_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] == true
                ? 'Barcode saved to gallery'
                : 'Failed to save barcode'),
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
            content: Text('Error saving barcode: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareBarcode() async {
    if (_generatedData == null) return;

    try {
      final RenderRepaintBoundary boundary =
          _barcodeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Barcode: $_generatedData',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing barcode: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showFormatDialog() {
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
            children: _barcodeFormats.map((format) {
              return ListTile(
                leading: Icon(
                  Icons.qr_code_scanner,
                  color: _selectedFormat == format['name'] ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                title: Text(
                  format['name']!,
                  style: TextStyle(
                    fontWeight: _selectedFormat == format['name']
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedFormat == format['name'] ? Theme.of(context).colorScheme.primary : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  format['hint']!,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _selectedFormat = format['name']!;
                    _barcodeController.clear();
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
          'Barcode Generator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_generatedData != null)
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: () {
                setState(() {
                  _generatedData = null;
                  _barcodeController.clear();
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
            // Barcode Format Selection
            GestureDetector(
              onTap: _showFormatDialog,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 3,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 20,
                            height: 3,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 20,
                            height: 3,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barcode Format',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedFormat,
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
            // Barcode Data Input Field
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
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: 'Barcode Data',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                keyboardType: _selectedFormat.contains('EAN') || 
                             _selectedFormat.contains('UPC') || 
                             _selectedFormat.contains('ITF')
                    ? TextInputType.number
                    : TextInputType.text,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                _getHintText(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Generate Barcode Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateBarcode,
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
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.qr_code_2, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Generate Barcode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            // Generated Barcode Display
            if (_generatedData != null) ...[
              const SizedBox(height: 30),
              Builder(
                builder: (context) {
                  try {
                    return Container(
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
                            key: _barcodeKey,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: BarcodeWidget(
                                barcode: _getBarcode(),
                                data: _generatedData!,
                                width: 250,
                                height: 120,
                                color: Colors.black,
                                backgroundColor: Colors.white,
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
                                onTap: _saveBarcode,
                                color: const Color(0xFF4CAF50),
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Share',
                                onTap: _shareBarcode,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    // Handle barcode encoding errors
                    String errorMessage = e.toString();
                    String displayMessage = 'Invalid barcode data';
                    
                    if (errorMessage.contains('checksum')) {
                      final checksumMatch = RegExp(r"should be '(\d)'").firstMatch(errorMessage);
                      if (checksumMatch != null && _generatedData != null && _generatedData!.length == 13) {
                        String corrected = _generatedData!.substring(0, 12) + checksumMatch.group(1)!;
                        _barcodeController.text = corrected;
                        displayMessage = 'Checksum error. Corrected value: $corrected';
                      } else {
                        displayMessage = 'Invalid checksum. ${_getHintText()}';
                      }
                    } else if (errorMessage.contains('Unable to encode')) {
                      displayMessage = errorMessage.split('Unable to encode')[1].split(',')[0].trim();
                    }
                    
                    // Show error after a delay to avoid build errors
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(displayMessage),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                        setState(() {
                          _generatedData = null;
                        });
                      }
                    });
                    
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            displayMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                },
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
