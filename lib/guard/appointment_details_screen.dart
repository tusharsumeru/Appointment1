import 'package:flutter/material.dart';
import '../action/action.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  
  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic>? appointmentData;
  bool isLoading = true;
  String? errorMessage;
  
  // New state variables for Accept/Reject functionality
  bool showCheckboxes = false;
  Set<String> selectedUsers = {};
  String? actionType; // 'accept' or 'reject'

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final result = await ActionService.getAppointmentById(widget.appointmentId);
      
      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load appointment details: $e';
        isLoading = false;
      });
    }
  }

  void _showAcceptRejectAllDialog(String action) {
    setState(() {
      actionType = action;
      showCheckboxes = true;
      selectedUsers.clear();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (selectedUsers.contains(userId)) {
        selectedUsers.remove(userId);
      } else {
        selectedUsers.add(userId);
      }
    });
  }

  void _selectAllUsers() {
    setState(() {
      selectedUsers.clear();
      // Add main user
      if (appointmentData?['createdBy'] != null) {
        final mainUserId = appointmentData!['createdBy']['id'] ?? 'main_user';
        selectedUsers.add(mainUserId);
      }
      // Add accompanying users
      if (appointmentData?['accompanyUsers']?['users'] != null) {
        for (var user in appointmentData!['accompanyUsers']['users']) {
          final userId = user['id'] ?? 'accompanying_${user.hashCode}';
          selectedUsers.add(userId);
        }
      }
    });
  }

  void _deselectAllUsers() {
    setState(() {
      selectedUsers.clear();
    });
  }

  void _confirmAction() {
    // TODO: Implement the actual accept/reject logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${actionType?.toUpperCase()} action for ${selectedUsers.length} users'),
        backgroundColor: actionType == 'accept' ? Colors.green : Colors.red,
      ),
    );
    
    setState(() {
      showCheckboxes = false;
      selectedUsers.clear();
      actionType = null;
    });
  }

  void _cancelAction() {
    setState(() {
      showCheckboxes = false;
      selectedUsers.clear();
      actionType = null;
    });
  }

  void _showImageModal(String imageUrl, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen image
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 200,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              // Close button
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleIndividualAction(String userId, String userName, String action) {
    // TODO: Implement individual accept/reject logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action for $userName'),
        backgroundColor: action == 'Accept' ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a237e)),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAppointmentDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Appointment ID: ${appointmentData?['appointmentId'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${appointmentData?['appointmentStatus']?['status'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
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
                      const SizedBox(height: 20),

                      // Accept All / Reject All Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAcceptRejectAllDialog('accept'),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAcceptRejectAllDialog('reject'),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Reject All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Checkboxes Section (shown when Accept All/Reject All is clicked)
                      if (showCheckboxes) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: actionType == 'accept' ? Colors.green : Colors.red,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    actionType == 'accept' ? Icons.check_circle : Icons.cancel,
                                    color: actionType == 'accept' ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${actionType?.toUpperCase()} All Users',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: actionType == 'accept' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Select All / Deselect All buttons
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _selectAllUsers,
                                    child: const Text('Select All'),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: _deselectAllUsers,
                                    child: const Text('Deselect All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Main User Checkbox
                              if (appointmentData?['createdBy'] != null)
                                _buildUserCheckbox(
                                  appointmentData!['createdBy']['id'] ?? 'main_user',
                                  appointmentData!['createdBy']['fullName'] ?? 'Main User',
                                  appointmentData!['createdBy']['profilePhoto'],
                                  isMainUser: true,
                                ),
                              
                              // Accompanying Users Checkboxes
                              if (appointmentData?['accompanyUsers']?['users'] != null)
                                ...(appointmentData!['accompanyUsers']['users'] as List).map((user) =>
                                  _buildUserCheckbox(
                                    user['id'] ?? 'accompanying_${user.hashCode}',
                                    user['fullName'] ?? 'Accompanying User',
                                    user['profilePhotoUrl'],
                                    isMainUser: false,
                                  ),
                                ).toList(),
                              
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: selectedUsers.isNotEmpty ? _confirmAction : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: actionType == 'accept' ? Colors.green : Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('${actionType?.toUpperCase()} Selected (${selectedUsers.length})'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _cancelAction,
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Main Visitor Information
                      _buildVisitorCard(
                        title: 'Main Visitor',
                        visitorData: {
                          'name': appointmentData?['createdBy']?['fullName'] ?? 'N/A',
                          'phone': _formatPhoneNumber(appointmentData?['createdBy']?['phoneNumber']),
                          'email': appointmentData?['email'] ?? 'N/A',
                          'profilePhoto': appointmentData?['profilePhoto'],
                          'accompanyingCount': appointmentData?['accompanyUsers']?['numberOfUsers'] ?? 0,
                          'id': appointmentData?['createdBy']?['id'],
                        },
                      ),
                      const SizedBox(height: 16),

                      // Individual Accompanying User Cards
                      if (appointmentData?['accompanyUsers'] != null && 
                          appointmentData?['accompanyUsers']?['users'] != null &&
                          (appointmentData?['accompanyUsers']?['users'] as List).isNotEmpty)
                        ...(appointmentData!['accompanyUsers']['users'] as List).map((user) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildIndividualAccompanyingUserCard(user),
                          ),
                        ).toList(),

                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF1a237e),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'N/A';
    try {
      final date = DateTime.parse(time.toString());
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time.toString();
    }
  }

  String _formatPhoneNumber(dynamic phoneData) {
    if (phoneData == null) return 'N/A';
    try {
      final countryCode = phoneData['countryCode'] ?? '';
      final number = phoneData['number'] ?? '';
      return '$countryCode$number';
    } catch (e) {
      return phoneData.toString();
    }
  }

  String _formatScheduledDate(dynamic scheduledDateTime) {
    if (scheduledDateTime == null || scheduledDateTime['date'] == null) return 'N/A';
    try {
      final date = DateTime.parse(scheduledDateTime['date'].toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatScheduledTime(dynamic scheduledDateTime) {
    if (scheduledDateTime == null || scheduledDateTime['time'] == null) return 'N/A';
    return scheduledDateTime['time'].toString();
  }

  String _formatPreferredDateRange(dynamic preferredDateRange) {
    if (preferredDateRange == null) return 'N/A';
    try {
      final fromDate = DateTime.parse(preferredDateRange['fromDate'].toString());
      final toDate = DateTime.parse(preferredDateRange['toDate'].toString());
      return '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatCommunicationPreferences(dynamic preferences) {
    if (preferences == null || preferences.isEmpty) return 'None specified';
    try {
      if (preferences is List) {
        return preferences.join(', ');
      }
      return preferences.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVisitorCard({
    required String title,
    required Map<String, dynamic> visitorData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: const Color(0xFF1a237e),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo (Bigger)
              GestureDetector(
                onTap: () {
                  if (visitorData['profilePhoto'] != null) {
                    _showImageModal(visitorData['profilePhoto'], visitorData['name']);
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1a237e).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: visitorData['profilePhoto'] != null
                        ? Image.network(
                            visitorData['profilePhoto'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1a237e).withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF1a237e),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF1a237e).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF1a237e),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Visitor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitorData['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.phone, visitorData['phone']),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.email, visitorData['email']),
                    const SizedBox(height: 8),
                    // Accompanying Users Count
                    if (visitorData['accompanyingCount'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a237e).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1a237e),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.group,
                              size: 16,
                              color: Color(0xFF1a237e),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${visitorData['accompanyingCount']} Accompanying',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1a237e),
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
          const SizedBox(height: 16),
          // Individual Accept/Reject Buttons for Main Visitor
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleIndividualAction(
                    visitorData['id'] ?? '',
                    visitorData['name'],
                    'Accept',
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleIndividualAction(
                    visitorData['id'] ?? '',
                    visitorData['name'],
                    'Reject',
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCheckbox(String userId, String userName, String? profilePhoto, {required bool isMainUser}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: selectedUsers.contains(userId),
            onChanged: (value) => _toggleUserSelection(userId),
            activeColor: actionType == 'accept' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          // Profile Photo
          GestureDetector(
            onTap: () {
              if (profilePhoto != null) {
                _showImageModal(profilePhoto, userName);
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1a237e).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: profilePhoto != null
                    ? Image.network(
                        profilePhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1a237e).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 25,
                              color: Color(0xFF1a237e),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1a237e).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 25,
                          color: Color(0xFF1a237e),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  isMainUser ? 'Main Visitor' : 'Accompanying User',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualAccompanyingUserCard(Map<String, dynamic> user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: const Color(0xFF1a237e),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Accompanying User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo (Same size as main user)
              GestureDetector(
                onTap: () {
                  if (user['profilePhotoUrl'] != null) {
                    _showImageModal(user['profilePhotoUrl'], user['fullName'] ?? 'User');
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1a237e).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: user['profilePhotoUrl'] != null
                        ? Image.network(
                            user['profilePhotoUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1a237e).withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF1a237e),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF1a237e).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF1a237e),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['fullName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Age
                    if (user['age'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.cake,
                            size: 16,
                            color: Color(0xFF666666),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Age: ${user['age']} years',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Individual Accept/Reject Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleIndividualAction(
                    user['id'] ?? '',
                    user['fullName'] ?? 'User',
                    'Accept',
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleIndividualAction(
                    user['id'] ?? '',
                    user['fullName'] ?? 'User',
                    'Reject',
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 