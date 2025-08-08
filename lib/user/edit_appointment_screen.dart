import 'package:flutter/material.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import 'user_screen.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentData;

  const EditAppointmentScreen({
    super.key,
    this.appointmentData,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  String _selectedAppointmentType = 'myself';
  String _selectedTeacherStatus = 'no';
  String _selectedLocation = 'Bengaluru,India';
  String _selectedSecretary = 'None';
  final TextEditingController _purposeController = TextEditingController(text: 'Blessings');
  DateTime _fromDate = DateTime(2025, 8, 8);
  DateTime _toDate = DateTime(2025, 8, 11);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Appointment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Type Selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // slate-50 equivalent
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Appointment Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B), // slate-800 equivalent
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select who this appointment is for',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B), // slate-500 equivalent
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Radio Buttons
                  Column(
                    children: [
                      // Myself Option
                      _buildRadioOption(
                        value: 'myself',
                        title: 'Request appointment for Myself',
                        isSelected: _selectedAppointmentType == 'myself',
                        onTap: () {
                          setState(() {
                            _selectedAppointmentType = 'myself';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Guest Option
                      _buildRadioOption(
                        value: 'guest',
                        title: 'Request appointment for a Guest',
                        isSelected: _selectedAppointmentType == 'guest',
                        onTap: () {
                          setState(() {
                            _selectedAppointmentType = 'guest';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Personal Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937), // gray-800 equivalent
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your contact details (auto-filled from your profile)',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF71717A), // zinc-500 equivalent
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form Fields - Each on separate line
                Column(
                  children: [
                    _buildFormField(
                      label: 'Full Name',
                      value: 'Ram Tharun',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      label: 'Email Address',
                      value: 'ramtharun0720@gmail.com',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      label: 'Phone Number',
                      value: '+919347653480',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      label: 'Designation',
                      value: 'Tech Developer',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      label: 'Company/Organization',
                      value: 'Sumeru Digital',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildAOLTeacherSection(),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Appointment Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // slate-50 equivalent
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B), // slate-800 equivalent
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Provide details about your requested appointment',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B), // slate-500 equivalent
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Appointment Location
                  _buildDropdownField(
                    label: 'Appointment Location',
                    value: _selectedLocation,
                    isRequired: true,
                    onTap: () {
                      // TODO: Show location picker
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Secretary Selection
                  _buildSecretaryDropdown(),
                  const SizedBox(height: 12),
                  
                  // Purpose of Meeting
                  _buildPurposeField(),
                  const SizedBox(height: 12),
                  
                  // Attachment
                  _buildAttachmentField(),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range Section
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE2E8F0), // slate-200 equivalent
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferred Date Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B), // slate-800 equivalent
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select your preferred date range for the appointment',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF64748B), // slate-500 equivalent
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Fields
                        Column(
                          children: [
                            _buildDateField(
                              label: 'From Date',
                              date: _fromDate,
                              isRequired: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _fromDate = date;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Days Range Indicator
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0), // slate-200 equivalent
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${_toDate.difference(_fromDate).inDays + 1} Days Range',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569), // slate-600 equivalent
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDateField(
                              label: 'To Date',
                              date: _toDate,
                              isRequired: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate,
                                  firstDate: _fromDate,
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _toDate = date;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569), // slate-600 equivalent
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE2E8F0), // slate-200 equivalent
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155), // slate-700 equivalent
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF94A3B8), // slate-400 equivalent
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretaryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Have you been in touch with any secretary regarding your appointment?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569), // slate-600 equivalent
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            // TODO: Show secretary picker
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE2E8F0), // slate-200 equivalent
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)], // gray-300 to gray-400
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '—',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'None',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155), // slate-700 equivalent
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF94A3B8), // slate-400 equivalent
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Purpose of Meeting',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569), // slate-600 equivalent
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE2E8F0), // slate-200 equivalent
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _purposeController,
            maxLines: null,
            expands: false,
            decoration: const InputDecoration(
              hintText: 'Please describe the purpose of your meeting in detail',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8), // slate-400 equivalent
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155), // slate-700 equivalent
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Attachment',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569), // slate-600 equivalent
              ),
            ),
            Text(
              ' (Optional)',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF94A3B8), // slate-400 equivalent
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
                Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE2E8F0), // slate-200 equivalent
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)], // slate-100 to slate-200
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1), // slate-300 equivalent
                  ),
                ),
                child: const Icon(
                  Icons.attach_file,
                  size: 20,
                  color: Color(0xFF64748B), // slate-500 equivalent
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155), // slate-700 equivalent
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF, DOC, PPT up to 5MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF64748B), // slate-500 equivalent
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0), // slate-200 equivalent
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Choose File',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569), // slate-600 equivalent
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[date.weekday - 1];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569), // slate-600 equivalent
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFCBD5E1), // slate-300 equivalent
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF64748B), // slate-500 equivalent
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${date.day} ${_getMonthName(date.month)} ${date.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF334155), // slate-700 equivalent
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($dayName)',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B), // slate-500 equivalent
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildFormField({
    required String label,
    required String value,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3F3F46), // zinc-700 equivalent
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F5), // zinc-100 equivalent
            border: Border.all(
              color: const Color(0xFFE4E4E7), // zinc-200 equivalent
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF52525B), // zinc-600 equivalent
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAOLTeacherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AOL Teacher:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3F3F46), // zinc-700 equivalent
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTeacherRadioOption(
                value: 'no',
                title: 'No',
                isSelected: _selectedTeacherStatus == 'no',
                onTap: () {
                  setState(() {
                    _selectedTeacherStatus = 'no';
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTeacherRadioOption(
                value: 'part-time',
                title: 'Part-time',
                isSelected: _selectedTeacherStatus == 'part-time',
                onTap: () {
                  setState(() {
                    _selectedTeacherStatus = 'part-time';
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTeacherRadioOption(
                value: 'full-time',
                title: 'Full-time',
                isSelected: _selectedTeacherStatus == 'full-time',
                onTap: () {
                  setState(() {
                    _selectedTeacherStatus = 'full-time';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherRadioOption({
    required String value,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFECFDF5) // emerald-50 equivalent
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFBBF7D0) // emerald-200 equivalent
                : const Color(0xFFE4E4E7), // zinc-200 equivalent
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              // Radio Button
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF10B981) // emerald-500 equivalent
                        : const Color(0xFFD4D4D8), // zinc-300 equivalent
                    width: 2,
                  ),
                  color: isSelected 
                      ? const Color(0xFF10B981) // emerald-500 equivalent
                      : Colors.white,
                ),
                child: isSelected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? const Color(0xFF064E3B) // emerald-900 equivalent
                        : const Color(0xFF52525B), // zinc-700 equivalent
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFEF3C7) // orange-50 equivalent
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFDBA74) // orange-300 equivalent
                : const Color(0xFFE2E8F0), // slate-200 equivalent
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Radio Button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFF97316) // orange-500 equivalent
                        : const Color(0xFFCBD5E1), // slate-300 equivalent
                    width: 2,
                  ),
                  color: isSelected 
                      ? const Color(0xFFF97316) // orange-500 equivalent
                      : Colors.white,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? const Color(0xFF9A3412) // orange-800 equivalent
                        : const Color(0xFF475569), // slate-600 equivalent
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
