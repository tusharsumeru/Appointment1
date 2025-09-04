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
    
    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          color: widget.index % 2 == 0 ? Colors.white : Color(0xFFFFF3E0), // Alternating colors like person card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                         // Header with profile pic and name
             Row(
               children: [
                 // Profile Picture
                 GestureDetector(
                   onTap: profilePic != null ? () => _showProfilePhoto(context, profilePic!) : null,
                   child: CircleAvatar(
                     radius: 25,
                     backgroundColor: Colors.grey[200],
                     backgroundImage: profilePic != null
                         ? NetworkImage(profilePic!)
                         : null,
                     child: profilePic == null
                         ? Text(
                             name.isNotEmpty ? name[0].toUpperCase() : '?',
                             style: const TextStyle(
                               fontSize: 20,
                               fontWeight: FontWeight.bold,
                               color: Colors.deepOrange,
                             ),
                           )
                         : null,
                   ),
                 ),
                 const SizedBox(width: 12),
                 // Name
                 Expanded(
                   child: Text(
                     name,
                     style: const TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: Colors.black87,
                     ),
                   ),
                 ),
                 // Status Badge
                 _buildStatusBadge(status),
               ],
             ),
             const SizedBox(height: 16),
             // Email Row
             Row(
               children: [
                 Icon(
                   Icons.email,
                   size: 16,
                   color: Colors.grey[600],
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     email,
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey[600],
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             // Date Row
             Row(
               children: [
                 Icon(
                   Icons.calendar_today,
                   size: 16,
                   color: Colors.grey[600],
                 ),
                 const SizedBox(width: 8),
                 Text(
                   createdAt,
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.grey[600],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             // Phone Row
             Row(
               children: [
                 Icon(
                   Icons.phone,
                   size: 16,
                   color: Colors.grey[600],
                 ),
                 const SizedBox(width: 8),
                 Text(
                   phone,
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.grey[600],
                   ),
                 ),
               ],
             ),
            const SizedBox(height: 16),
                         // Actions Row
             SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: widget.onViewDetails,
                 icon: const Icon(
                   Icons.visibility,
                   size: 16,
                 ),
                 label: const Text('View Details'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                   padding: const EdgeInsets.symmetric(
                     vertical: 12,
                   ),
                 ),
               ),
             ),
             // Only show Approve/Reject buttons if status is pending
             if (status.toLowerCase() == 'pending') ...[
               const SizedBox(height: 22),
               
               // Show initial Approve/Reject buttons if remark section is not shown
               if (!_showRemarkSection) ...[
                 Row(
                   children: [
                     Expanded(
                       child: ElevatedButton.icon(
                         onPressed: _toggleRemarkSection,
                         icon: const Icon(
                           Icons.check,
                           size: 16,
                         ),
                         label: const Text('Approve'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.green,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                           padding: const EdgeInsets.symmetric(
                             vertical: 12,
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: ElevatedButton.icon(
                         onPressed: _toggleRemarkSection,
                         icon: const Icon(
                           Icons.close,
                           size: 16,
                         ),
                         label: const Text('Reject'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.red,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                           padding: const EdgeInsets.symmetric(
                             vertical: 12,
                           ),
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
                                 Icons.check,
                                 size: 16,
                               ),
                         label: Text(_isApproving ? 'Approving...' : 'Approve'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.green,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                           padding: const EdgeInsets.symmetric(
                             vertical: 12,
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(width: 12),
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
                                 Icons.close,
                                 size: 16,
                               ),
                         label: Text(_isRejecting ? 'Rejecting...' : 'Reject'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.red,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                           padding: const EdgeInsets.symmetric(
                             vertical: 12,
                           ),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'under review':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }
}
