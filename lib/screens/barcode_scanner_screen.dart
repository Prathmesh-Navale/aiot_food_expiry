// lib/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

// This is the model structure that the scanner should return.
typedef OnScanCompleted = void Function(Map<String, dynamic> scannedData);

class BarcodeScannerScreen extends StatefulWidget {
  final OnScanCompleted onScanCompleted;

  const BarcodeScannerScreen({super.key, required this.onScanCompleted});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _permissionGranted = false;
  bool _scanComplete = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
      });
    } else {
      setState(() {
        _permissionGranted = false;
      });
    }
  }

  // --- MOCK DATA GENERATOR (Returns specific Cold Drink Data) ---
  Map<String, dynamic> _getMockProductData(String barcode) {
    // This mocks the backend lookup using the scanned barcode.
    // We use the Cold Drink Cola details for the final entry.

    // Calculate days between today and 2026-06-30
    final targetDate = DateTime.tryParse('2026-06-30') ?? DateTime.now().add(const Duration(days: 250));
    final daysToExpiry = targetDate.difference(DateTime.now()).inDays;

    return {
      'productName': 'Cold Drink Cola (330ml)',
      'initialPrice': 1.99,
      'quantity': 150,
      'storageLocation': 'Shelf A',
      'expiryDays': daysToExpiry,
      'productSku': 'COLA-330-001', // The actual SKU/Barcode
      // Note: salesLast10d is intentionally omitted and will default to 0 in the submission logic.
    };
  }
  // ------------------------------------------------------------------

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_scanComplete) return;

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    // Only process the first barcode detected
    setState(() {
      _scanComplete = true; // Prevents re-scanning
    });

    final scannedData = _getMockProductData(barcode);

    // Close the scanner and pass data back to the inventory screen
    Navigator.pop(context);
    widget.onScanCompleted(scannedData);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Permission')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera access is required to scan codes.'),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings to Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // Actual Scanner UI
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR/Barcode')),
      body: Stack(
        children: [
          // 1. Camera Feed
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) => _onBarcodeDetected(capture),
            fit: BoxFit.cover,
          ),

          // 2. Overlay / Scanner Box (The focus area)
          Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _scanComplete
                  ? Center(
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.green.withOpacity(0.8),
                      child: const Text('Scan Successful!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  )
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 50, color: Colors.white),
                    Text('Center QR/Barcode here', style: TextStyle(color: Colors.white, backgroundColor: Colors.black54.withOpacity(0.5))),
                  ],
                ),
              ),
            ),
          ),

          // 3. Footer/Flashlight Control
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: ValueListenableBuilder(
                      valueListenable: cameraController.torchState,
                      builder: (context, state, child) {
                        if (state == TorchState.off) {
                          return const Icon(Icons.flash_off, color: Colors.grey);
                        }
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                      },
                    ),
                    iconSize: 32.0,
                    onPressed: () => cameraController.toggleTorch(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: ValueListenableBuilder(
                      valueListenable: cameraController.cameraFacingState,
                      builder: (context, state, child) {
                        if (state == CameraFacing.front) {
                          return const Icon(Icons.camera_front);
                        }
                        return const Icon(Icons.camera_rear);
                      },
                    ),
                    iconSize: 32.0,
                    onPressed: () => cameraController.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}