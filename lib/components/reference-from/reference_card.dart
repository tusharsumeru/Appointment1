import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../action/action.dart';
import '../common/profile_photo_dialog.dart'; // Add this import

class ReferenceCard extends StatefulWidget {
  final Map<String, dynamic> referenceData;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStatusUpdated;
  final VoidCallback? onDelete; // Add delete callback
  final int index; // Add index parameter for alternating colors

  const ReferenceCard({
    super.key,
    required this.referenceData,
    this.onViewDetails,
    this.onStatusUpdated,
    this.onDelete, // Add delete callback
    required this.index, // Add index parameter
  });

  @override
  State<ReferenceCard> createState() => _ReferenceCardState();
}

class _ReferenceCardState extends State<ReferenceCard> {
  bool _isApproving = false;
  bool _isRejecting = false;
  bool _sendEmail = true;
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

  // Show action bottom sheet for approve/reject
  void _showActionBottomSheet(String action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Icon(
                    action == 'approve' ? Icons.check_circle : Icons.cancel,
                    color: action == 'approve' ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    action == 'approve' ? 'Approve Reference Form' : 'Reject Reference Form',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reference form for: $name',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Secretary Remark Text Field
              const Text(
                'Secretary Remark (optional):',
                style: TextStyle(
                  fontSize: 16,
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
                    color: Colors.grey[500],
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              
              // Send email checkbox
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _sendEmail,
                      onChanged: (val) {
                        setState(() {
                          _sendEmail = val ?? true;
                        });
                      },
                      activeColor: Colors.blue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.mail_outline, size: 20, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Send email notification to applicant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isApproving || _isRejecting) ? null : () => _handleAction(action),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action == 'approve' ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isApproving || _isRejecting) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Icon(
                              action == 'approve' ? Icons.check_circle : Icons.cancel,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _isApproving 
                                ? 'Approving...' 
                                : _isRejecting 
                                    ? 'Rejecting...' 
                                    : action == 'approve' 
                                        ? 'Approve' 
                                        : 'Reject',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Handle approve/reject action
  Future<void> _handleAction(String action) async {
    if (_isApproving || _isRejecting || formId.isEmpty) return;
    
    setState(() {
      if (action == 'approve') {
        _isApproving = true;
      } else {
        _isRejecting = true;
      }
    });

    try {
      print('🔄 Calling updateReferenceFormStatus for formId: $formId');
      print('🔄 Status: ${action == 'approve' ? 'Approved' : 'Rejected'}');
      print('🔄 Secretary remark: ${_remarkController.text.trim()}');
      
      final result = await ActionService.updateReferenceFormStatus(
        formId: formId,
        status: action == 'approve' ? 'Approved' : 'Rejected',
        secretaryRemark: _remarkController.text.trim().isNotEmpty 
            ? _remarkController.text.trim() 
            : action == 'approve' 
                ? 'Approved by secretary' 
                : 'Rejected by secretary',
        sendEmailNotification: _sendEmail,
      );
      
      print('🔄 API Response: $result');

      if (result['success'] == true) {
        // Close bottom sheet
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Reference form ${action}d successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Trigger refresh to fetch updated data immediately
        widget.onStatusUpdated?.call();
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to ${action} reference form');
      }
    } catch (e) {
      _showErrorMessage('Error ${action}ing reference form: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
          _isRejecting = false;
        });
      }
    }
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
                const SizedBox(height: 8),
                // Delete Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                    ),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      foregroundColor: Colors.red.shade600,
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showActionBottomSheet('approve'),
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
                          onPressed: () => _showActionBottomSheet('reject'),
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
