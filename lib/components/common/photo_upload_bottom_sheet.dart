import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../action/action.dart';

class PhotoUploadBottomSheet extends StatefulWidget {
  final Function(File file)? onPhotoSelected;
  final VoidCallback? onSubUserCreated;

  const PhotoUploadBottomSheet({
    super.key,
    this.onPhotoSelected,
    this.onSubUserCreated,
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
  bool isDuplicateValidationComplete = false;
  Map<String, dynamic>? duplicateValidationResult;
  String? duplicateValidationError;
  String? subUserCreationError; // New variable for sub-user creation errors

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
          validationResult = null;
          isValidationComplete = false;
          duplicateValidationResult = null;
          isDuplicateValidationComplete = false;
          duplicateValidationError = null;
          subUserCreationError = null;
        });
        
        // Step 1: Upload and validate the image
        final result = await ActionService.validateProfilePhoto(selectedImage!);
        
        setState(() {
          validationResult = result;
          isValidationComplete = true;
        });
        
        // Check if initial validation was successful
        bool isValidationSuccessful = result['success'] == true;
        
        if (isValidationSuccessful) {
          // Step 2: Perform duplicate photo validation
          setState(() {
            isUploading = true;
          });
          
          try {
            final duplicateResult = await ActionService.validateDuplicatePhoto(
              selectedImage!,
            );
            
            setState(() {
              duplicateValidationResult = duplicateResult;
              isDuplicateValidationComplete = true;
              isUploading = false;
            });
            
            // Check if duplicate validation passed
            if (duplicateResult['success'] == true) {
              final apiResult = duplicateResult['data']?['apiResult'];
              if (apiResult != null && apiResult['duplicates_found'] == true) {
                // Duplicate photo detected
                setState(() {
                  duplicateValidationError = "Duplicate photo detected. This photo is too similar to an existing photo in your account.";
                });
              } else {
                // No duplicates found, proceed with sub-user creation
                if (widget.onPhotoSelected != null) {
                  widget.onPhotoSelected!(selectedImage!);
                }
              }
            } else {
              // Duplicate validation failed
              setState(() {
                duplicateValidationError = "⚠️ Duplicate photo detected";
              });
            }
          } catch (duplicateError) {
            setState(() {
              isUploading = false;
              duplicateValidationError = "Error checking for duplicates: ${duplicateError.toString()}";
            });
          }
        } else {
          // Initial validation failed
          setState(() {
            isUploading = false;
          });
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
      isDuplicateValidationComplete = false;
      duplicateValidationResult = null;
      duplicateValidationError = null;
      subUserCreationError = null;
      isCreatingSubUser = false;
    });
  }

  bool _canProceedWithSubUserCreation() {
    // Check if initial validation passed and duplicate validation is complete
    if (validationResult == null || !_isValidationSuccessful(validationResult!)) {
      return false;
    }
    
    if (!isDuplicateValidationComplete) {
      return false;
    }
    
    // Check if there are no duplicate validation errors
    if (duplicateValidationError != null) {
      return false;
    }
    
    // Check if duplicate validation result is successful
    if (duplicateValidationResult != null && duplicateValidationResult!['success'] == true) {
      final apiResult = duplicateValidationResult!['data']?['apiResult'];
      if (apiResult != null && apiResult['duplicates_found'] == true) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _createSubUser() async {
    if (selectedImage == null) return;

    // Double-check that we can proceed with sub-user creation
    if (!_canProceedWithSubUserCreation()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for photo validation to complete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        
        // Call the callback to refresh the parent screen
        if (widget.onSubUserCreated != null) {
          widget.onSubUserCreated!();
        }
        
        // Close the bottom sheet
        Navigator.of(context).pop();
      } else {
        // Sub user creation failed - show error in bottom sheet instead of toast
        setState(() {
          isCreatingSubUser = false;
          // Store the error message to display in the UI
          subUserCreationError = result['message'] ?? 'Failed to create sub user';
        });
      }
    } catch (e) {
      setState(() {
        isCreatingSubUser = false;
        subUserCreationError = 'Error creating sub user: $e';
      });
    }
  }

  bool _isValidationSuccessful(Map<String, dynamic> result) {
    // Debug: Print the actual result structure
    print('🔍 [DEBUG VALIDATION] Full result: $result');
    print('🔍 [DEBUG VALIDATION] result["success"]: ${result['success']}');
    print('🔍 [DEBUG VALIDATION] result["status"]: ${result['status']}');
    print('🔍 [DEBUG VALIDATION] result["data"]: ${result['data']}');
    
    // Check if validation was successful based on response data
    bool isSuccess = result['success'] == true;
    
    // Check the status field in the response data (directly in result, not nested under data)
    if (result['status'] != null) {
      isSuccess = result['status'] == 'verified';
    }
    
    // Also check if data contains status (in case it's nested)
    if (result['data'] != null && result['data']['status'] != null) {
      isSuccess = result['data']['status'] == 'verified';
    }
    
    print('🔍 [DEBUG VALIDATION] Final isSuccess: $isSuccess');
    return isSuccess;
  }

  String _getValidationMessage(Map<String, dynamic> result) {
    // Debug: Print the actual result structure for message
    print('🔍 [DEBUG MESSAGE] Full result: $result');
    print('🔍 [DEBUG MESSAGE] result["status"]: ${result['status']}');
    print('🔍 [DEBUG MESSAGE] result["reason"]: ${result['reason']}');
    print('🔍 [DEBUG MESSAGE] result["data"]: ${result['data']}');
    
    // Handle different response structures from backend
    if (_isValidationSuccessful(result)) {
      return result['message'] ?? 'Photo validated successfully!';
    } else {
      // Handle error messages from backend for non-200 status codes
      // Check if we have the response data with status and reason
      if (result['status'] == 'non_verified' && result['reason'] != null) {
        return result['reason'];
      }
      
      // Also check if data contains the reason
      if (result['data'] != null && result['data']['reason'] != null) {
        return result['data']['reason'];
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
                  Column(
                    children: [
                      // Image
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: validationResult != null && _isValidationSuccessful(validationResult!)
                                ? Colors.transparent
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
                      
                      const SizedBox(height: 16),
                      
                      // Initial Validation Message
                      Text(
                        validationResult != null ? _getValidationMessage(validationResult!) : 'Validation in progress...',
                        style: TextStyle(
                          fontSize: 14,
                          color: validationResult != null && _isValidationSuccessful(validationResult!)
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      
                      // Show duplicate validation status if initial validation passed
                      if (validationResult != null && _isValidationSuccessful(validationResult!) && isDuplicateValidationComplete) ...[
                        const SizedBox(height: 16),
                        
                        if (duplicateValidationError != null) ...[
                          // Duplicate photo error
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    duplicateValidationError!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (duplicateValidationResult != null && duplicateValidationResult!['success'] == true) ...[
                          // Duplicate validation passed
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No duplicate photos detected. You can proceed with creating a sub-user.',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      
                      // Show sub-user creation error if it exists
                      if (subUserCreationError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subUserCreationError!,
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Show loading for duplicate validation
                      if (validationResult != null && _isValidationSuccessful(validationResult!) && !isDuplicateValidationComplete && isUploading) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Checking for duplicate photos...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
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
                              onPressed: _canProceedWithSubUserCreation() && !isCreatingSubUser && subUserCreationError == null
                                  ? _createSubUser
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canProceedWithSubUserCreation() && subUserCreationError == null
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
                                  : const Text('Create Sub User'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                            Text(
                              isValidationComplete && !isDuplicateValidationComplete
                                  ? 'Checking for duplicate photos...'
                                  : 'Uploading and validating...',
                              style: const TextStyle(
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
                        isUploading 
                            ? (isValidationComplete && !isDuplicateValidationComplete 
                                ? 'Checking Duplicates...' 
                                : 'Uploading...')
                            : 'Choose Photo',
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
