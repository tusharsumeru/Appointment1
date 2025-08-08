import 'package:flutter/material.dart';
import '../../user/darshan_photos_screen.dart';

class UserAppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String status;
  final String userName;
  final String userTitle;
  final String company;
  final String? profilePhoto;
  final String appointmentDateRange;
  final int attendeesCount;
  final List<String>? attendeePhotos;
  final String purpose;
  final String assignedTo;
  final String dateRange;
  final int daysCount;
  final String email;
  final String phone;
  final String location;
  final VoidCallback? onEditPressed;
  final Color? headerColor;
  final Map<String, dynamic>? appointmentData;

  const UserAppointmentCard({
    super.key,
    required this.appointmentId,
    required this.status,
    required this.userName,
    required this.userTitle,
    required this.company,
    this.profilePhoto,
    required this.appointmentDateRange,
    required this.attendeesCount,
    this.attendeePhotos,
    required this.purpose,
    required this.assignedTo,
    required this.dateRange,
    required this.daysCount,
    required this.email,
    required this.phone,
    required this.location,
    this.onEditPressed,
    this.headerColor,
    this.appointmentData,
  });



  @override
  Widget build(BuildContext context) {
    // Check if this is a guest appointment
    final isGuestAppointment = _isGuestAppointment();
    final guestInfo = _getGuestInfo();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and appointment ID
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.lightBlue.shade50,
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(
                               color: Colors.lightBlue.shade200,
                               width: 1,
                             ),
                           ),
                           child: Text(
                             status,
                             style: TextStyle(
                               color: Colors.blue.shade600,
                               fontSize: 12,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ),
                         if (isGuestAppointment) ...[
                           const SizedBox(width: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: Colors.orange.shade100,
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(
                                 color: Colors.orange.shade300,
                                 width: 1,
                               ),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(
                                   Icons.person_add,
                                   size: 16,
                                   color: Colors.orange.shade700,
                                 ),
                                 const SizedBox(width: 4),
                                 Text(
                                   'GUEST',
                                   style: TextStyle(
                                     color: Colors.orange.shade700,
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ],
                     ),
                     Text(
                       appointmentId,
                       style: TextStyle(
                         color: Colors.grey.shade500,
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ],
                 ),
              ),

              // User Information
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: isGuestAppointment && guestInfo['photo'] != null
                            ? Image.network(
                                guestInfo['photo']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : profilePhoto != null
                                ? Image.network(
                                    profilePhoto!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuestAppointment ? guestInfo['name'] ?? 'Guest' : userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isGuestAppointment) ...[
                            if (guestInfo['designation'] != null && guestInfo['designation']!.isNotEmpty)
                              Text(
                                guestInfo['designation']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (guestInfo['company'] != null && guestInfo['company']!.isNotEmpty)
                              Text(
                                guestInfo['company']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (guestInfo['email'] != null && guestInfo['email']!.isNotEmpty)
                              Text(
                                guestInfo['email']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ] else ...[
                            Text(
                              userTitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Appointment Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // View Darshan Photos Section
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (appointmentData != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DarshanPhotosScreen(
                                    appointmentId: appointmentId,
                                    appointmentData: appointmentData!,
                                  ),
                                ),
                              );
                            } else {
                              // Fallback if appointmentData is not available
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DarshanPhotosScreen(
                                    appointmentId: appointmentId,
                                    appointmentData: {
                                      'profilePhoto': profilePhoto,
                                      'createdBy': {'fullName': userName},
                                      'accompanyUsers': {
                                        'users': attendeePhotos?.map((photo) => {
                                          'profilePhotoUrl': photo,
                                          'fullName': 'User',
                                        }).toList() ?? [],
                                      },
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'View Darshan Photos with Gurudev',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointment Date
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Appointment Date',
                      appointmentDateRange,
                    ),
                    const SizedBox(height: 12),

                    // Appointment Attendees
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Appointment Attendees',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '$attendeesCount Person${attendeesCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (attendeePhotos != null && attendeePhotos!.isNotEmpty)
                                    Container(
                                      width: (attendeePhotos!.length * 16.0) + 8.0,
                                      height: 24,
                                      child: Stack(
                                        children: attendeePhotos!.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final photoUrl = entry.value;
                                          return Positioned(
                                            left: index * 16.0,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipOval(
                                                child: Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade200,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Purpose of Meeting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (headerColor ?? Colors.deepPurple).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (headerColor ?? Colors.deepPurple).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 20,
                            color: headerColor ?? Colors.deepPurple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Purpose of Meeting',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: headerColor ?? Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  purpose,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (headerColor ?? Colors.deepPurple).withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assignment and Date Range
                    _buildDetailRow(
                      Icons.person,
                      'Assigned to:',
                      assignedTo,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Date: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  dateRange,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$daysCount Days',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                                         // Edit Button
                     if (onEditPressed != null)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 16),
                         child: SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             onPressed: _isScheduled() ? null : onEditPressed,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: _isScheduled() 
                                   ? Colors.grey.shade400 
                                   : (headerColor ?? Colors.deepPurple),
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               elevation: _isScheduled() ? 0 : 2,
                             ),
                             child: Text(
                               _isScheduled() ? 'Edit' : 'Edit Details',
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ),
                         ),
                       ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  // Check if this is a guest appointment
  bool _isGuestAppointment() {
    if (appointmentData == null) return false;
    
    final appointmentType = appointmentData!['appointmentType']?.toString().toLowerCase();
    final appointmentFor = appointmentData!['appointmentFor'];
    
    return appointmentType == 'guest' || 
           (appointmentFor != null && appointmentFor['type']?.toString().toLowerCase() == 'guest');
  }

  // Extract guest information from appointment data
  Map<String, String?> _getGuestInfo() {
    if (appointmentData == null) return {};
    
    final guestInformation = appointmentData!['guestInformation'];
    if (guestInformation == null || guestInformation is! Map<String, dynamic>) {
      return {};
    }
    
    return {
      'name': guestInformation['fullName']?.toString(),
      'email': guestInformation['emailId']?.toString(),
      'designation': guestInformation['designation']?.toString(),
      'company': guestInformation['company']?.toString(),
      'location': guestInformation['location']?.toString(),
      'photo': guestInformation['profilePhotoUrl']?.toString(),
    };
  }

  // Check if appointment is scheduled (has scheduled date/time)
  bool _isScheduled() {
    if (appointmentData == null) return false;
    
    final scheduledDateTime = appointmentData!['scheduledDateTime'];
    if (scheduledDateTime != null) {
      final scheduledDate = scheduledDateTime['date'];
      return scheduledDate != null && scheduledDate.toString().isNotEmpty;
    }
    
    return false;
  }
} 