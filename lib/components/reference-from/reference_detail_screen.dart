import 'package:flutter/material.dart';
import '../common/profile_photo_dialog.dart'; // Add this import

class ReferenceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> referenceData;

  const ReferenceDetailScreen({
    super.key,
    required this.referenceData,
  });

  // Helper getters for cleaner access to data
  String get name => referenceData['name'] ?? '';
  String get email => referenceData['email'] ?? '';
  String get phone => referenceData['phone'] ?? '';
  String get status => referenceData['status'] ?? '';
  String? get profilePic => referenceData['photo'] ?? referenceData['profilePic'];
  String get teacherCode => referenceData['teacherCode'] ?? 'N/A';
  String get createdAt => referenceData['createdAt'] != null 
      ? DateTime.parse(referenceData['createdAt']).toString().split(' ')[0]
      : '';
  String get secretaryRemark => referenceData['secretaryRemark'] ?? 'No remarks provided';
  String get details => referenceData['details'] ?? 'No details provided';
  String get remarks => referenceData['remarks'] ?? 'No remarks provided';
  String get reasonForForm => referenceData['reasonForForm'] ?? 'No reason provided';
  String get gurudevWhere => referenceData['gurudevWhere'] ?? 'No location provided';
  String get gurudevWhen => referenceData['gurudevWhen'] != null 
      ? DateTime.parse(referenceData['gurudevWhen']).toString().split(' ')[0]
      : 'No date provided';
  String get someoneElseWho => referenceData['someoneElseWho'] ?? 'No name provided';
  String get someoneElseWhere => referenceData['someoneElseWhere'] ?? 'No location provided';
  String get someoneElseContext => referenceData['someoneElseContext'] ?? 'No context provided';
  String get datesAtAshram => referenceData['datesAtAshram'] ?? 'No dates provided';
  List<String> get coursesTaught => referenceData['coursesTaught'] != null 
      ? List<String>.from(referenceData['coursesTaught'])
      : [];

  @override
  Widget build(BuildContext context) {
    // Debug logging to see the data structure
    print('ReferenceDetailScreen - referenceData: $referenceData');
    print('ReferenceDetailScreen - name: $name');
    print('ReferenceDetailScreen - email: $email');
    print('ReferenceDetailScreen - phone: $phone');
    print('ReferenceDetailScreen - status: $status');
    print('ReferenceDetailScreen - teacherCode: $teacherCode');
    print('ReferenceDetailScreen - createdAt: $createdAt');
    print('ReferenceDetailScreen - coursesTaught: $coursesTaught');
    print('ReferenceDetailScreen - reasonForForm: $reasonForForm');
    print('ReferenceDetailScreen - gurudevWhere: $gurudevWhere');
    print('ReferenceDetailScreen - gurudevWhen: $gurudevWhen');
    print('ReferenceDetailScreen - someoneElseWho: $someoneElseWho');
    print('ReferenceDetailScreen - someoneElseWhere: $someoneElseWhere');
    print('ReferenceDetailScreen - someoneElseContext: $someoneElseContext');
    print('ReferenceDetailScreen - datesAtAshram: $datesAtAshram');
    print('ReferenceDetailScreen - remarks: $remarks');
    print('ReferenceDetailScreen - secretaryRemark: $secretaryRemark');
    print('ReferenceDetailScreen - profilePic: $profilePic');
    print('ReferenceDetailScreen - photo field: ${referenceData['photo']}');
    print('ReferenceDetailScreen - profilePic field: ${referenceData['profilePic']}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reference Details',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Name and Email
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: profilePic != null && profilePic!.isNotEmpty 
                            ? () => _showProfilePhoto(context, profilePic!) 
                            : null,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: profilePic != null && profilePic!.isNotEmpty
                              ? NetworkImage(profilePic!)
                              : null,
                          child: profilePic == null || profilePic!.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBadge(status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Combined Information Card
              _buildInfoCard(
                'Reference Information',
                [
                  _buildInfoRow(Icons.info, 'Status', status),
                  _buildInfoRow(Icons.email, 'Email Address', email),
                  _buildInfoRow(Icons.phone, 'Phone Number', phone),
                  _buildInfoRow(Icons.calendar_today, 'Created Date', createdAt),
                  _buildInfoRow(Icons.person, 'Teacher Code', teacherCode),
                  _buildInfoRow(Icons.school, 'Teaching Details', details),
                  _buildInfoRow(Icons.book, 'Courses Taught', coursesTaught.isNotEmpty ? coursesTaught.join(', ') : 'No courses'),
                  _buildInfoRow(Icons.info, 'Reason for Form', reasonForForm),
                  _buildInfoRow(Icons.location_on, 'Gurudev Location', gurudevWhere),
                  _buildInfoRow(Icons.schedule, 'Gurudev Date', gurudevWhen),
                  _buildInfoRow(Icons.person_add, 'Someone Else Who', someoneElseWho),
                  _buildInfoRow(Icons.location_city, 'Someone Else Where', someoneElseWhere),
                  _buildInfoRow(Icons.chat, 'Someone Else Context', someoneElseContext),
                  _buildInfoRow(Icons.calendar_month, 'Dates at Ashram', datesAtAshram),
                  _buildInfoRow(Icons.note, 'Remarks', remarks),
                  _buildInfoRow(Icons.comment, 'Secretary Remarks', secretaryRemark),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Fixed width for labels like person card
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
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

  // Add this method to show profile photo dialog
  void _showProfilePhoto(BuildContext context, String imageUrl) {
    ProfilePhotoDialog.showWithErrorHandling(
      context,
      imageUrl: imageUrl,
      userName: name,
      description: "$name's profile photo",
    );
  }
}