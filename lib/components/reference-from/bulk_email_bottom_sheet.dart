import 'package:flutter/material.dart';

class BulkEmailBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> referenceForms;
  final Future<void> Function(List<Map<String, dynamic>> selectedForms, String? message)? onSendBulkEmail;

  const BulkEmailBottomSheet({
    super.key,
    required this.referenceForms,
    this.onSendBulkEmail,
  });

  @override
  State<BulkEmailBottomSheet> createState() => _BulkEmailBottomSheetState();
}

class _BulkEmailBottomSheetState extends State<BulkEmailBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  Set<String> _selectedFormIds = {};
  List<Map<String, dynamic>> _approvedForms = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Filter approved forms
    _approvedForms = widget.referenceForms
        .where((form) => form['status']?.toString().toLowerCase() == 'approved')
        .toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectAllApproved() {
    setState(() {
      // Filter out forms with null or empty IDs and create unique identifiers
      _selectedFormIds = _approvedForms
          .where((form) => form['id'] != null && form['id'].toString().isNotEmpty)
          .map((form) => form['id'].toString())
          .toSet();
      
      // If no valid IDs, use index-based selection as fallback
      if (_selectedFormIds.isEmpty) {
        _selectedFormIds = List.generate(_approvedForms.length, (index) => index.toString()).toSet();
      }
      
      // Debug print
      print('🔍 Total approved forms: ${_approvedForms.length}');
      print('🔍 Selected form IDs: $_selectedFormIds');
      print('🔍 Selected forms count: ${_selectedForms.length}');
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFormIds.clear();
    });
  }

  void _toggleSelection(String formId) {
    setState(() {
      if (_selectedFormIds.contains(formId)) {
        _selectedFormIds.remove(formId);
      } else {
        _selectedFormIds.add(formId);
      }
    });
  }

  void _toggleSelectionByForm(Map<String, dynamic> form) {
    setState(() {
      String formId;
      if (form['id'] != null && form['id'].toString().isNotEmpty) {
        formId = form['id'].toString();
      } else {
        // Use index as fallback
        formId = _approvedForms.indexOf(form).toString();
      }
      
      if (_selectedFormIds.contains(formId)) {
        _selectedFormIds.remove(formId);
      } else {
        _selectedFormIds.add(formId);
      }
    });
  }

  List<Map<String, dynamic>> get _selectedForms {
    return _approvedForms.where((form) {
      // Check if form has valid ID
      if (form['id'] != null && form['id'].toString().isNotEmpty) {
        return _selectedFormIds.contains(form['id'].toString());
      } else {
        // Fallback to index-based selection
        final index = _approvedForms.indexOf(form);
        return _selectedFormIds.contains(index.toString());
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar for drag gesture
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Send Bulk Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send email to ${_selectedFormIds.length} selected approved applicants',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selection Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected: ${_selectedFormIds.length} of ${_approvedForms.length} approved forms',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _selectAllApproved,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Select All Approved',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _deselectAll,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Deselect All',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected Users Grid
                  if (_selectedFormIds.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _selectedForms.length,
                          itemBuilder: (context, index) {
                            final form = _selectedForms[index];
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (form['name'] ?? 'U')[0].toString().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Name and Email
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            form['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Flexible(
                                          child: Text(
                                            form['email'] ?? 'No email',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Remove button
                                  GestureDetector(
                                    onTap: () => _toggleSelectionByForm(form),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.red.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Email Message
                  const Text(
                    'Email Message (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add a custom message to include in the email...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      filled: false,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_selectedFormIds.isEmpty || _isSending) ? null : () async {
                            print('🚀 Send button clicked, starting bulk email process...');
                            
                            // Check if at least one form is selected
                            if (_selectedForms.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select at least one form"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isSending = true;
                            });

                            try {
                              if (widget.onSendBulkEmail != null) {
                                print('📧 Calling onSendBulkEmail callback...');
                                await widget.onSendBulkEmail!(
                                  _selectedForms,
                                  _messageController.text.trim().isEmpty 
                                      ? null 
                                      : _messageController.text.trim(),
                                );
                                print('✅ onSendBulkEmail callback completed successfully');
                                
                                // Close the bottom sheet after successful completion
                                if (mounted) {
                                  print('🚪 Closing bottom sheet...');
                                  Navigator.of(context).pop();
                                }
                              } else {
                                print('❌ onSendBulkEmail callback is null');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Bulk email functionality not available"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Handle error if needed
                              print('❌ Error in bulk email: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to send bulk email: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSending = false;
                                });
                                print('🔄 Reset loading state');
                              }
                            }
                          },
                          icon: _isSending 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.mail, size: 16),
                          label: Text(_isSending 
                              ? 'Sending...' 
                              : 'Send to ${_selectedFormIds.length} Recipients'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSending ? Colors.grey.shade600 : Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Add bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
