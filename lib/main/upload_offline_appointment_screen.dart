import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import '../components/sidebar/sidebar_component.dart';
import 'upload_history_screen.dart'; // Added import for UploadHistoryScreen

class UploadOfflineAppointmentScreen extends StatefulWidget {
  const UploadOfflineAppointmentScreen({super.key});

  @override
  State<UploadOfflineAppointmentScreen> createState() => _UploadOfflineAppointmentScreenState();
}

class _UploadOfflineAppointmentScreenState extends State<UploadOfflineAppointmentScreen> {
  String? _selectedFileName;
  // PlatformFile? _selectedFile;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Not Started', 'Ongoing', 'Completed'];

  void _pickFile() async {
    // Show file type selection dialog
    String? selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select File Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel File (.xlsx)'),
                onTap: () => Navigator.pop(context, 'xlsx'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel File (.xls)'),
                onTap: () => Navigator.pop(context, 'xls'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('CSV File (.csv)'),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Text File (.txt)'),
                onTap: () => Navigator.pop(context, 'txt'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedType != null) {
      setState(() {
        _selectedFileName = 'offline_appointments.$selectedType';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selected: offline_appointments.$selectedType')),
      );
    }
  }

  void _uploadFile() {
    if (_selectedFileName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File uploaded successfully: $_selectedFileName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
    }
  }

  void _bulkSchedule() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select Date
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Select Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Select Time
                const Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: '--:--',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Options Checkboxes
                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('TBS/Req', style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text("Don't send Email/SMS", style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Send Arrival Time', style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Schedule Email & SMS Confirmation', style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Send VDS Email', style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Stay Available', style: TextStyle(fontSize: 14)),
                  value: false,
                  onChanged: (bool? value) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                
                // Select Venue
                const Text(
                  'Select Venue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Satsang Backstage',
                      isExpanded: true,
                      menuMaxHeight: 200,
                      items: const [
                        DropdownMenuItem(value: 'Satsang Backstage', child: Text('Satsang Backstage')),
                        DropdownMenuItem(value: 'Secretariat Office A1', child: Text('Secretariat Office A1')),
                        DropdownMenuItem(value: 'Special Enclosure - Shiva Temple', child: Text('Special Enclosure - Shiva Temple')),
                        DropdownMenuItem(value: 'Yoga School', child: Text('Yoga School')),
                        DropdownMenuItem(value: 'Radha Kunj', child: Text('Radha Kunj')),
                        DropdownMenuItem(value: 'Shiva Temple', child: Text('Shiva Temple')),
                        DropdownMenuItem(value: 'Gurukul', child: Text('Gurukul')),
                      ],
                      onChanged: (String? value) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bulk schedule saved successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadHistoryScreen()),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.deepPurple,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildValueCell(String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  final List<Map<String, String>> _dummyData = [
    {
      'uploadDate': '2024-07-01',
      'requestId': 'REQ123',
      'group': 'A',
      'name': 'John Doe',
      'totalPersons': '5',
      'requestedDate': '2024-07-02',
      'appointmentDate': '2024-07-05',
      'venue': 'Hall 1',
      'status': 'Completed',
    },
    {
      'uploadDate': '2024-07-03',
      'requestId': 'REQ124',
      'group': 'B',
      'name': 'Jane Smith',
      'totalPersons': '3',
      'requestedDate': '2024-07-04',
      'appointmentDate': '2024-07-06',
      'venue': 'Hall 2',
      'status': 'Ongoing',
    },
    {
      'uploadDate': '2024-07-05',
      'requestId': 'REQ125',
      'group': 'C',
      'name': 'Alice Brown',
      'totalPersons': '2',
      'requestedDate': '2024-07-06',
      'appointmentDate': '2024-07-07',
      'venue': 'Hall 3',
      'status': 'Not Started',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Offline Appointment'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
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
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // File upload section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Placeholder
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.file_upload,
                              size: 40,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileName ?? 'Click here to select a file from device',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // if (_selectedFile != null) ...[
                            //   const SizedBox(height: 4),
                            //   Text(
                            //     'Size: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       color: Colors.grey.shade500,
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _uploadFile,
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text(
                          'Upload',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bulk Schedule and History buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _bulkSchedule,
                            icon: const Icon(Icons.schedule, color: Colors.white),
                            label: const Text(
                              'Bulk Schedule',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showHistory,
                            icon: const Icon(Icons.history, color: Colors.white),
                            label: const Text(
                              'History',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search filter
                    Row(
                      children: [
                        const Text(
                          'Filter by: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFilter,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                items: _filterOptions.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedFilter = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Content area
            Expanded(
              child: ListView.builder(
                itemCount: _dummyData.length,
                itemBuilder: (context, index) {
                  final item = _dummyData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelValue('Upload Date', item['uploadDate'] ?? ''),
                            _buildLabelValue('Request ID', item['requestId'] ?? ''),
                            _buildLabelValue('Group', item['group'] ?? ''),
                            _buildLabelValue('Name', item['name'] ?? ''),
                            _buildLabelValue('Total Person(s)', item['totalPersons'] ?? ''),
                            _buildLabelValue('Requested Date', item['requestedDate'] ?? ''),
                            _buildLabelValue('Appointment Date', item['appointmentDate'] ?? ''),
                            _buildLabelValue('Venue', item['venue'] ?? ''),
                            _buildLabelValue('Status', item['status'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label + ':',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
                fontSize: 14,
              ),
            ),
          ),
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
      ),
    );
  }
} 