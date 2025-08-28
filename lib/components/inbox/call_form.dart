import 'package:flutter/material.dart';

class CallForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onCall;
  final VoidCallback? onClose;

  const CallForm({
    Key? key,
    required this.appointment,
    this.onCall,
    this.onClose,
  }) : super(key: key);

  @override
  State<CallForm> createState() => _CallFormState();
}

class _CallFormState extends State<CallForm> {
  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getPhoneNumber() {
    // Check if this is a guest appointment first
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    if (appointmentType == 'guest' && guestInformation is Map<String, dynamic>) {
      final guestPhone = guestInformation['phoneNumber']?.toString();
      if (guestPhone != null && guestPhone.isNotEmpty) {
        return guestPhone;
      }
    }
    
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final mobileNumber = optional['mobileNumber'];
        if (mobileNumber is Map<String, dynamic>) {
          final countryCode = mobileNumber['countryCode']?.toString() ?? '';
          final number = mobileNumber['number']?.toString() ?? '';
          if (number.isNotEmpty) {
            return '$countryCode$number';
          }
        }
      }
    }
    
    // Fallback to regular phone fields
    final phoneData = widget.appointment['phoneNumber'];
    if (phoneData is Map<String, dynamic>) {
      final countryCode = phoneData['countryCode']?.toString() ?? '';
      final number = phoneData['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode $number';
      }
    }
    return phoneData?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact call options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call option
                InkWell(
                  onTap: () {
                    widget.onCall?.call();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Call ${_getAppointmentName()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_getPhoneNumber().isNotEmpty)
                                Text(
                                  _getPhoneNumber(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onCall?.call();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Call'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 