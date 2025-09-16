import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../action/action.dart';
import '../components/common/add_photo_button.dart';
import '../components/common/photo_upload_bottom_sheet.dart';
import 'user_sidebar.dart';
import 'sub_user_details_screen.dart';

class MyDivinePictureScreen extends StatefulWidget {
  const MyDivinePictureScreen({super.key});

  @override
  State<MyDivinePictureScreen> createState() => _MyDivinePictureScreenState();
}

class _MyDivinePictureScreenState extends State<MyDivinePictureScreen> {
  List<Map<String, dynamic>> subUsers = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic>? userData;
  bool isDeleteMode = false; // New state for delete mode

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final result = await ActionService.getCurrentUser();

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          userData = data;
          subUsers = _extractSubUsers(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = result['message'] ?? 'Failed to load user data';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Network error. Please check your connection and try again.';
      });
    }
  }

  List<Map<String, dynamic>> _extractSubUsers(Map<String, dynamic> userData) {
    final List<Map<String, dynamic>> users = [];
    
    try {
      // Add main user
      users.add({
        'userId': userData['userId'] ?? '',
        'profilePhoto': userData['profilePhoto'] ?? '',
        'fullName': userData['fullName'] ?? 'Main User',
        'isMainUser': true,
      });

      // Add sub users
      final subUsersList = userData['sub_users'] as List<dynamic>?;
      if (subUsersList != null && subUsersList.isNotEmpty) {
        for (int i = 0; i < subUsersList.length; i++) {
          final subUser = subUsersList[i];
          if (subUser is Map<String, dynamic>) {
            users.add({
              'userId': subUser['userId'] ?? '',
              'profilePhoto': subUser['profilePhoto'] ?? '',
              'fullName': 'Divine Picture ${i + 1}', // Use meaningful names for sub users
              'isMainUser': false,
              'subUserId': subUser['_id'] ?? '',
              'index': i + 1,
            });
          }
        }
      }
    } catch (error) {
      print('Error extracting sub users: $error');
      // Return at least the main user if there's an error
      if (users.isEmpty) {
        users.add({
          'userId': userData['userId'] ?? '',
          'profilePhoto': userData['profilePhoto'] ?? '',
          'fullName': userData['fullName'] ?? 'Main User',
          'isMainUser': true,
        });
      }
    }

    return users;
  }

  void _onUserTap(Map<String, dynamic> user) {
    // Navigate to user details screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubUserDetailsScreen(
          userData: user,
          isMainUser: user['isMainUser'] == true,
        ),
      ),
    );
  }

  void _onAddPhotoTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoUploadBottomSheet(
        onPhotoSelected: (File file) {
          // TODO: Handle the selected photo file
          // You can upload it to your server here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo selected: ${file.path}'),
              backgroundColor: const Color(0xFFF97316),
            ),
          );
        },
        onSubUserCreated: () {
          // Refresh the screen when sub-user is successfully created
          _loadUserData();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Stack(
              children: [
                // Close button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.grey,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ),
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 24,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    const Text(
                      'Delete Sub-User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      'Are you sure you want to delete "${user['fullName']}"? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteSubUser(user);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteSubUser(Map<String, dynamic> user) async {
    if (user['isMainUser'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete main user account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await ActionService.deleteSubUser(user['userId']);

      if (result['success'] == true) {
        // Remove the deleted user from the local list
        setState(() {
          subUsers.removeWhere((u) => u['userId'] == user['userId']);
          isDeleteMode = false; // Exit delete mode after successful deletion
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Divine Picture deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete Divine Picture'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildOptimizedImage({
    required String imageUrl,
    Widget? placeholder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.isEmpty) {
      return placeholder ?? Container(
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.person,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Icon(
            Icons.person,
            size: 50,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isMainUser = user['isMainUser'] == true;
    
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _onUserTap(user),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMainUser ? const Color(0xFFF97316) : Colors.blue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildOptimizedImage(
                imageUrl: user['profilePhoto'] ?? '',
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Cross mark for delete mode (sub users only)
        if (!isMainUser && isDeleteMode)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _showDeleteConfirmation(user),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Divine Picture'),
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
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const UserSidebar(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUserData();
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gradient title: Divine Pictures
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFEA580C), // from-orange-600
                          Color(0xFF9A3412), // to-orange-800
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'Divine Pictures',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40, // text-4xl (approx), scales well on mobile
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Discover and share your precious darshan moments with Gurudev',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Powered by line with pulsing dot and link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.3, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF97316),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF97316),
                            ),
                            children: [
                              const TextSpan(text: 'DivinePicAI Powered By '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse('https://sumerudigital.com/');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    'Sumeru Digital Solutions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (subUsers.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No users found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Users Grid - 3 columns with Add Photo button integrated
                Column(
                  children: [
                    // Title and Delete Button in same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Divine Pictures',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isDeleteMode = !isDeleteMode;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDeleteMode ? Colors.red : const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            isDeleteMode ? Icons.close : Icons.delete_outline,
                            size: 20,
                          ),
                          label: Text(
                            isDeleteMode ? 'Cancel Delete' : 'Delete',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (int i = 0; i < (subUsers.length + 1); i += 3)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (int j = 0; j < 3 && (i + j) < (subUsers.length + 1); j++)
                              if (i + j == 0)
                                // Add Photo button in first position
                                AddPhotoButton(
                                  onPressed: _onAddPhotoTap,
                                  size: 100, // Match the size of user cards
                                  ariaLabel: 'Add Photo',
                                )
                              else
                                // User cards (adjust index to account for Add Photo button)
                                _buildUserCard(subUsers[i + j - 1]),
                            // Add empty containers to maintain spacing when less than 3 items
                            for (int j = 0; j < (3 - ((i + 3) > (subUsers.length + 1) ? (subUsers.length + 1) - i : 3)); j++)
                              const SizedBox(width: 100),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
