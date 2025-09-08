import 'package:flutter/material.dart';
import '../../action/action.dart';

class UniquePhoneCodeComponent extends StatefulWidget {
  const UniquePhoneCodeComponent({super.key});

  @override
  State<UniquePhoneCodeComponent> createState() => _UniquePhoneCodeComponentState();
}

class _UniquePhoneCodeComponentState extends State<UniquePhoneCodeComponent> {
  List<Map<String, dynamic>> _alternativePhones = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _editPhoneController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  bool _isEditing = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadAlternativePhones();
  }

  @override
  void dispose() {
    _editPhoneController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAlternativePhones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ActionService.getAlternativePhones();
      if (result['success']) {
        setState(() {
          _alternativePhones = List<Map<String, dynamic>>.from(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load unique codes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading unique codes: $e';
        _isLoading = false;
      });
    }
  }


  Future<void> _updateAlternativePhone(String id) async {
    if (_editPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a three-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate three-digit code
    final code = _editPhoneController.text.trim();
    if (code.length != 3 || !RegExp(r'^\d{3}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid three-digit code (000-999)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isEditing = true;
    });

    try {
      final result = await ActionService.updateAlternativePhone(id, code);
      if (result['success']) {
        _editPhoneController.clear();
        setState(() {
          _editingId = null;
        });
        _loadAlternativePhones();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unique code updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update unique code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _startEditing(Map<String, dynamic> phone) {
    setState(() {
      _editingId = phone['_id'];
      _editPhoneController.text = phone['number']?.toString() ?? '';
    });
    // Focus the text field after setting the text
    _editFocusNode.requestFocus();
  }

  void _cancelEditing() {
    _editFocusNode.unfocus();
    setState(() {
      _editingId = null;
      _editPhoneController.clear();
    });
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Invalid date';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildOTPInput() {
    final currentText = _editPhoneController.text;
    final digits = currentText.split('');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final digit = index < digits.length ? digits[index] : '';
        final isFocused = currentText.length == index;
        final hasDigit = digit.isNotEmpty;
        
        return GestureDetector(
          onTap: () {
            // Focus the TextField and move cursor to the tapped position
            _editFocusNode.requestFocus();
            _editPhoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: index),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            decoration: BoxDecoration(
              color: isFocused 
                  ? const Color(0xFFF97316).withOpacity(0.1)
                  : hasDigit
                      ? const Color(0xFFF97316).withOpacity(0.05)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused 
                    ? const Color(0xFFF97316)
                    : hasDigit
                        ? const Color(0xFFF97316).withOpacity(0.3)
                        : Colors.grey[300]!,
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: digit.isEmpty
                  ? Icon(
                      Icons.circle_outlined,
                      size: 8,
                      color: isFocused 
                          ? const Color(0xFFF97316)
                          : Colors.grey[400],
                    )
                  : Text(
                      digit,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isFocused 
                            ? const Color(0xFFF97316)
                            : const Color(0xFF333333),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOTPDisplay(String code) {
    final digits = code.split('');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final digit = index < digits.length ? digits[index] : '';
        return Container(
          width: 50,
          height: 50,
          margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF97316),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildPhoneCard(Map<String, dynamic> phone) {
    final isEditing = _editingId == phone['_id'];
    final code = phone['number']?.toString() ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF97316).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF97316).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isEditing
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Update Unique Phone Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter 3-digit code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _editPhoneController,
                      focusNode: _editFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF333333),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) {
                        // Only allow numeric input
                        if (value.length > 3) {
                          _editPhoneController.text = value.substring(0, 3);
                          _editPhoneController.selection = TextSelection.fromPosition(
                            TextPosition(offset: 3),
                          );
                        }
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.length == 3) {
                          _updateAlternativePhone(phone['_id']);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isEditing ? null : _cancelEditing,
                          child: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEditing || _editPhoneController.text.length != 3 
                              ? null 
                              : () => _updateAlternativePhone(phone['_id']),
                          child: _isEditing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Title
                  const Text(
                    'Unique Phone Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OTP Style Code Display
                  _buildOTPDisplay(code),
                  const SizedBox(height: 32),
                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startEditing(phone),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone List
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadAlternativePhones,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_alternativePhones.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[50]!,
                    const Color(0xFFF97316).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF97316).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // OTP-style empty boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Unique Codes Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unique three-digit codes will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _alternativePhones.length,
                itemBuilder: (context, index) {
                  return _buildPhoneCard(_alternativePhones[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
