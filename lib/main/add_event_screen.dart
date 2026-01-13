import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../action/action.dart';
import '../components/sidebar/sidebar_component.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _eventPlaceController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _fromTimeController = TextEditingController();
  final _toDateController = TextEditingController();
  final _toTimeController = TextEditingController();
  final _detailsController = TextEditingController();
  final _remarksController = TextEditingController();
  final _peopleController = TextEditingController(text: '1');

  DateTime? _selectedFromDate;
  TimeOfDay? _selectedFromTime;
  DateTime? _selectedToDate;
  TimeOfDay? _selectedToTime;
  int _numberOfPeople = 1;
  File? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventPlaceController.dispose();
    _fromDateController.dispose();
    _fromTimeController.dispose();
    _toDateController.dispose();
    _toTimeController.dispose();
    _detailsController.dispose();
    _remarksController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (isFrom) {
          _selectedFromDate = picked;
          _fromDateController.text = formatted;
        } else {
          _selectedToDate = picked;
          _toDateController.text = formatted;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isFrom) {
          _selectedFromTime = picked;
          _fromTimeController.text = formatted;
        } else {
          _selectedToTime = picked;
          _toTimeController.text = formatted;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _updatePeopleFromText() {
    final val = int.tryParse(_peopleController.text.trim());
    if (val == null || val < 1) {
      setState(() {
        _numberOfPeople = 1;
        _peopleController.text = '1';
      });
    } else {
      setState(() {
        _numberOfPeople = val;
      });
    }
  }

  Future<void> _submit() async {
    _updatePeopleFromText();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFromDate == null ||
        _selectedFromTime == null ||
        _selectedToDate == null ||
        _selectedToTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To date/time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fromDateTime = DateTime(
      _selectedFromDate!.year,
      _selectedFromDate!.month,
      _selectedFromDate!.day,
      _selectedFromTime!.hour,
      _selectedFromTime!.minute,
    );
    final toDateTime = DateTime(
      _selectedToDate!.year,
      _selectedToDate!.month,
      _selectedToDate!.day,
      _selectedToTime!.hour,
      _selectedToTime!.minute,
    );

    if (!toDateTime.isAfter(fromDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date/time must be after start date/time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ActionService.createEvent(
        eventName: _eventNameController.text.trim(),
        eventFromDateTime: fromDateTime.toIso8601String(),
        eventToDateTime: toDateTime.toIso8601String(),
        eventLocation: _eventPlaceController.text.trim(),
        eventDescription: _detailsController.text.trim(),
        eventImageFile: _selectedImage,
        eventCapacity: _numberOfPeople,
        secretaryNotes: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Event created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to create event',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Event Information',
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
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Event Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Event Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Fill in the details about your event',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Event Name',
                          controller: _eventNameController,
                          hint: 'Enter event name',
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'Event Place',
                          controller: _eventPlaceController,
                          hint: 'Enter event place',
                          required: true,
                        ),
                        const SizedBox(height: 12),

                        // From date/time
                        _buildDateTimeRow(
                          label: 'Event From Date and Time',
                          dateController: _fromDateController,
                          timeController: _fromTimeController,
                          onDateTap: () => _pickDate(isFrom: true),
                          onTimeTap: () => _pickTime(isFrom: true),
                        ),
                        const SizedBox(height: 12),

                        // To date/time
                        _buildDateTimeRow(
                          label: 'Event To Date and Time',
                          dateController: _toDateController,
                          timeController: _toTimeController,
                          onDateTap: () => _pickDate(isFrom: false),
                          onTimeTap: () => _pickTime(isFrom: false),
                        ),
                        const SizedBox(height: 12),

                        // Image
                        _buildImagePicker(),
                        const SizedBox(height: 12),

                        // Number of people
                        _buildPeoplePicker(),
                        const SizedBox(height: 12),

                        // Details
                        _buildTextArea(
                          label: 'Details of Events',
                          controller: _detailsController,
                          hint: 'Provide details about the event',
                          required: true,
                        ),
                        const SizedBox(height: 12),

                        // Remarks
                        _buildTextArea(
                          label: 'Special Remarks (Optional)',
                          controller: _remarksController,
                          hint: 'Any special remarks or additional information',
                          required: false,
                        ),
                        const SizedBox(height: 16),

                        Divider(color: const Color(0xFFE5E7EB)),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Submit Request',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: _inputDecoration(hint),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, true),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onDateTap,
                child: InputDecorator(
                  decoration: _inputDecoration('Select date'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateController.text.isEmpty
                                ? 'Select date'
                                : dateController.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: onTimeTap,
                decoration: _inputDecoration('Time').copyWith(
                  prefixIcon: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Event Image', false),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text(
                'Choose Image',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedImage != null
                    ? _selectedImage!.path.split('/').last
                    : 'No file chosen',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeoplePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Number of People', true),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton(
              onPressed: _numberOfPeople > 1
                  ? () {
                      setState(() {
                        _numberOfPeople--;
                        _peopleController.text = _numberOfPeople.toString();
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: TextFormField(
                controller: _peopleController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(''),
                onChanged: (_) => _updatePeopleFromText(),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 1) return 'Invalid';
                  return null;
                },
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _numberOfPeople++;
                  _peopleController.text = _numberOfPeople.toString();
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text, bool required) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9CA3AF),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5F5)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}


