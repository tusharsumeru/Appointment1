import 'package:flutter/material.dart';

class UserAppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String status;
  final String userName;
  final String userTitle;
  final String company;
  final String? profilePhoto;
  final String appointmentDateRange;
  final int attendeesCount;
  final String? attendeePhoto;
  final String purpose;
  final String assignedTo;
  final String dateRange;
  final int daysCount;
  final String email;
  final String phone;
  final String location;
  final VoidCallback? onEditPressed;
  final Color? headerColor;

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
    this.attendeePhoto,
    required this.purpose,
    required this.assignedTo,
    required this.dateRange,
    required this.daysCount,
    required this.email,
    required this.phone,
    required this.location,
    this.onEditPressed,
    this.headerColor,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
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
                    child: profilePhoto != null
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
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                           Text(
                             'Appointment Attendees',
                             style: TextStyle(
                               fontSize: 14,
                               color: Colors.grey.shade600,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Row(
                             children: [
                               Text(
                                 '$attendeesCount Person',
                                 style: const TextStyle(
                                   fontSize: 14,
                                   color: Colors.black87,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                               const Spacer(),
                               if (attendeePhoto != null)
                                 Container(
                                   width: 24,
                                   height: 24,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     border: Border.all(
                                       color: Colors.grey.shade300,
                                       width: 1,
                                     ),
                                   ),
                                   child: ClipOval(
                                     child: Image.network(
                                       attendeePhoto!,
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
                             Text(
                               'Purpose of Meeting',
                               style: TextStyle(
                                 fontSize: 14,
                                 color: headerColor ?? Colors.deepPurple,
                                 fontWeight: FontWeight.w500,
                               ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Date: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                dateRange,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Range: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                dateRange.split(' to ').last,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                                 // Contact Details
                 const Text(
                   'Contact Details',
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                     color: Colors.black87,
                   ),
                   textAlign: TextAlign.left,
                 ),
                const SizedBox(height: 12),
                _buildContactRow(Icons.email, email),
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone, phone),
                const SizedBox(height: 8),
                _buildContactRow(Icons.location_on, location),
                const SizedBox(height: 16),

                                 // Edit Button
                 if (onEditPressed != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 16),
                     child: SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: onEditPressed,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: headerColor ?? Colors.deepPurple,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                           elevation: 2,
                         ),
                         child: const Text(
                           'Edit Details',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
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

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
} 