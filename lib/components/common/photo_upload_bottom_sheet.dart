import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../action/action.dart';

class PhotoUploadBottomSheet extends StatefulWidget {
  final Function(File file)? onPhotoSelected;

  const PhotoUploadBottomSheet({
    super.key,
    this.onPhotoSelected,
  });

  @override
  State<PhotoUploadBottomSheet> createState() => _PhotoUploadBottomSheetState();
}

class _PhotoUploadBottomSheetState extends State<PhotoUploadBottomSheet> {
  File? selectedImage;
  bool isDragging = false;
  bool isUploading = false;
  bool isCreatingSubUser = false;
  Map<String, dynamic>? validationResult;
  bool isValidationComplete = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          isUploading = true;
        });
        
        // Upload and validate the image
        final result = await ActionService.validateProfilePhoto(selectedImage!);
        
        setState(() {
          isUploading = false;
          validationResult = result;
          isValidationComplete = true;
        });
        
        // Check if validation was successful based on response data
        bool isValidationSuccessful = result['success'] == true;
        
        // Also check the status field in the response data
        if (result['data'] != null && result['data']['status'] != null) {
          isValidationSuccessful = result['data']['status'] != 'non_verified';
        }
        
        if (isValidationSuccessful) {
          // Image uploaded and validated successfully
          if (widget.onPhotoSelected != null) {
            widget.onPhotoSelected!(selectedImage!);
          }
        } else {
          // Handle validation failure - keep the image for display
          print('🔍 Validation failed: ${result['message']}');
          print('🔍 Status code: ${result['statusCode']}');
          print('🔍 Response data: ${result['data']}');
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        selectedImage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFF97316)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFF97316)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetValidation() {
    setState(() {
      selectedImage = null;
      validationResult = null;
      isValidationComplete = false;
      isCreatingSubUser = false;
    });
  }

  Future<void> _createSubUser() async {
    if (selectedImage == null) return;

    setState(() {
      isCreatingSubUser = true;
    });

    try {
      final result = await ActionService.createSubUser(selectedImage!);
      
      if (result['success'] == true) {
        // Sub user created successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sub user created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the bottom sheet
        Navigator.of(context).pop();
      } else {
        // Sub user creation failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create sub user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating sub user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isCreatingSubUser = false;
      });
    }
  }

  bool _isValidationSuccessful(Map<String, dynamic> result) {
    // Check if validation was successful based on response data
    bool isSuccess = result['success'] == true;
    
    // Also check the status field in the response data
    if (result['data'] != null && result['data']['status'] != null) {
      isSuccess = result['data']['status'] != 'non_verified';
    }
    
    return isSuccess;
  }

  String _getValidationMessage(Map<String, dynamic> result) {
    // Handle different response structures from backend
    if (_isValidationSuccessful(result)) {
      return result['message'] ?? 'Photo validated successfully!';
    } else {
      // Handle error messages from backend for non-200 status codes
      // Check if we have the response data with status and reason
      if (result['data'] != null) {
        // Handle the structure: {"status": "non_verified", "reason": "multiple_faces_detected! Please upload your image clearly"}
        if (result['data']['status'] == 'non_verified' && result['data']['reason'] != null) {
          return result['data']['reason'];
        }
        // Handle other data structures
        if (result['data']['reason'] != null) {
          return result['data']['reason'];
        }
        if (result['data']['message'] != null) {
          return result['data']['message'];
        }
      }
      
      // Fallback to other error message fields
      if (result['message'] != null) {
        return result['message'];
      } else if (result['error'] != null) {
        return result['error'];
      } else {
        return 'Photo validation failed. Please try again.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upload Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151), // gray-800
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 24,
                        color: Color(0xFF9CA3AF), // gray-400
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        hoverColor: const Color(0xFF374151), // gray-700
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Show validation result or upload area
                if (isValidationComplete && validationResult != null && selectedImage != null) ...[
                  // Validation Result with Image
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isValidationSuccessful(validationResult!)
                            ? Colors.green
                            : Colors.red,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _isValidationSuccessful(validationResult!)
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                    ),
                    child: Column(
                      children: [
                        // Status Title
                        Text(
                          _isValidationSuccessful(validationResult!)
                              ? 'Photo Verified Successfully!'
                              : 'Photo Validation Failed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isValidationSuccessful(validationResult!)
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Image with Validation Indicators
                        Stack(
                          children: [
                            // Main Image
                            Container(
                              width: double.infinity,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: validationResult!['success'] == true
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                                                         // Validation Indicators
                             Positioned(
                               top: 12,
                               left: 12,
                               child: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: _isValidationSuccessful(validationResult!)
                                       ? Colors.green
                                       : Colors.red,
                                   shape: BoxShape.circle,
                                   boxShadow: [
                                     BoxShadow(
                                       color: Colors.black.withOpacity(0.2),
                                       blurRadius: 4,
                                       offset: const Offset(0, 2),
                                     ),
                                   ],
                                 ),
                                 child: Icon(
                                   _isValidationSuccessful(validationResult!)
                                       ? Icons.check
                                       : Icons.close,
                                   color: Colors.white,
                                   size: 24,
                                 ),
                               ),
                             ),
                            
                                                         // Right side indicator (only for success)
                             if (_isValidationSuccessful(validationResult!))
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                                                 // Validation Message
                         Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: _isValidationSuccessful(validationResult!)
                                 ? Colors.green.shade50
                                 : Colors.red.shade50,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(
                               color: _isValidationSuccessful(validationResult!)
                                   ? Colors.green.shade200
                                   : Colors.red.shade200,
                             ),
                           ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    validationResult!['success'] == true
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color: validationResult!['success'] == true
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                                                     Text(
                                     _isValidationSuccessful(validationResult!)
                                         ? 'Validation Result'
                                         : 'Validation Error',
                                     style: TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: _isValidationSuccessful(validationResult!)
                                           ? Colors.green.shade700
                                           : Colors.red.shade700,
                                     ),
                                   ),
                                ],
                              ),
                              const SizedBox(height: 8),
                                                             Text(
                                 _getValidationMessage(validationResult!),
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: _isValidationSuccessful(validationResult!)
                                       ? Colors.green.shade700
                                       : Colors.red.shade700,
                                 ),
                               ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _resetValidation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.grey.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Try Another Photo'),
                              ),
                            ),
                            const SizedBox(width: 12),
                                                         Expanded(
                               child: ElevatedButton(
                                 onPressed: _isValidationSuccessful(validationResult!) && !isCreatingSubUser
                                     ? _createSubUser
                                     : null,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: _isValidationSuccessful(validationResult!)
                                       ? const Color(0xFFF97316)
                                       : Colors.grey.shade300,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                 ),
                                 child: isCreatingSubUser
                                     ? const Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           SizedBox(
                                             width: 16,
                                             height: 16,
                                             child: CircularProgressIndicator(
                                               strokeWidth: 2,
                                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                             ),
                                           ),
                                           SizedBox(width: 8),
                                           Text('Creating...'),
                                         ],
                                       )
                                     : Text(
                                         _isValidationSuccessful(validationResult!)
                                             ? 'Create Sub User'
                                             : 'Fix Issues',
                                       ),
                               ),
                             ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Upload area
                  GestureDetector(
                    onTap: isUploading ? null : _showImageSourceDialog,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isUploading 
                              ? const Color(0xFFF97316) // orange-500 when uploading
                              : const Color(0xFFD1D5DB), // gray-300
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isUploading) ...[
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF97316), // orange-500
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Uploading and validating...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF374151), // gray-700
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              '📷',
                              style: TextStyle(
                                fontSize: 48,
                                color: Color(0xFFFB923C), // orange-400
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151), // gray-700
                                ),
                                children: [
                                  TextSpan(text: 'Drag & drop your photo here, or '),
                                  TextSpan(
                                    text: 'browse',
                                    style: TextStyle(
                                      color: Color(0xFFEA580C), // orange-600
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Allowed formats: JPG, PNG, JPEG',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF), // gray-400
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Show upload button only when not showing validation result
                if (!isValidationComplete) ...[
                  const SizedBox(height: 16),
                  
                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUploading ? null : _showImageSourceDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUploading 
                            ? Colors.grey.shade400 
                            : const Color(0xFFF97316), // orange-500
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isUploading ? 'Uploading...' : 'Choose Photo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
