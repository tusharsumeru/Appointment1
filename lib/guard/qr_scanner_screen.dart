import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../action/action.dart';
import 'appointment_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? controller;
  bool isScanning = false;
  String? scannedData;
  bool isLoading = true;
  String? errorMessage;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      print('📷 Initializing camera scanner...');
      
      // Create the scanner controller
      // When we try to start it, iOS will automatically show the permission dialog if needed
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        autoStart: false, // We'll start it manually to handle permission better
      );
      
      if (!mounted) return;
      
      // Try to start the camera - this will trigger the iOS permission dialog
      try {
        await controller?.start();
        
        if (!mounted) return;
        
        // If we get here, permission was granted
        setState(() {
          hasPermission = true;
          isLoading = false;
          isScanning = true;
        });
        
        print('✅ Camera scanner initialized and started successfully');
      } catch (e) {
        // Camera failed to start - likely permission denied
        print('❌ Camera failed to start: $e');
        
        if (!mounted) return;
        
        // Check permission status
        final status = await Permission.camera.status;
        
        if (status.isPermanentlyDenied || status.isDenied) {
          setState(() {
            isLoading = false;
            errorMessage = 'Camera permission is required to scan QR codes. Please enable camera access in Settings.';
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Failed to initialize camera: $e';
          });
        }
      }
    } catch (e) {
      print('❌ Error initializing camera controller: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

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
        actions: controller != null ? [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (controller == null) return;
              try {
                if (isScanning) {
                  await controller!.stop();
                } else {
                  await controller!.start();
                }
                if (mounted) {
                  setState(() {
                    isScanning = !isScanning;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ] : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _initializeScanner();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFF97316)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null) {
      return const Center(
        child: Text('Camera controller not initialized'),
      );
    }

    return Stack(
      children: [
        // QR Scanner View
        MobileScanner(
          controller: controller!,
          onDetect: (BarcodeCapture capture) {
            if (!mounted || scannedData != null || controller == null) return;
            
            try {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    scannedData = barcode.rawValue;
                  });
                  controller!.stop();
                  setState(() {
                    isScanning = false;
                  });
                  
                  // Handle the scanned data directly
                  _handleScannedData(scannedData!);
                  break;
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error scanning: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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
                color: Colors.black.withValues(alpha: 0.7),
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
          if (controller != null)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  if (controller != null) {
                    try {
                      await controller!.toggleTorch();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error toggling torch: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
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
                  color: Colors.green.withValues(alpha: 0.9),
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
    controller?.dispose();
    super.dispose();
  }
} 