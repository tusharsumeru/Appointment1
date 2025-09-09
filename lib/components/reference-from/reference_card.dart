import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../action/action.dart';
import '../common/profile_photo_dialog.dart'; // Add this import

class ReferenceCard extends StatefulWidget {
  final Map<String, dynamic> referenceData;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStatusUpdated;
  final int index; // Add index parameter for alternating colors

  const ReferenceCard({
    super.key,
    required this.referenceData,
    this.onViewDetails,
    this.onStatusUpdated,
    required this.index, // Add index parameter
  });

  @override
  State<ReferenceCard> createState() => _ReferenceCardState();
}

class _ReferenceCardState extends State<ReferenceCard> {
  bool _isApproving = false;
  bool _isRejecting = false;
  bool _showRemarkSection = false;
  final TextEditingController _remarkController = TextEditingController();

  // Helper getters for easy access to data
  String get name => widget.referenceData['name'] ?? 'Unknown';
  String get email => widget.referenceData['email'] ?? 'No email';
  String get phone => widget.referenceData['phone'] ?? 'No phone';
  String get status => widget.referenceData['status'] ?? 'Unknown';
  String? get profilePic => widget.referenceData['photo'] ?? widget.referenceData['profilePic'];
  String get createdAt => _formatDate(widget.referenceData['createdAt'] ?? 'No date');
  String get formId => widget.referenceData['_id'] ?? widget.referenceData['id'] ?? '';

  // Helper method to format date in IST
  String _formatDate(String dateString) {
    if (dateString == 'No date') return 'No date';
    
    try {
      // Parse ISO date string (UTC)
      DateTime utcDate = DateTime.parse(dateString);
      
      // Convert to IST (UTC + 5:30)
      DateTime istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      
      // Format to user-friendly format: "3 Sep 2025, 3:05 AM IST"
      List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      String day = istDate.day.toString();
      String month = months[istDate.month - 1];
      String year = istDate.year.toString();
      
      // Format time in IST
      String hour = istDate.hour.toString().padLeft(2, '0');
      String minute = istDate.minute.toString().padLeft(2, '0');
      String amPm = istDate.hour >= 12 ? 'PM' : 'AM';
      int displayHour = istDate.hour > 12 ? istDate.hour - 12 : (istDate.hour == 0 ? 12 : istDate.hour);
      
      return '$day $month $year, $displayHour:$minute $amPm';
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  // Show remark section
  void _toggleRemarkSection() {
    setState(() {
      _showRemarkSection = true;
    });
  }

  // Handle accept action
  Future<void> _handleAccept() async {
    if (_isApproving || _isRejecting || formId.isEmpty) return;
    
    setState(() {
      _isApproving = true;
    });

    try {
      print('🔄 Calling updateReferenceFormStatus for formId: $formId');
      print('🔄 Status: Approved');
      print('🔄 Secretary remark: ${_remarkController.text.trim()}');
      
      final result = await ActionService.updateReferenceFormStatus(
        formId: formId,
        status: 'Approved',
        secretaryRemark: _remarkController.text.trim().isNotEmpty 
            ? _remarkController.text.trim() 
            : 'Approved by secretary',
      );
      
      print('🔄 API Response: $result');

      if (result['success'] == true) {
        // Trigger refresh to fetch updated data immediately
        widget.onStatusUpdated?.call();
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to approve reference form');
      }
    } catch (e) {
      _showErrorMessage('Error accepting reference form: $e');
    } finally {
      setState(() {
        _isApproving = false;
      });
    }
  }

  // Handle reject action
  Future<void> _handleReject() async {
    if (_isApproving || _isRejecting || formId.isEmpty) return;
    
    setState(() {
      _isRejecting = true;
    });

    try {
      print('🔄 Calling updateReferenceFormStatus for formId: $formId');
      print('🔄 Status: Rejected');
      print('🔄 Secretary remark: ${_remarkController.text.trim()}');
      
      final result = await ActionService.updateReferenceFormStatus(
        formId: formId,
        status: 'Rejected',
        secretaryRemark: _remarkController.text.trim().isNotEmpty 
            ? _remarkController.text.trim() 
            : 'Rejected by secretary',
      );
      
      print('🔄 API Response: $result');

      if (result['success'] == true) {
        // Trigger refresh to fetch updated data immediately
        widget.onStatusUpdated?.call();
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to reject reference form');
      }
    } catch (e) {
      _showErrorMessage('Error rejecting reference form: $e');
    } finally {
      setState(() {
        _isRejecting = false;
      });
    }
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Remove the old _showFullImage method and replace with ProfilePhotoDialog
  void _showProfilePhoto(BuildContext context, String imageUrl) {
    ProfilePhotoDialog.showWithErrorHandling(
      context,
      imageUrl: imageUrl,
      userName: name,
      description: "$name's profile photo",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging to see the data structure
    print('ReferenceCard - referenceData: ${widget.referenceData}');
    print('ReferenceCard - name: $name');
    print('ReferenceCard - email: $email');
    print('ReferenceCard - phone: $phone');
    print('ReferenceCard - status: $status');
    print('ReferenceCard - createdAt: $createdAt');
    print('ReferenceCard - formId: $formId');
    print('ReferenceCard - profilePic: $profilePic');
    print('ReferenceCard - photo field: ${widget.referenceData['photo']}');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with status badge overlay
          Container(
            height: 256, // h-64 equivalent
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                // Full width image
                GestureDetector(
                  onTap: profilePic != null ? () => _showProfilePhoto(context, profilePic!) : null,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: profilePic != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              profilePic!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Status badge positioned absolutely
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(status),
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(
                      Icons.visibility,
                      size: 16,
                    ),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade200),
                      foregroundColor: Colors.blue.shade600,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                // Only show Approve/Reject buttons if status is pending
                if (status.toLowerCase() == 'pending') ...[
                  const SizedBox(height: 12),
                  
                  // Show initial Approve/Reject buttons if remark section is not shown
                  if (!_showRemarkSection) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleRemarkSection,
                            icon: const Icon(
                              Icons.check_circle,
                              size: 16,
                            ),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleRemarkSection,
                            icon: const Icon(
                              Icons.cancel,
                              size: 16,
                            ),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Show remark section and final action buttons when _showRemarkSection is true
                  if (_showRemarkSection) ...[
                    // Secretary Remark Text Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secretary Remark(optional):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remarkController,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                            FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z].*')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter your remark',
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    // Final Accept and Reject Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isApproving || _isRejecting) ? null : _handleAccept,
                            icon: _isApproving 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                  ),
                            label: Text(_isApproving ? 'Approving...' : 'Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isApproving || _isRejecting) ? null : _handleReject,
                            icon: _isRejecting 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.cancel,
                                    size: 16,
                                  ),
                            label: Text(_isRejecting ? 'Rejecting...' : 'Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData? icon;
    
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        borderColor = Colors.green.shade200;
        break;
      case 'pending':
        backgroundColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        borderColor = Colors.yellow.shade200;
        icon = Icons.refresh;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        borderColor = Colors.red.shade200;
        break;
      case 'under review':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        borderColor = Colors.blue.shade200;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        borderColor = Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }
}
