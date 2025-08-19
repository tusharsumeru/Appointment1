import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../action/action.dart';
import 'appointment_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316), // Orange
                Color(0xFFEAB308), // Yellow
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (isScanning) {
                controller.stop();
              } else {
                controller.start();
              }
              setState(() {
                isScanning = !isScanning;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && scannedData == null) {
                  setState(() {
                    scannedData = barcode.rawValue;
                  });
                  controller.stop();
                  setState(() {
                    isScanning = false;
                  });
                  
                  // Handle the scanned data directly
                  _handleScannedData(scannedData!);
                  break;
                }
              }
            },
          ),
          
          // Instructions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Position the QR code within the frame to scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Flashlight Toggle
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                await controller.toggleTorch();
              },
              backgroundColor: const Color(0xFFF97316),
              child: const Icon(Icons.flash_on, color: Colors.white),
            ),
          ),
          
          // Scan Result - Brief Success Message
          if (scannedData != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QR Code detected! Processing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleScannedData(String scannedData) async {
    // Extract appointment ID from the URL
    final appointmentId = ActionService.extractAppointmentIdFromUrl(scannedData);
    
    if (appointmentId == null) {
      // Show brief error message and return to scanner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code. Please scan a valid appointment QR code.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Fetch appointment admission status
    final result = await ActionService.getAppointmentById(appointmentId);

    if (result['success']) {
      // Navigate directly to appointment details screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AppointmentDetailsScreen(
            appointmentId: appointmentId,
          ),
        ),
      );
    } else {
      // Show error message and return to scanner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to verify appointment status.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
} 