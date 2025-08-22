import 'package:flutter/material.dart';
import 'dart:io';
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
      ),
    );
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
    
    return GestureDetector(
      onTap: () => _onUserTap(user),
      child: Container(
        width: 120,
        height: 120,
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
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'My Divine Picture',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click on a user to view their details',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
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
                                  size: 120, // Match the size of user cards
                                  ariaLabel: 'Add Photo',
                                )
                              else
                                // User cards (adjust index to account for Add Photo button)
                                _buildUserCard(subUsers[i + j - 1]),
                            // Add empty containers to maintain spacing when less than 3 items
                            for (int j = 0; j < (3 - ((i + 3) > (subUsers.length + 1) ? (subUsers.length + 1) - i : 3)); j++)
                              const SizedBox(width: 120),
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
