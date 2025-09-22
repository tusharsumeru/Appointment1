import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
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
  final String? appointmentAttachment;

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
    this.appointmentAttachment,
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
                     GestureDetector(
                       onTap: () {
                         Clipboard.setData(ClipboardData(text: appointmentId));
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Row(
                               children: [
                                 const Icon(
                                   Icons.copy,
                                   color: Colors.white,
                                   size: 20,
                                 ),
                                 const SizedBox(width: 8),
                                 Text('Appointment ID copied: $appointmentId'),
                               ],
                             ),
                             backgroundColor: Colors.green,
                             duration: const Duration(seconds: 2),
                             behavior: SnackBarBehavior.floating,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8),
                             ),
                           ),
                         );
                       },
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text(
                             appointmentId,
                             style: TextStyle(
                               color: Colors.grey.shade500,
                               fontSize: 14,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(width: 4),
                           Icon(
                             Icons.copy,
                             size: 16,
                             color: Colors.grey.shade400,
                           ),
                         ],
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
                            (() {
                              final des = guestInfo['designation'] ?? '';
                              final comp = guestInfo['company'] ?? '';
                              final hasDes = des.isNotEmpty;
                              final hasComp = comp.isNotEmpty;
                              final line = hasDes && hasComp
                                  ? '$des at $comp'
                                  : (hasDes ? des : (hasComp ? comp : ''));
                              if (line.isEmpty) return const SizedBox.shrink();
                              return Text(
                                line,
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            })(),
                            if (guestInfo['email'] != null && guestInfo['email']!.isNotEmpty)
                              Text(
                                guestInfo['email']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ] else ...[
                            (() {
                              final des = userTitle;
                              final comp = company;
                              final hasDes = des.isNotEmpty;
                              final hasComp = comp.isNotEmpty;
                              final line = hasDes && hasComp
                                  ? '$des at $comp'
                                  : (hasDes ? des : (hasComp ? comp : ''));
                              return Text(
                                line,
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            })(),
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
                    
                    // Show TBS/REQ or Venue Label if applicable
                    if (_shouldShowSpecialLabel()) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        _getSpecialLabelIcon(),
                        _getSpecialLabelLabel(),
                        _getSpecialLabelText(),
                      ),
                    ],
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
                                  if (attendeesCount <= 10)
                                    Container(
                                      width: (attendeesCount * 16.0) + 8.0,
                                      height: 24,
                                      child: Stack(
                                        children: List.generate(attendeesCount, (index) {
                                          final attendeeName = _getAttendeeName(index);
                                          final hasPhoto = attendeePhotos != null && 
                                                          index < attendeePhotos!.length && 
                                                          attendeePhotos![index].isNotEmpty;
                                          final photoUrl = hasPhoto ? attendeePhotos![index] : null;
                                          
                                          return Positioned(
                                            left: index * 16.0,
                                              child: GestureDetector(
                                                onTap: () => hasPhoto 
                                                    ? _showImageModal(context, photoUrl!, attendeeName)
                                                    : _showPlaceholderModal(context, attendeeName),
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
                                                  child: hasPhoto
                                                      ? ClipOval(
                                                          child: Image.network(
                                                            photoUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return _buildPlaceholderCircle(name: attendeeName);
                                                            },
                                                          ),
                                                        )
                                                      : _buildPlaceholderCircle(name: attendeeName),
                                                ),
                                              ),
                                          );
                                        }),
                                      ),
                                    )
                                  else if (attendeePhotos != null && attendeePhotos!.isNotEmpty)
                                    Container(
                                      width: (attendeePhotos!.length * 16.0) + 8.0,
                                      height: 24,
                                      child: Stack(
                                        children: attendeePhotos!.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final photoUrl = entry.value;
                                          final attendeeName = _getAttendeeName(index);
                                          
                                          return Positioned(
                                            left: index * 16.0,
                                            child: GestureDetector(
                                              onTap: () => _showImageModal(context, photoUrl, attendeeName),
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
                                                      return _buildPlaceholderCircle(name: attendeeName);
                                                    },
                                                  ),
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
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: _buildPlaceholderCircle(name: 'User'),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade50.withOpacity(0.5),
                            Colors.yellow.shade50.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade100.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Purpose of Meeting',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  purpose,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Attachments Section - Only show if attachment exists
                    if (appointmentAttachment != null && appointmentAttachment!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              // Open the attachment URL
                              print('🔄 Attachment URL clicked: $appointmentAttachment');
                              _openAttachmentUrl(context, appointmentAttachment!);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
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
                                            'Attachments',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Click to view attachment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
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
                                   : (headerColor ?? const Color(0xFFF97316)),
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

  // Check if we should show special label (TBS/REQ or Venue Label)
  bool _shouldShowSpecialLabel() {
    if (appointmentData == null) return false;
    
    // Check communication preferences for TBS/REQ
    final communicationPreferences = appointmentData!['communicationPreferences'];
    if (communicationPreferences != null && communicationPreferences is List) {
      for (var pref in communicationPreferences) {
        final prefString = pref.toString().toLowerCase();
        if (prefString.contains('tbs') || prefString.contains('req')) {
          return true;
        }
      }
    }
    
    // Check venue label for special venues
    final scheduledDateTime = appointmentData!['scheduledDateTime'];
    if (scheduledDateTime != null && scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null) {
        final lowerVenueLabel = venueLabel.toLowerCase();
        if (lowerVenueLabel.contains('satsang backstage') || 
            lowerVenueLabel.contains('pooja backstage') || 
            lowerVenueLabel.contains('gurukul')) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Get the special label label text (for the left side)
  String _getSpecialLabelLabel() {
    if (appointmentData == null) return '';
    
    // Check communication preferences for TBS/REQ
    final communicationPreferences = appointmentData!['communicationPreferences'];
    if (communicationPreferences != null && communicationPreferences is List) {
      for (var pref in communicationPreferences) {
        final prefString = pref.toString().toLowerCase();
        if (prefString.contains('tbs') || prefString.contains('req')) {
          return 'Type:';
        }
      }
    }
    
    // Check venue label for special venues
    final scheduledDateTime = appointmentData!['scheduledDateTime'];
    if (scheduledDateTime != null && scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null) {
        final lowerVenueLabel = venueLabel.toLowerCase();
        if (lowerVenueLabel.contains('satsang backstage') || 
            lowerVenueLabel.contains('pooja backstage') || 
            lowerVenueLabel.contains('gurukul')) {
          return 'Status:';
        }
      }
    }
    
    return '';
  }

  // Get the special label text
  String _getSpecialLabelText() {
    if (appointmentData == null) return '';
    
    // Check communication preferences for TBS/REQ
    final communicationPreferences = appointmentData!['communicationPreferences'];
    if (communicationPreferences != null && communicationPreferences is List) {
      for (var pref in communicationPreferences) {
        final prefString = pref.toString().toLowerCase();
        if (prefString.contains('tbs') || prefString.contains('req')) {
          return 'TBS/REQ';
        }
      }
    }
    
    // Check venue label for special venues
    final scheduledDateTime = appointmentData!['scheduledDateTime'];
    if (scheduledDateTime != null && scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null) {
        final lowerVenueLabel = venueLabel.toLowerCase();
        if (lowerVenueLabel.contains('satsang backstage')) {
          return 'Satsang Backstage';
        } else if (lowerVenueLabel.contains('pooja backstage')) {
          return 'Pooja Backstage';
        } else if (lowerVenueLabel.contains('gurukul')) {
          return 'Gurukul';
        }
      }
    }
    
    return '';
  }

  // Get the special label icon
  IconData _getSpecialLabelIcon() {
    if (appointmentData == null) return Icons.info;
    
    // Check communication preferences for TBS/REQ
    final communicationPreferences = appointmentData!['communicationPreferences'];
    if (communicationPreferences != null && communicationPreferences is List) {
      for (var pref in communicationPreferences) {
        final prefString = pref.toString().toLowerCase();
        if (prefString.contains('tbs') || prefString.contains('req')) {
          return Icons.schedule;
        }
      }
    }
    
    // Check venue label for special venues
    final scheduledDateTime = appointmentData!['scheduledDateTime'];
    if (scheduledDateTime != null && scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null) {
        final lowerVenueLabel = venueLabel.toLowerCase();
        if (lowerVenueLabel.contains('satsang backstage') || 
            lowerVenueLabel.contains('pooja backstage') || 
            lowerVenueLabel.contains('gurukul')) {
          return Icons.schedule;
        }
      }
    }
    
    return Icons.info;
  }


  // Open attachment URL in browser
  Future<void> _openAttachmentUrl(BuildContext context, String url) async {
    try {
      // Clean and validate the URL
      String cleanUrl = url.trim();
      
      // Add protocol if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      print('🔄 Attempting to open URL: $cleanUrl');
      
      final Uri uri = Uri.parse(cleanUrl);
      
      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(uri);
      print('🔄 Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        print('🔄 URL launched successfully: $launched');
        
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open attachment in browser'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error if URL cannot be launched
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open attachment URL: $cleanUrl'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('🔄 Error opening attachment URL: $e');
      // Show error if there's an exception
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening attachment: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Get attendee name based on index
  String _getAttendeeName(int index) {
    if (appointmentData == null) return 'User ${index + 1}';
    
    try {
      // Check if this is a guest appointment
      final appointmentType = appointmentData!['appointmentType']?.toString().toLowerCase();
      final appointmentFor = appointmentData!['appointmentFor'];
      final isGuestAppointment = appointmentType == 'guest' || 
                                 (appointmentFor != null && appointmentFor['type']?.toString().toLowerCase() == 'guest');
      
      if (isGuestAppointment) {
        // For guest appointments: first photo is guest, rest are accompanying users
        if (index == 0) {
          // Guest name
          final guestInformation = appointmentData!['guestInformation'];
          if (guestInformation != null && guestInformation is Map<String, dynamic>) {
            return guestInformation['fullName']?.toString() ?? 'Guest';
          }
          return 'Guest';
        } else {
          // Accompanying user name
          final accompanyUsers = appointmentData!['accompanyUsers'];
          if (accompanyUsers != null && accompanyUsers['users'] != null) {
            final List<dynamic> users = accompanyUsers['users'];
            final userIndex = index - 1; // Subtract 1 because index 0 is guest
            if (userIndex < users.length) {
              final user = users[userIndex];
              if (user is Map<String, dynamic>) {
                return user['fullName']?.toString() ?? 'User ${index + 1}';
              }
            }
          }
          return 'User ${index + 1}';
        }
      } else {
        // For regular appointments: first photo is main user, rest are accompanying users
        if (index == 0) {
          // Main user name
          return appointmentData!['createdBy']?['fullName']?.toString() ?? userName;
        } else {
          // Accompanying user name
          final accompanyUsers = appointmentData!['accompanyUsers'];
          if (accompanyUsers != null && accompanyUsers['users'] != null) {
            final List<dynamic> users = accompanyUsers['users'];
            final userIndex = index - 1; // Subtract 1 because index 0 is main user
            if (userIndex < users.length) {
              final user = users[userIndex];
              if (user is Map<String, dynamic>) {
                return user['fullName']?.toString() ?? 'User ${index + 1}';
              }
            }
          }
          return 'User ${index + 1}';
        }
      }
    } catch (e) {
      return 'User ${index + 1}';
    }
  }

  // Build placeholder circle for missing attendee photos
  Widget _buildPlaceholderCircle({String? name}) {
    String displayText = '';
    if (name != null && name.isNotEmpty) {
      // Get first letter of the name, handling multiple words
      final words = name.trim().split(' ');
      if (words.isNotEmpty) {
        displayText = words.first[0].toUpperCase();
      }
    }
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF97316), // Orange color
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.0, // Reduce line height to prevent overflow
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Show placeholder modal for attendees without photos
  void _showPlaceholderModal(BuildContext context, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Placeholder Circle
                  Container(
                    width: 128,
                    height: 128,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF97316), // Orange color
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Show image modal
  void _showImageModal(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image
                  Container(
                    width: 128,
                    height: 128,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}