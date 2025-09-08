import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool get _isGuestAppointment =>
      widget.appointment['appointmentType']?.toString() == 'guest';

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
            final combined = (countryCode + number).replaceAll(' ', '').replaceAll('+', '');
            return combined.isNotEmpty ? '+$combined' : '';
          }
        }
      }
    }
    
    // Fallback to regular phone fields
    final phoneData = widget.appointment['phoneNumber'];
    if (phoneData is Map<String, dynamic>) {
      final cc = phoneData['countryCode']?.toString() ?? '';
      final num = phoneData['number']?.toString() ?? '';
      if (num.isNotEmpty) {
        final combined = (cc + num).replaceAll(' ', '').replaceAll('+', '');
        return combined.isNotEmpty ? '+$combined' : '';
      }
    }
    final asString = phoneData?.toString() ?? '';
    if (asString.isNotEmpty) {
      final clean = asString.replaceAll(RegExp(r"\s+"), '').replaceAll('+', '');
      return clean.isNotEmpty ? '+$clean' : '';
    }
    return '';
  }

  String _formatPhone(dynamic phone) {
    String normalize(String input) {
      final clean = input.replaceAll(RegExp(r"\s+"), '').replaceAll('+', '');
      if (clean.isEmpty) return '';
      return '+$clean';
    }
    if (phone is Map<String, dynamic>) {
      final cc = (phone['countryCode']?.toString() ?? '').replaceAll(' ', '');
      final num = (phone['number']?.toString() ?? '').replaceAll(' ', '');
      if (num.isNotEmpty) {
        final combined = (cc + num).replaceAll('+', '');
        return combined.isNotEmpty ? '+$combined' : '';
      }
      return '';
    }
    if (phone is String) return normalize(phone);
    return '';
  }

  List<Map<String, String>> _getGuestPhoneOptions() {
    final List<Map<String, String>> phones = [];
    final guestInformation = widget.appointment['guestInformation'];

    // Guest primary phone
    if (guestInformation is Map<String, dynamic>) {
      final guestName = guestInformation['fullName']?.toString() ?? _getAppointmentName();
      // Common shapes
      final direct = _formatPhone(guestInformation['phoneNumber']);
      if (direct.isNotEmpty) {
        phones.add({'label': 'Guest', 'number': direct, 'name': guestName});
      }

      // Reference person phone (try multiple likely shapes)
      final reference = guestInformation['referencePerson'] ?? guestInformation['reference'] ?? {};
      String refNumber = '';
      String refName = '';
      if (reference is Map<String, dynamic>) {
        refName = reference['name']?.toString() ?? reference['fullName']?.toString() ?? '';
        refNumber = _formatPhone(reference['phoneNumber']);
        if (refNumber.isEmpty) {
          refNumber = _formatPhone(reference['mobileNumber']);
        }
        if (refNumber.isEmpty) {
          refNumber = _formatPhone(reference['phone']);
        }
      }
      // Alternative direct fields
      if (refNumber.isEmpty) {
        refNumber = _formatPhone(guestInformation['referencePhone']);
      }
      if (refNumber.isEmpty) {
        // Sometimes reference is provided under referenceFrom
        final refFrom = guestInformation['referenceFrom'];
        if (refFrom is Map<String, dynamic>) {
          refNumber = _formatPhone(refFrom['phoneNumber'] ?? refFrom['mobileNumber']);
          if (refName.isEmpty) {
            refName = refFrom['name']?.toString() ?? refFrom['fullName']?.toString() ?? '';
          }
        }
      }
      if (refNumber.isNotEmpty) {
        phones.add({'label': 'Reference', 'number': refNumber, 'name': refName});
      }
    }

    // Also check root-level guest/reference fields (some payloads use these)
    if (phones.where((e) => e['label'] == 'Guest').isEmpty) {
      final guestRoot = _formatPhone(widget.appointment['phoneNumber']);
      if (guestRoot.isNotEmpty) {
        final guestName = widget.appointment['guestInformation']?['fullName']?.toString() ?? _getAppointmentName();
        phones.add({'label': 'Guest', 'number': guestRoot, 'name': guestName});
      }
    }

    // Root-level reference person object
    if (phones.where((e) => e['label'] == 'Reference').isEmpty) {
      final referencePerson = widget.appointment['referencePerson'];
      if (referencePerson is Map<String, dynamic>) {
        var refRoot = _formatPhone(referencePerson['phoneNumber'])
            .isNotEmpty ? _formatPhone(referencePerson['phoneNumber']) : '';
        if (refRoot.isEmpty) refRoot = _formatPhone(referencePerson['mobileNumber']);
        if (refRoot.isEmpty) refRoot = _formatPhone(referencePerson['phone']);
        if (refRoot.isNotEmpty) {
          final refName = referencePerson['name']?.toString() ?? referencePerson['fullName']?.toString() ?? '';
          phones.add({'label': 'Reference', 'number': refRoot, 'name': refName});
        }
      }
    }

    // Root-level simple reference phone fields
    if (phones.where((e) => e['label'] == 'Reference').isEmpty) {
      final candidates = [
        widget.appointment['referencePhoneNumber'],
        widget.appointment['referencePhone'],
        widget.appointment['refPhone'],
        widget.appointment['contactPhone'],
      ];
      for (final c in candidates) {
        final num = _formatPhone(c);
        if (num.isNotEmpty) {
          final refName = widget.appointment['referencePerson']?['name']?.toString() ??
              widget.appointment['referencePerson']?['fullName']?.toString() ?? 'Reference';
          phones.add({'label': 'Reference', 'number': num, 'name': refName});
          break;
        }
      }
    }

    // Fallback: if nothing found, use _getPhoneNumber
    if (phones.isEmpty) {
      final num = _getPhoneNumber();
      if (num.isNotEmpty) phones.add({'label': 'Call', 'number': num});
    }
    return phones;
  }

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
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
                if (_isGuestAppointment) ...[
                  // Show multiple options for guest appointments
                  ..._getGuestPhoneOptions().map((entry) {
                    final label = entry['label'] ?? 'Call';
                    final number = entry['number'] ?? '';
                    final name = (entry['name']?.isNotEmpty == true)
                        ? entry['name']!
                        : _getAppointmentName();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          _makePhoneCall(number);
                          Navigator.pop(context);
                          widget.onCall?.call();
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
                                      '$name (${label})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (number.isNotEmpty)
                                      Text(
                                        number,
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
                    );
                  }).toList(),
                ] else ...[
                  // Default single call option
                  InkWell(
                    onTap: () {
                      final number = _getPhoneNumber();
                      if (number.isNotEmpty) {
                        _makePhoneCall(number);
                      }
                      Navigator.pop(context);
                      widget.onCall?.call();
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
                      // Default to guest primary or general number
                      final options = _isGuestAppointment ? _getGuestPhoneOptions() : [];
                      final number = _isGuestAppointment
                          ? (options.isNotEmpty ? options.first['number'] ?? '' : '')
                          : _getPhoneNumber();
                      if (number.isNotEmpty) {
                        _makePhoneCall(number);
                      }
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