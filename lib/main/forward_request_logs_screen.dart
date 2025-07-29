import 'package:flutter/material.dart';

class ForwardRequestLogsScreen extends StatefulWidget {
  const ForwardRequestLogsScreen({super.key});

  @override
  State<ForwardRequestLogsScreen> createState() => _ForwardRequestLogsScreenState();
}

class _ForwardRequestLogsScreenState extends State<ForwardRequestLogsScreen> {
  String _currentSearchQuery = '';
  Map<String, dynamic> _currentFilters = {};
  String _selectedSecretary = 'All Secretaries';
  bool _isRefreshing = false;

  // Dummy data for forward request logs
  final List<Map<String, dynamic>> _logsData = [
    {
      'appointmentId': 'REQ001',
      'originalRequester': 'Rajesh Kumar',
      'forwardedTo': 'Secretary 1',
      'forwardedBy': 'Admin User',
      'forwardDate': '2024-01-15',
      'forwardTime': '10:30 AM',
      'status': 'Forwarded',
      'reason': 'Requires special handling',
      'priority': 'High',
    },
    {
      'appointmentId': 'REQ002',
      'originalRequester': 'Priya Sharma',
      'forwardedTo': 'Secretary 2',
      'forwardedBy': 'Manager',
      'forwardDate': '2024-01-14',
      'forwardTime': '2:15 PM',
      'status': 'In Progress',
      'reason': 'Additional documentation needed',
      'priority': 'Medium',
    },
    {
      'appointmentId': 'REQ003',
      'originalRequester': 'Amit Patel',
      'forwardedTo': 'Secretary 3',
      'forwardedBy': 'Supervisor',
      'forwardDate': '2024-01-13',
      'forwardTime': '9:45 AM',
      'status': 'Completed',
      'reason': 'Escalation required',
      'priority': 'Low',
    },
    {
      'appointmentId': 'REQ004',
      'originalRequester': 'Sneha Reddy',
      'forwardedTo': 'Secretary 1',
      'forwardedBy': 'Admin User',
      'forwardDate': '2024-01-12',
      'forwardTime': '11:20 AM',
      'status': 'Forwarded',
      'reason': 'Special approval needed',
      'priority': 'High',
    },
    {
      'appointmentId': 'REQ005',
      'originalRequester': 'Karthik Singh',
      'forwardedTo': 'Secretary 2',
      'forwardedBy': 'Manager',
      'forwardDate': '2024-01-11',
      'forwardTime': '3:30 PM',
      'status': 'Pending',
      'reason': 'Review required',
      'priority': 'Medium',
    },
  ];

  void _onSearchChanged(String query) {
    setState(() {
      _currentSearchQuery = query;
    });
    // Handle search logic here
    print('Search query: $query');
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
    });
    // Handle filter logic here
    print('Filters applied: $filters');
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'forwarded':
        return 'blue';
      case 'in progress':
        return 'orange';
      case 'completed':
        return 'green';
      case 'pending':
        return 'yellow';
      default:
        return 'grey';
    }
  }

  String _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }

  void _showSecretaryDropdown() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Secretary',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...['All Secretaries', 'Secretary 1', 'Secretary 2', 'Secretary 3', 'Secretary 4'].map((secretary) => ListTile(
                title: Text(secretary),
                onTap: () {
                  setState(() {
                    _selectedSecretary = secretary;
                  });
                  Navigator.pop(context);
                },
                trailing: _selectedSecretary == secretary
                    ? const Icon(Icons.check, color: Colors.deepPurple)
                    : null,
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isRefreshing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _currentSearchQuery = '';
      _selectedSecretary = 'All Secretaries';
      _currentFilters.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters cleared!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print the first log entry
    if (_logsData.isNotEmpty) {
      print('First log entry: ${_logsData[0]}');
      print('First log appointmentId: ${_logsData[0]['appointmentId']}');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward Request Logs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search forward request logs...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Secretary Dropdown and Action Buttons Row
                Row(
                  children: [
                    // Secretary Dropdown
                    Expanded(
                      child: GestureDetector(
                        onTap: _showSecretaryDropdown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.deepPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedSecretary,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Clear Filter Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearFilters,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.clear_all,
                                  color: Colors.deepPurple,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Refresh Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isRefreshing ? null : _refreshData,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: _isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Logs List
                Expanded(
                  child: ListView.builder(
                    itemCount: _logsData.length,
                    itemBuilder: (context, index) {
                      final log = _logsData[index];
                      print('Debug - log data: $log'); // Debug print
                      print('Debug - appointmentId: ${log['appointmentId']}'); // Debug print
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Appointment ID
                              Text(
                                'Appointment ID: ${log['appointmentId'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Request Details
                              _buildInfoRow('Forwarded To', log['forwardedTo']),
                              const SizedBox(height: 8),
                              _buildInfoRow('Time', log['forwardTime']),
                              const SizedBox(height: 8),
                              _buildInfoRow('Secretary Name', log['forwardedTo']),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
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
    );
  }
} 