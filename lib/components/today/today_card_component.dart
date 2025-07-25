import 'package:flutter/material.dart';
import 'today_detail_component.dart';

class TodayCardComponent extends StatefulWidget {
  const TodayCardComponent({super.key});

  @override
  State<TodayCardComponent> createState() => _TodayCardComponentState();
}

class _TodayCardComponentState extends State<TodayCardComponent> {
  // Track completed items across all categories
  static final Set<String> completedItems = <String>{};
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Morning:',
      'count': 3,
      'icon': Icons.wb_sunny,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'Evening:',
      'count': 1,
      'icon': Icons.wb_sunny_outlined,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'Night:',
      'count': 4,
      'icon': Icons.nightlight_round,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'TBS/Req:',
      'count': 2,
      'icon': Icons.person,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'Done:',
      'count': completedItems.length,
      'icon': Icons.check_circle,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'Satsang Backstage:',
      'count': 3,
      'icon': Icons.music_note,
      'iconColor': Colors.deepPurple,
    },
    {
      'title': 'Gurukul:',
      'count': 1,
      'icon': Icons.school,
      'iconColor': Colors.deepPurple,
    },
  ];

  Widget _buildDoneDetailScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Done'),
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
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completedItems.length} completed items',
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
          
          // Completed items list
          Expanded(
            child: completedItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No completed items yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: completedItems.length,
                    itemBuilder: (context, index) {
                      final itemId = completedItems.elementAt(index);
                      return _buildCompletedItemCard(itemId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedItemCard(String itemId) {
    // Parse itemId to get category and item number
    final parts = itemId.split('_');
    final category = parts[0];
    final itemNumber = parts[1];

    // Sample data for demonstration (re-used from TodayDetailComponent for consistency)
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
    final data = sampleData[int.parse(itemNumber) % sampleData.length]; // Use itemNumber for data selection

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'], // Display name from sample data
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['designation'], // Display designation
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              // Completed status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Undo button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  completedItems.remove(itemId);
                  // Update Done category count
                  _categories[4]['count'] = completedItems.length;
                });

                // Show undo message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item restored to $category!'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Undo',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _categories.map((category) {
        return _buildCategoryRow(category);
      }).toList(),
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
      child: GestureDetector(
        onTap: () {
          if (category['title'] == 'Done:') {
            // Show completed items with undo functionality
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _buildDoneDetailScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TodayDetailComponent(
                  categoryTitle: category['title'],
                  categoryIcon: category['icon'],
                  count: category['count'],
                  onItemCompleted: (String itemId) {
                    setState(() {
                      completedItems.add(itemId);
                      // Update Done category count
                      _categories[4]['count'] = completedItems.length;
                    });
                  },
                  onItemUndone: (String itemId) {
                    setState(() {
                      completedItems.remove(itemId);
                      // Update Done category count
                      _categories[4]['count'] = completedItems.length;
                    });
                  },
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: category['iconColor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category['icon'],
                color: category['iconColor'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Title
            Expanded(
              child: Text(
                category['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            
            // Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${category['count']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
} 