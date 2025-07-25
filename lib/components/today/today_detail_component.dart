import 'package:flutter/material.dart';

class TodayDetailComponent extends StatefulWidget {
  final String categoryTitle;
  final IconData categoryIcon;
  final int count;
  final Function(String)? onItemCompleted;
  final Function(String)? onItemUndone;

  const TodayDetailComponent({
    super.key,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.count,
    this.onItemCompleted,
    this.onItemUndone,
  });

  @override
  State<TodayDetailComponent> createState() => _TodayDetailComponentState();
}

class _TodayDetailComponentState extends State<TodayDetailComponent> {
  String selectedDropdownValue = 'A';
  List<int> completedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header section with icon and count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.categoryIcon,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.count} items',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items for ${widget.categoryTitle}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cards based on count
                  Expanded(
                    child: widget.count > 0 
                        ? ListView.builder(
                            itemCount: widget.count,
                            itemBuilder: (context, index) {
                              final itemNumber = index + 1;
                              // Skip completed items
                              if (completedItems.contains(itemNumber)) {
                                return const SizedBox.shrink();
                              }
                              return _buildItemCard(itemNumber);
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No items found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Items for ${widget.categoryTitle} will appear here when available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int itemNumber) {
    // Sample data for demonstration
    final List<Map<String, dynamic>> sampleData = [
      {
        'name': 'Divya - Testing',
        'designation': 'Developer',
        'time': '04:30 PM',
        'hasHomeIcon': true,
        'hasUserIcon': true,
        'userCount': 2,
        'assignee': 'KK',
      },
      {
        'name': 'Divya',
        'designation': 'tester',
        'time': '04:30 PM',
        'hasHomeIcon': true,
        'hasUserIcon': true,
        'userCount': 1,
        'assignee': 'MP',
      },
      {
        'name': 'avinash Choudhary',
        'designation': 'Devops',
        'time': '04:45 PM',
        'hasHomeIcon': false,
        'hasUserIcon': true,
        'userCount': 1,
        'assignee': '',
      },
    ];

    final data = sampleData[itemNumber % sampleData.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with profile and dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      data['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Designation
                    Text(
                      data['designation'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time, user count, and home icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data['time'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                                            // User count with icon and assignee
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['userCount']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (data['assignee'].isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['assignee'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                        const SizedBox(width: 12),
                        // Home icon (if present)
                        if (data['hasHomeIcon'])
                          Icon(
                            Icons.home,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Dropdown at top right corner
              PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() {
                    selectedDropdownValue = value;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedDropdownValue,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'A',
                    child: Text('A'),
                  ),
                  const PopupMenuItem(
                    value: 'O',
                    child: Text('O'),
                  ),
                  const PopupMenuItem(
                    value: 'A1',
                    child: Text('A1'),
                  ),
                  const PopupMenuItem(
                    value: 'A2',
                    child: Text('A2'),
                  ),
                  const PopupMenuItem(
                    value: 'A3',
                    child: Text('A3'),
                  ),
                  const PopupMenuItem(
                    value: 'R',
                    child: Text('R'),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
                      // Done button at bottom center with full width
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle done action for this specific card
                  _handleDoneAction(itemNumber);
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDoneAction(int itemNumber) {
    final itemId = '${widget.categoryTitle}_$itemNumber';
    
    setState(() {
      completedItems.add(itemNumber);
    });
    
    // Notify parent component
    widget.onItemCompleted?.call(itemId);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item $itemNumber moved to Done category!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 