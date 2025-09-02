import 'package:flutter/material.dart';
import '../../action/action.dart';

class ReferenceCard extends StatefulWidget {
  final Map<String, dynamic> referenceData;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStatusUpdated;

  const ReferenceCard({
    super.key,
    required this.referenceData,
    this.onViewDetails,
    this.onStatusUpdated,
  });

  @override
  State<ReferenceCard> createState() => _ReferenceCardState();
}

class _ReferenceCardState extends State<ReferenceCard> {
  bool _isApproving = false;
  bool _isRejecting = false;

  // Helper getters for easy access to data
  String get name => widget.referenceData['name'] ?? 'Unknown';
  String get email => widget.referenceData['email'] ?? 'No email';
  String get phone => widget.referenceData['phone'] ?? 'No phone';
  String get status => widget.referenceData['status'] ?? 'Unknown';
  String? get profilePic => widget.referenceData['photo'] ?? widget.referenceData['profilePic'];
  String get createdAt => widget.referenceData['createdAt'] ?? 'No date';
  String get formId => widget.referenceData['_id'] ?? widget.referenceData['id'] ?? '';

  // Handle accept action
  Future<void> _handleAccept() async {
    if (_isApproving || _isRejecting || formId.isEmpty) return;
    
    setState(() {
      _isApproving = true;
    });

    try {
      print('🔄 Calling updateReferenceFormStatus for formId: $formId');
      print('🔄 Status: Approved');
      print('🔄 Secretary remark: Approved by secretary');
      
      final result = await ActionService.updateReferenceFormStatus(
        formId: formId,
        status: 'Approved',
        secretaryRemark: 'Approved by secretary',
      );
      
      print('🔄 API Response: $result');

      if (result['success'] == true) {
        _showSuccessMessage('Reference form approved successfully!');
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
      print('🔄 Secretary remark: Rejected by secretary');
      
      final result = await ActionService.updateReferenceFormStatus(
        formId: formId,
        status: 'Rejected',
        secretaryRemark: 'Rejected by secretary',
      );
      
      print('🔄 API Response: $result');

      if (result['success'] == true) {
        _showSuccessMessage('Reference form rejected successfully!');
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
                 CircleAvatar(
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
                   backgroundColor: Colors.lightBlue,
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
               const SizedBox(height: 12),
               // Accept and Reject Buttons
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
}
