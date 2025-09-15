import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../components/sidebar/sidebar_component.dart';
import '../action/storage_service.dart';
import '../action/action.dart';
import '../auth/login_screen.dart';
import '../components/user/photo_validation_bottom_sheet.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditMode = false;
  
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Photo upload state
  File? _selectedImageFile;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Fetch fresh user data from API
      final result = await ActionService.getCurrentUser();
      
      if (result['success']) {
        setState(() {
          _userData = result['data'];
          _isLoading = false;
        });
        
        // Initialize form controllers with user data
        _fullNameController.text = result['data']?['fullName'] ?? '';
        _emailController.text = result['data']?['email'] ?? '';
      } else {
        // Handle error cases
        if (result['statusCode'] == 401 || 
            result['statusCode'] == 403 || 
            result['statusCode'] == 404) {
          // Session expired or account issues - logout and redirect to login
          await StorageService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else {
          // Other errors - show error message
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to load user data'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

  void _handleEditAccount() {
    setState(() {
      _isEditMode = true;
    });
  }

  void _handleCancelEdit() {
    setState(() {
      _isEditMode = false;
      // Reset form fields to original values
      _fullNameController.text = _userData?['fullName'] ?? '';
      _emailController.text = _userData?['email'] ?? '';
      // Clear selected image
      _selectedImageFile = null;
      _isUploadingPhoto = false;
    });
  }

  void _handleSaveChanges() async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving changes...'),
            ],
          ),
        );
      },
    );

    try {
      // Get current user data for required fields
      final currentUserData = _userData!;
      
      // Prepare the update data
      final result = await ActionService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        email: currentUserData['email'] ?? '', // Email is read-only, use current
        phoneNumber: currentUserData['phoneNumber']?['number']?.toString() ?? 
                    currentUserData['phoneNumber']?.toString() ?? 
                    '', // Use current phone number
        designation: currentUserData['designation'],
        company: currentUserData['company'],
        full_address: currentUserData['full_address']?['display_name']?.toString() ?? 
                     currentUserData['full_address']?.toString() ?? 
                     '', // Use current address
        userTags: _getValidUserTags(currentUserData), // Filter out invalid tags
        profilePhotoUrl: currentUserData['profilePhoto'], // Use current photo URL
        profilePhotoFile: _selectedImageFile, // Include validated photo file if selected
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Refresh user data from server to get the latest information
        await _loadUserData();
        
        // Exit edit mode
        setState(() {
          _isEditMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUploadPhoto() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _handleTakePhoto() async {
    await _pickImage(ImageSource.camera);
  }

  void _handleRemovePhoto() {
    setState(() {
      _selectedImageFile = null;
      _isUploadingPhoto = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Show uploading state immediately
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      try {
        // Validate photo first using the validation API
        final result = await ActionService.validateProfilePhoto(
          File(pickedFile.path),
        );

        if (result['success']) {
          // Validation successful
          setState(() {
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo validated successfully! It will be uploaded when you save changes.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Validation failed - clear the selected file and show error dialog
          setState(() {
            _selectedImageFile = null;
            _isUploadingPhoto = false;
          });

          // Show backend error message in dialog
          final errorMessage =
              result['error'] ?? result['message'] ?? 'Photo validation failed';
          _showPhotoValidationErrorDialog(errorMessage, () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImageFile = null;
              _isUploadingPhoto = false;
            });
          });
        }
      } catch (e) {
        // Exception occurred - clear the selected file and show error dialog
        setState(() {
          _selectedImageFile = null;
          _isUploadingPhoto = false;
        });

        // Show error message in dialog
        _showPhotoValidationErrorDialog(
          'Error validating photo: ${e.toString()}',
          () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImageFile = null;
              _isUploadingPhoto = false;
            });
          },
        );
      }
    }
  }

  void _showPhotoValidationErrorDialog(String errorMessage, VoidCallback onRetry) {
    // Remove "Guest X:" prefix if present
    String cleanErrorMessage = errorMessage;
    if (cleanErrorMessage.contains('Guest ') &&
        cleanErrorMessage.contains(': ')) {
      cleanErrorMessage = cleanErrorMessage.split(': ').skip(1).join(': ');
    }

    // Remove "Profile photo validation failed:" prefix if present
    if (cleanErrorMessage.startsWith('Profile photo validation failed:')) {
      cleanErrorMessage = cleanErrorMessage
          .replaceFirst('Profile photo validation failed:', '')
          .trim();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Photo Validation Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanErrorMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please ensure your photo meets our validation requirements',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show photo validation guidance bottom sheet
                PhotoValidationBottomSheet.show(
                  context,
                  onTryAgain: onRetry,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Photo Guidelines',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getValidUserTags(Map<String, dynamic> userData) {
    // Get user tags from either userTags or additionalRoles
    List<String> tags = [];
    
    if (userData['userTags'] != null) {
      if (userData['userTags'] is List) {
        tags.addAll(userData['userTags'].cast<String>());
      }
    }
    
    if (userData['additionalRoles'] != null) {
      if (userData['additionalRoles'] is List) {
        tags.addAll(userData['additionalRoles'].cast<String>());
      }
    }
    
    // Filter out invalid tags like "No Roles selected"
    return tags.where((tag) => 
      tag.isNotEmpty && 
      tag.toLowerCase() != 'no roles selected' &&
      tag.toLowerCase() != 'none'
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First line: Main heading
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Second line: Sub-heading
                          Text(
                            'Manage your account information and preferences.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Third line: Action buttons
                          if (!_isEditMode) ...[
                            // Edit Account button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.orangeAccent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _handleEditAccount,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit Account'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ] else ...[
                                                         // Save and Cancel buttons
                             Row(
                               children: [
                                 Expanded(
                                   child: SizedBox(
                                     height: 48, // Fixed height for both buttons
                                     child: ElevatedButton(
                                       onPressed: _handleCancelEdit,
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.white,
                                         foregroundColor: Colors.grey.shade700,
                                         padding: const EdgeInsets.symmetric(horizontal: 20),
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(8),
                                           side: BorderSide(color: Colors.grey.shade200),
                                         ),
                                         elevation: 0,
                                       ),
                                       child: const Text('Cancel'),
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: SizedBox(
                                     height: 48, // Fixed height for both buttons
                                     child: Container(
                                       decoration: BoxDecoration(
                                         gradient: const LinearGradient(
                                           colors: [Colors.green, Colors.greenAccent],
                                           begin: Alignment.centerLeft,
                                           end: Alignment.centerRight,
                                         ),
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                       child: ElevatedButton.icon(
                                         onPressed: _handleSaveChanges,
                                         icon: const Icon(Icons.save, size: 18),
                                         label: const Text('Save Changes'),
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: Colors.transparent,
                                           foregroundColor: Colors.white,
                                           padding: const EdgeInsets.symmetric(horizontal: 20),
                                           shape: RoundedRectangleBorder(
                                             borderRadius: BorderRadius.circular(8),
                                           ),
                                           elevation: 0,
                                           shadowColor: Colors.transparent,
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                                         // Main Content - Vertical Layout
                     Column(
                       children: [
                         // Profile Photo Card
                         Container(
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(16),
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.grey.withOpacity(0.1),
                                 spreadRadius: 1,
                                 blurRadius: 10,
                                 offset: const Offset(0, 2),
                               ),
                             ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Card Header
                               Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     colors: [
                                       Colors.grey.shade50,
                                       Colors.white,
                                       Colors.grey.shade50.withOpacity(0.5),
                                     ],
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                   ),
                                   borderRadius: const BorderRadius.vertical(
                                     top: Radius.circular(16),
                                   ),
                                   border: Border(
                                     bottom: BorderSide(
                                       color: Colors.grey.shade200,
                                       width: 1,
                                     ),
                                   ),
                                 ),
                                 child: Row(
                                   children: [
                                     Icon(
                                       Icons.person,
                                       size: 24,
                                       color: Colors.grey.shade400,
                                     ),
                                     const SizedBox(width: 12),
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         const Text(
                                           'Profile Photo',
                                           style: TextStyle(
                                             fontSize: 20,
                                             fontWeight: FontWeight.w600,
                                             color: Color(0xFF1F2937),
                                           ),
                                         ),
                                         Text(
                                           'Your profile picture - Divine pic validation',
                                           style: TextStyle(
                                             fontSize: 14,
                                             color: Colors.grey.shade500,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                                                                    // Card Content
                                     Padding(
                                       padding: const EdgeInsets.all(24),
                                       child: _isEditMode
                                           ? Column(
                                               children: [
                                                 // Profile Photo with edit styling
                                                 Container(
                                                   width: double.infinity,
                                                   padding: const EdgeInsets.all(24),
                                                   decoration: BoxDecoration(
                                                     border: Border.all(
                                                       color: Colors.green.shade300,
                                                       width: 2,
                                                     ),
                                                     borderRadius: BorderRadius.circular(16),
                                                     color: Colors.green.shade50.withOpacity(0.5),
                                                   ),
                                                   child: Column(
                                                     children: [
                                                       // Profile Photo
                                                       Container(
                                                         width: 144,
                                                         height: 144,
                                                         decoration: BoxDecoration(
                                                           shape: BoxShape.circle,
                                                           border: Border.all(
                                                             color: Colors.white,
                                                             width: 4,
                                                           ),
                                                           boxShadow: [
                                                             BoxShadow(
                                                               color: Colors.grey.withOpacity(0.3),
                                                               spreadRadius: 2,
                                                               blurRadius: 10,
                                                               offset: const Offset(0, 4),
                                                             ),
                                                           ],
                                                         ),
                                                         child: ClipOval(
                                                           child: _isUploadingPhoto
                                                               ? Container(
                                                                   width: 128,
                                                                   height: 128,
                                                                   decoration: BoxDecoration(
                                                                     color: Colors.blue.shade50,
                                                                     shape: BoxShape.circle,
                                                                   ),
                                                                   child: const Center(
                                                                     child: Column(
                                                                       mainAxisAlignment: MainAxisAlignment.center,
                                                                       children: [
                                                                         CircularProgressIndicator(
                                                                           valueColor: AlwaysStoppedAnimation<Color>(
                                                                             Colors.blue,
                                                                           ),
                                                                           strokeWidth: 3,
                                                                         ),
                                                                         SizedBox(height: 8),
                                                                         Text(
                                                                           'Validating...',
                                                                           style: TextStyle(
                                                                             fontSize: 12,
                                                                             color: Colors.blue,
                                                                             fontWeight: FontWeight.w500,
                                                                           ),
                                                                         ),
                                                                       ],
                                                                     ),
                                                                   ),
                                                                 )
                                                               : _selectedImageFile != null
                                                                   ? Image.file(
                                                                       _selectedImageFile!,
                                                                       width: 128,
                                                                       height: 128,
                                                                       fit: BoxFit.cover,
                                                                       errorBuilder: (context, error, stackTrace) {
                                                                         return Container(
                                                                           width: 128,
                                                                           height: 128,
                                                                           color: Colors.grey.shade200,
                                                                           child: Icon(
                                                                             Icons.person,
                                                                             size: 64,
                                                                             color: Colors.grey.shade400,
                                                                           ),
                                                                         );
                                                                       },
                                                                     )
                                                                   : _userData?['profilePhoto'] != null
                                                                       ? Image.network(
                                                                           _userData!['profilePhoto'],
                                                                           width: 128,
                                                                           height: 128,
                                                                           fit: BoxFit.cover,
                                                                           errorBuilder: (context, error, stackTrace) {
                                                                             return Container(
                                                                               width: 128,
                                                                               height: 128,
                                                                               color: Colors.grey.shade200,
                                                                               child: Icon(
                                                                                 Icons.person,
                                                                                 size: 64,
                                                                                 color: Colors.grey.shade400,
                                                                               ),
                                                                             );
                                                                           },
                                                                         )
                                                                       : Container(
                                                                           width: 128,
                                                                           height: 128,
                                                                           color: Colors.grey.shade200,
                                                                           child: Icon(
                                                                             Icons.person,
                                                                             size: 64,
                                                                             color: Colors.grey.shade400,
                                                                           ),
                                                                         ),
                                                         ),
                                                       ),
                                                       const SizedBox(height: 16),
                                                       // Photo Status
                                                       Column(
                                                         children: [
                                                           Text(
                                                             _isUploadingPhoto
                                                                 ? 'Validating photo...'
                                                                 : _selectedImageFile != null
                                                                     ? 'New photo selected'
                                                                     : _userData?['profilePhoto'] != null
                                                                         ? 'Photo uploaded'
                                                                         : 'No photo uploaded',
                                                             style: TextStyle(
                                                               fontSize: 18,
                                                               fontWeight: FontWeight.w500,
                                                               color: _isUploadingPhoto
                                                                   ? Colors.blue
                                                                   : const Color(0xFF166534),
                                                             ),
                                                           ),
                                                           const SizedBox(height: 4),
                                                           Text(
                                                             _isUploadingPhoto
                                                                 ? 'Please wait while we validate your photo'
                                                                 : _selectedImageFile != null
                                                                     ? 'Ready to upload'
                                                                     : _userData?['profilePhoto'] != null
                                                                         ? 'Photo from server'
                                                                         : 'No photo available',
                                                             style: TextStyle(
                                                               fontSize: 14,
                                                               color: _isUploadingPhoto
                                                                   ? Colors.blue.shade600
                                                                   : Colors.green.shade600,
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                                 const SizedBox(height: 24),
                                                 // Important notice
                                                 Container(
                                                   width: double.infinity,
                                                   padding: const EdgeInsets.all(12),
                                                   decoration: BoxDecoration(
                                                     color: Colors.orange.shade50,
                                                     borderRadius: BorderRadius.circular(8),
                                                     border: Border.all(color: Colors.orange.shade200),
                                                   ),
                                                   child: Text(
                                                     'Important: Kindly upload a recent and clearly recognizable passport size photo to help us with identification and smooth entry during your visit. The appointment / darshan, if confirmed, will be non-transferable.',
                                                     style: TextStyle(
                                                       fontSize: 12,
                                                       color: Colors.orange.shade700,
                                                       fontWeight: FontWeight.w500,
                                                     ),
                                                   ),
                                                 ),
                                                 const SizedBox(height: 12),
                                                 // Photo Action Buttons
                                                 // First line: Upload Different Photo (full width)
                                                 SizedBox(
                                                   width: double.infinity,
                                                   child: ElevatedButton.icon(
                                                     onPressed: _handleUploadPhoto,
                                                     icon: const Icon(Icons.upload, size: 20),
                                                     label: const Text('Upload Different Photo'),
                                                     style: ElevatedButton.styleFrom(
                                                       backgroundColor: Colors.white,
                                                       foregroundColor: Colors.grey.shade700,
                                                       padding: const EdgeInsets.symmetric(vertical: 12),
                                                       shape: RoundedRectangleBorder(
                                                         borderRadius: BorderRadius.circular(8),
                                                         side: BorderSide(color: Colors.grey.shade200),
                                                       ),
                                                       elevation: 0,
                                                     ),
                                                   ),
                                                 ),
                                                 const SizedBox(height: 12),
                                                 // Second line: Take New Photo and Remove (side by side)
                                                 Row(
                                                   children: [
                                                     Expanded(
                                                       child: ElevatedButton.icon(
                                                         onPressed: _handleTakePhoto,
                                                         icon: const Icon(Icons.camera_alt, size: 20),
                                                         label: const Text('Take New Photo'),
                                                         style: ElevatedButton.styleFrom(
                                                           backgroundColor: Colors.white,
                                                           foregroundColor: Colors.grey.shade700,
                                                           padding: const EdgeInsets.symmetric(vertical: 12),
                                                           shape: RoundedRectangleBorder(
                                                             borderRadius: BorderRadius.circular(8),
                                                             side: BorderSide(color: Colors.grey.shade200),
                                                           ),
                                                           elevation: 0,
                                                         ),
                                                       ),
                                                     ),
                                                     const SizedBox(width: 12),
                                                     Expanded(
                                                       child: ElevatedButton.icon(
                                                         onPressed: _handleRemovePhoto,
                                                         icon: const Icon(Icons.close, size: 20),
                                                         label: const Text('Remove'),
                                                         style: ElevatedButton.styleFrom(
                                                           backgroundColor: Colors.white,
                                                           foregroundColor: Colors.red.shade600,
                                                           padding: const EdgeInsets.symmetric(vertical: 12),
                                                           shape: RoundedRectangleBorder(
                                                             borderRadius: BorderRadius.circular(8),
                                                             side: BorderSide(color: Colors.red.shade200),
                                                           ),
                                                           elevation: 0,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               ],
                                             )
                                           : Row(
                                               children: [
                                                 // Profile Photo (read-only mode)
                                                 Container(
                                                   width: 144,
                                                   height: 144,
                                                   decoration: BoxDecoration(
                                                     shape: BoxShape.circle,
                                                     border: Border.all(
                                                       color: Colors.white,
                                                       width: 4,
                                                     ),
                                                     boxShadow: [
                                                       BoxShadow(
                                                         color: Colors.grey.withOpacity(0.3),
                                                         spreadRadius: 2,
                                                         blurRadius: 10,
                                                         offset: const Offset(0, 4),
                                                       ),
                                                     ],
                                                   ),
                                                   child: ClipOval(
                                                     child: _userData?['profilePhoto'] != null
                                                         ? Image.network(
                                                             _userData!['profilePhoto'],
                                                             width: 128,
                                                             height: 128,
                                                             fit: BoxFit.cover,
                                                             errorBuilder: (context, error, stackTrace) {
                                                               return Container(
                                                                 width: 128,
                                                                 height: 128,
                                                                 color: Colors.grey.shade200,
                                                                 child: Icon(
                                                                   Icons.person,
                                                                   size: 64,
                                                                   color: Colors.grey.shade400,
                                                                 ),
                                                               );
                                                             },
                                                           )
                                                         : Container(
                                                             width: 128,
                                                             height: 128,
                                                             color: Colors.grey.shade200,
                                                             child: Icon(
                                                               Icons.person,
                                                               size: 64,
                                                               color: Colors.grey.shade400,
                                                             ),
                                                           ),
                                                   ),
                                                 ),
                                                 const SizedBox(width: 24),
                                                 // Photo Info
                                                 Expanded(
                                                   child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       const Text(
                                                         'Profile Photo',
                                                         style: TextStyle(
                                                           fontSize: 18,
                                                           fontWeight: FontWeight.w500,
                                                           color: Color(0xFF1F2937),
                                                         ),
                                                       ),
                                                       const SizedBox(height: 4),
                                                       Text(
                                                         _userData?['profilePhoto'] != null
                                                             ? 'Photo uploaded'
                                                             : 'No photo uploaded',
                                                         style: TextStyle(
                                                           fontSize: 14,
                                                           color: Colors.grey.shade500,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ],
                                             ),
                                     ),
                             ],
                           ),
                         ),
                         
                         const SizedBox(height: 24),

                         // Personal Information Card
                         Container(
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(16),
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.grey.withOpacity(0.1),
                                 spreadRadius: 1,
                                 blurRadius: 10,
                                 offset: const Offset(0, 2),
                               ),
                             ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Card Header
                               Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     colors: [
                                       Colors.grey.shade50,
                                       Colors.white,
                                       Colors.grey.shade50.withOpacity(0.5),
                                     ],
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                   ),
                                   borderRadius: const BorderRadius.vertical(
                                     top: Radius.circular(16),
                                   ),
                                   border: Border(
                                     bottom: BorderSide(
                                       color: Colors.grey.shade200,
                                       width: 1,
                                     ),
                                   ),
                                 ),
                                 child: Row(
                                   children: [
                                     Icon(
                                       Icons.person,
                                       size: 24,
                                       color: Colors.grey.shade400,
                                     ),
                                     const SizedBox(width: 12),
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         const Text(
                                           'Personal Information',
                                           style: TextStyle(
                                             fontSize: 20,
                                             fontWeight: FontWeight.w600,
                                             color: Color(0xFF1F2937),
                                           ),
                                         ),
                                         Text(
                                           'Your basic account information',
                                           style: TextStyle(
                                             fontSize: 14,
                                             color: Colors.grey.shade500,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                                                                // Card Content
                                 Padding(
                                   padding: const EdgeInsets.all(24),
                                   child: Column(
                                     children: [
                                       // Full Name
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text(
                                             'Full Name',
                                             style: TextStyle(
                                               fontSize: 14,
                                               fontWeight: FontWeight.w500,
                                               color: Color(0xFF374151),
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                                                                       _isEditMode
                                                ? TextField(
                                                    controller: _fullNameController,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                    decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: 'Enter your full name',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide(color: Colors.blue.shade300),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    ),
                                                  )
                                               : Container(
                                                   width: double.infinity,
                                                   height: 48,
                                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                   decoration: BoxDecoration(
                                                     color: Colors.grey.shade50.withOpacity(0.3),
                                                     border: Border.all(color: Colors.grey.shade200),
                                                     borderRadius: BorderRadius.circular(8),
                                                   ),
                                                   child: Align(
                                                     alignment: Alignment.centerLeft,
                                                     child: Text(
                                                       _userData?['fullName'] ?? 'Not available',
                                                       style: const TextStyle(
                                                         fontSize: 16,
                                                         color: Color(0xFF1F2937),
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                         ],
                                       ),
                                       const SizedBox(height: 24),

                                       // Email Address
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text(
                                             'Email Address',
                                             style: TextStyle(
                                               fontSize: 14,
                                               fontWeight: FontWeight.w500,
                                               color: Color(0xFF374151),
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                                                                                                                   Container(
                                              width: double.infinity,
                                              height: 48,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100.withOpacity(0.5),
                                                border: Border.all(color: Colors.grey.shade200),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _userData?['email'] ?? 'Not available',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                                                                         ),
                                         ],
                                       ),
                                     ],
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
            ),
    );
  }
}
