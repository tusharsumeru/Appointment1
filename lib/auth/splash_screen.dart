import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';
import '../main/home_screen.dart';
import '../main/inbox_screen.dart';
import '../action/storage_service.dart';
import '../action/action.dart';
import '../action/jwt_utils.dart';
import '../guard/guard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();

    // Check authentication status and navigate accordingly
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      try {
        // Check if user is logged in
        final isLoggedIn = await StorageService.isLoggedIn();
        final token = await StorageService.getToken();

        if (isLoggedIn && token != null) {
          // Check if token is expired
          if (JwtUtils.isTokenExpired(token)) {
            // Token is expired, logout and redirect to login
            await StorageService.logout();
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
            return;
          }
          
          // Token is valid, proceed with role-based navigation
          await _handleRoleBasedNavigation();
        } else {
          // User is not logged in, navigate to login screen
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      } catch (e) {
        // If there's an error, navigate to login screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _handleRoleBasedNavigation() async {
    try {
      // Get user data from storage or API
      var userData = await StorageService.getUserData();

      if (userData == null) {
        // If no cached user data, fetch from API
        final userResult = await ActionService.getCurrentUser();
        if (userResult['success']) {
          userData = userResult['data'];
          if (userData != null) {
            await StorageService.saveUserData(userData);
          }
        } else {
          // API call failed - check if it's due to session expiration
          if (userResult['statusCode'] == 401) {
            // Session expired, logout and redirect to login
            await StorageService.logout();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 800),
                ),
              );
            }
            return;
          }
        }
      }

      // Check if we have valid user data
      if (userData == null) {
        // No user data available, logout and redirect to login
        await StorageService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
        return;
      }

      String? userRole = userData['role']?.toString().toLowerCase();

      if (mounted) {
        if (userRole == 'secretary') {
          // Secretary role - navigate to appointment management interface
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const InboxScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else if (userRole == 'admin') {
          // Admin role - navigate to admin interface (to be implemented)
          // TODO: Replace with AdminScreen when implemented
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else if (userRole == 'guard') {
          // Guard role - navigate to guard interface
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const GuardScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else if (userRole == 'user' || userRole == 'client') {
          // Regular user/client role - navigate to user interface (to be implemented)
          // TODO: Replace with UserScreen when implemented
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          // Unknown role or no role - logout and go to login
          await StorageService.logout();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    } catch (e) {
      // If there's an error, logout and go to login screen
      await StorageService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AOL Logo with scale animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: SvgPicture.asset(
                        'image/aol-logo-color.svg',
                        width: 200,
                        height: 100,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Icon(
                          Icons.business,
                          size: 80,
                          color: Color(0xFF1a237e),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // App Title with slide animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'AOL Appointment',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a237e),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Subtitle with fade animation
                    // FadeTransition(
                    //   opacity: _fadeAnimation,
                    //   child: const Text(
                    //     'Professional Appointment Management',
                    //     style: TextStyle(
                    //       fontSize: 18,
                    //       color: Color(0xFF666666),
                    //       letterSpacing: 1.0,
                    //       fontWeight: FontWeight.w300,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            // Bottom section with loading
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1a237e).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1a237e),
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Loading text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Initializing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
