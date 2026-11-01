import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/food.dart';
import '../services/food_api.dart';

/// Scans a product barcode with the camera and looks it up on Open Food Facts.
/// Returns the found [FoodItem] to the previous screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Looking up $code…';
    });
    try {
      final FoodItem? food = await FoodApi.lookupBarcode(code);
      if (!mounted) return;
      if (food == null) {
        setState(() => _message =
            'Product $code is not in the Open Food Facts database yet. '
            'Try searching for it by name.');
      } else {
        Navigator.pop(context, food);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Could not look up the barcode: $e');
    }
    // Allow another scan after a short pause.
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter barcode'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 5449000000996'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Look up')),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) _lookup(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes
                  .map((b) => b.rawValue)
                  .whereType<String>()
                  .firstOrNull;
              if (code != null) _lookup(code);
            },
          ),
          // Viewfinder frame
          Center(
            child: Container(
              width: 270,
              height: 170,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message ?? 'Point the camera at the barcode on a package',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _manualEntry,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Type the barcode instead'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
