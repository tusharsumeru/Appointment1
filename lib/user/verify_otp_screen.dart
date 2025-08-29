import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../auth/notification_setup_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResendLoading = false;
  int _resendTimer = 0;
  Timer? _timer;
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 600; // 10 minutes in seconds
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Update the complete OTP string
    _enteredOtp = _otpControllers.map((controller) => controller.text).join();

    // Auto-verify when all 6 digits are entered
    if (_enteredOtp.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the OTP verification API
      final result = await ActionService.verifyOtp(
        email: widget.email,
        otp: _enteredOtp,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          // OTP verification successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    '🎉 Excellent! Your account is now verified. Welcome to the Art of Living community!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Send signup notification after successful verification
          try {
            final userData = await StorageService.getUserData() ?? {};
            if (userData['_id'] != null || userData['id'] != null) {
              final notificationResult =
                  await ActionService.sendSignupNotification(
                    userId: userData['_id'] ?? userData['id'],
                    signupInfo: {
                      'source': 'mobile_app',
                      'timestamp': DateTime.now().toIso8601String(),
                      'verificationMethod': 'email_otp',
                    },
                  );

              if (notificationResult['success']) {
                print('✅ Signup notification sent successfully');
              } else {
                print(
                  '⚠️ Failed to send signup notification: ${notificationResult['message']}',
                );
              }
            }
          } catch (e) {
            print('❌ Error sending signup notification: $e');
          }

          // Navigate to FCM setup screen after successful verification
          // Get user data from storage or use default
          final userData = await StorageService.getUserData() ?? {};
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  NotificationSetupScreen(isNewUser: true, userData: userData),
            ),
          );
        } else {
          // OTP verification failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invalid OTP code'),
              backgroundColor: Colors.red,
            ),
          );

          // Clear the OTP fields for retry
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _enteredOtp = '';
          _focusNodes[0].requestFocus();
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResendLoading = true;
    });

    try {
      // Call the resend OTP API
      final result = await ActionService.resendOtp(email: widget.email);

      setState(() {
        _isResendLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    '📧 New verification code sent! Please check your inbox for the latest code.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Restart the timer
          _startResendTimer();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to resend OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _isResendLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getMaskedEmail() {
    final email = widget.email;
    if (email.length <= 7) return email;

    final atIndex = email.indexOf('@');
    if (atIndex <= 3) return email;

    final prefix = email.substring(0, 3);
    final suffix = email.substring(atIndex);
    return '$prefix*******$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAFAFA), // zinc-50
              Colors.white,
              Color(0xFFF4F4F5), // zinc-100
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 64),

                  // Header Section
                  Column(
                    children: [
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF374151), // gray-700
                            Color(0xFF1F2937), // gray-800
                            Color(0xFF111827), // gray-900
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Decorative line with dot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 1,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.grey.shade600.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF374151), // gray-700
                                  Color(0xFF1F2937), // gray-800
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 1,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.grey.shade600.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // OTP Form Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          // Email info
                          Column(
                            children: [
                              const Text(
                                'Please enter the 6-digit code sent to',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF52525B), // zinc-600
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getMaskedEmail(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF27272A), // zinc-800
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The code will expire in ${_formatTime(_resendTimer)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF71717A), // zinc-500
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // OTP Input Fields
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate responsive dimensions
                              final screenWidth = constraints.maxWidth;
                              final isSmallScreen = screenWidth < 350;
                              final isMediumScreen = screenWidth < 400;
                              
                              // Responsive sizing
                              final fieldWidth = isSmallScreen ? 40.0 : (isMediumScreen ? 44.0 : 48.0);
                              final fieldHeight = isSmallScreen ? 44.0 : (isMediumScreen ? 46.0 : 48.0);
                              final fontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
                              final horizontalMargin = isSmallScreen ? 1.0 : (isMediumScreen ? 1.5 : 2.0);
                              final contentPadding = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
                              
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                                    width: fieldWidth,
                                    child: SizedBox(
                                      height: fieldHeight,
                                      child: TextFormField(
                                        controller: _otpControllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(1),
                                        ],
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(
                                            0xFFFAFAFA,
                                          ).withOpacity(0.5), // zinc-50/50
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.all(contentPadding),
                                        ),
                                        onChanged: (value) =>
                                            _onOtpChanged(value, index),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ).copyWith(
                                    backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                  ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [
                                            Colors.grey.shade400,
                                            Colors.grey.shade500,
                                          ]
                                        : const [
                                            Color(0xFFF97316), // orange-500
                                            Color(0xFFEAB308), // yellow-500
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Verify Email',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                                                     // Resend link
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               const Text(
                                 "Didn't receive the code? ",
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Color(0xFF52525B), // zinc-600
                                 ),
                               ),
                               GestureDetector(
                                 onTap: _resendTimer > 0 || _isResendLoading
                                     ? null
                                     : _resendOtp,
                                 child: _isResendLoading
                                     ? const SizedBox(
                                         width: 12,
                                         height: 12,
                                         child: CircularProgressIndicator(
                                           strokeWidth: 2,
                                           valueColor:
                                               AlwaysStoppedAnimation<Color>(
                                                 Color(
                                                   0xFFEA580C,
                                                 ), // orange-600
                                               ),
                                         ),
                                       )
                                     : Text(
                                         _resendTimer > 0
                                             ? 'Resend in ${_formatTime(_resendTimer)}'
                                             : 'Resend',
                                         style: TextStyle(
                                           fontSize: 12,
                                           fontWeight: FontWeight.w500,
                                           color: _resendTimer > 0
                                               ? Colors.grey.shade400
                                               : const Color(
                                                   0xFFEA580C,
                                                 ), // orange-600
                                         ),
                                       ),
                               ),
                             ],
                           ),
                        ],
                                             ),
                     ),
                   ),
                   
                   // Back to Login link (outside the card)
                   const SizedBox(height: 32),
                   GestureDetector(
                     onTap: () => Navigator.of(context).pop(),
                     child: Container(
                       padding: const EdgeInsets.symmetric(
                         horizontal: 24,
                         vertical: 12,
                       ),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.8),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.grey.shade200),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.grey.shade200.withOpacity(0.3),
                             blurRadius: 8,
                             offset: const Offset(0, 2),
                           ),
                         ],
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             Icons.arrow_back,
                             size: 18,
                             color: Colors.grey.shade600,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             'Back to Login',
                             style: TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.w500,
                               color: Colors.grey.shade700,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );
   }
 }
