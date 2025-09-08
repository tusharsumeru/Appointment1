import 'package:flutter/material.dart';
import '../main/home_screen.dart';
import '../main/inbox_screen.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../guard/guard_screen.dart';
import '../user/user_screen.dart';
import '../user/appointment_type_selection_screen.dart';
import '../user/signup_screen.dart';
import 'notification_setup_screen.dart';
import '../user/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call the login API
        final result = await ActionService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Login successful - save token and user data
          final data = result['data'];
          if (data != null && data['token'] != null) {
            await StorageService.saveToken(data['token']);

            // Save user data if available
            if (data['user'] != null) {
              await StorageService.saveUserData(data['user']);

              // Send login notification
              try {
                final notificationResult =
                    await ActionService.sendLoginNotification(
                      userId: data['user']['_id'] ?? data['user']['id'],
                      loginInfo: {
                        'deviceInfo': 'Flutter Mobile App',
                        'location': 'Mobile Device',
                        'timestamp': DateTime.now().toIso8601String(),
                      },
                    );

                if (notificationResult['success']) {
                } else {
                }
              } catch (e) {
              }
            }

            // Check user role and navigate accordingly
            await _handleRoleBasedNavigation(data['user']);
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Login failed. Please try again.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRoleBasedNavigation(
    Map<String, dynamic>? userData,
  ) async {
    if (userData == null) {
      // If no user data, try to get it from the API
      final userResult = await ActionService.getCurrentUser();
      if (userResult['success']) {
        userData = userResult['data'];
      }
    }

    String? userRole = userData?['role']?.toString().toLowerCase();

    if (mounted) {
      if (userRole == 'secretary' ||
          userRole == 'admin' ||
          userRole == 'super-admin') {
        // Secretary, Admin, and Super-Admin roles - navigate directly to inbox screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const InboxScreen(),
          ),
        );
      } else if (userRole == 'guard') {
        // Guard role - navigate directly to guard screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const GuardScreen(),
          ),
        );
      } else if (userRole == 'user' || userRole == 'client') {
        // Regular user/client role - always show notification setup for now
        // TODO: Check from backend if user has FCM tokens stored
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NotificationSetupScreen(
              isNewUser: false,
              userData: userData ?? {},
            ),
          ),
        );
      } else {
        // Unknown role or no role - show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Access denied. Your role (${userRole ?? 'unknown'}) is not authorized.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        // Logout the user since they don't have proper access
        await StorageService.logout();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48, // 48 for padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // AOL Logo
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          'image/aol-logo.jpg',
                          height: 120,
                          width: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to text if image fails to load
                            return Container(
                              height: 120,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                                                             child: Center(
                                 child: Container(
                                   decoration: const BoxDecoration(
                                     gradient: LinearGradient(
                                       colors: [
                                         Color(0xFFFF6B35), // Orange
                                         Color(0xFFFFD93D), // Yellow
                                       ],
                                       begin: Alignment.centerLeft,
                                       end: Alignment.centerRight,
                                     ),
                                   ),
                                   child: const Text(
                                     'THE ART OF LIVING',
                                     style: TextStyle(
                                       fontSize: 18,
                                       fontWeight: FontWeight.bold,
                                       color: Colors.white,
                                     ),
                                     textAlign: TextAlign.center,
                                   ),
                                 ),
                               ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your account',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Login Form Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                             // Login Button
                             Container(
                               height: 56, // h-14 equivalent
                               decoration: BoxDecoration(
                                 gradient: const LinearGradient(
                                   colors: [Color(0xFFF97316), Color(0xFFEAB308)], // orange-500 to yellow-500
                                   begin: Alignment.centerLeft,
                                   end: Alignment.centerRight,
                                 ),
                                 borderRadius: BorderRadius.circular(12), // rounded-xl equivalent
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.1),
                                     blurRadius: 8,
                                     offset: const Offset(0, 4),
                                   ),
                                 ],
                               ),
                               child: Material(
                                 color: Colors.transparent,
                                 child: InkWell(
                                   onTap: _isLoading ? null : _handleLogin,
                                   borderRadius: BorderRadius.circular(12),
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                     child: Center(
                                       child: _isLoading
                                           ? const SizedBox(
                                               height: 20,
                                               width: 20,
                                               child: CircularProgressIndicator(
                                                 strokeWidth: 2,
                                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                               ),
                                             )
                                           : const Text(
                                               'Login',
                                               style: TextStyle(
                                                 fontSize: 18, // text-lg equivalent
                                                 fontWeight: FontWeight.w600, // font-semibold equivalent
                                                 color: Colors.white,
                                               ),
                                             ),
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                              const SizedBox(height: 12),
                              // Forgot Password Button
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                                                     child: const Text(
                                     'Forgot Your Password?',
                                                                           style: TextStyle(
                                        color: Color(0xFFE65100),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                   ),
                                ),
                              ),
                           ],
                         ),
                       ),
                      const SizedBox(height: 16),

                      // Create Account Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                                                         child: const Text(
                               'Create Account',
                                                               style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100),
                                  decoration: TextDecoration.underline,
                                ),
                             ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
