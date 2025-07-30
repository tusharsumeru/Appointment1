import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';

class UploadHistoryScreen extends StatefulWidget {
  const UploadHistoryScreen({super.key});

  @override
  State<UploadHistoryScreen> createState() => _UploadHistoryScreenState();
}

class _UploadHistoryScreenState extends State<UploadHistoryScreen> {
  final List<Map<String, String>> _historyData = [
    {
      'uploadDate': '2024-07-01',
      'uploadTime': '10:30 AM',
      'uploadedBy': 'John Doe',
      'location': 'Main Office',
    },
    {
      'uploadDate': '2024-07-02',
      'uploadTime': '02:15 PM',
      'uploadedBy': 'Jane Smith',
      'location': 'Branch Office A',
    },
    {
      'uploadDate': '2024-07-03',
      'uploadTime': '09:45 AM',
      'uploadedBy': 'Mike Johnson',
      'location': 'Remote Location',
    },
    {
      'uploadDate': '2024-07-04',
      'uploadTime': '11:20 AM',
      'uploadedBy': 'Sarah Wilson',
      'location': 'Main Office',
    },
    {
      'uploadDate': '2024-07-05',
      'uploadTime': '03:30 PM',
      'uploadedBy': 'David Brown',
      'location': 'Branch Office B',
    },
  ];

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'View all appointment history',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // History cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _historyData.length,
                itemBuilder: (context, index) {
                  final item = _historyData[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upload number
                            Text(
                              'Upload #${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Details
                            _buildLabelValue('Upload Date', item['uploadDate'] ?? ''),
                            _buildLabelValue('Upload Time', item['uploadTime'] ?? ''),
                            _buildLabelValue('Uploaded By', item['uploadedBy'] ?? ''),
                            _buildLabelValue('Location', item['location'] ?? ''),
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
} 