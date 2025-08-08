import 'package:flutter/material.dart';

class LocationBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  final String? selectedLocation;
  final Function(String?) onLocationSelected;
  final bool isLoading;

  const LocationBottomSheet({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: Colors.grey[300],
            height: 1,
          ),
          
          // Content
          Flexible(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading locations...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : locations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No locations available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          final locationName = location['name'] ?? 'Unknown Location';
                          final isSelected = selectedLocation == locationName;
                          
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.deepPurple.withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: isSelected ? Colors.deepPurple : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              locationName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.deepPurple : Colors.black87,
                              ),
                            ),
                            subtitle: location['address'] != null
                                ? Text(
                                    location['address'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.deepPurple,
                                    size: 24,
                                  )
                                : null,
                            onTap: () {
                              onLocationSelected(locationName);
                              Navigator.pop(context);
                            },
                            tileColor: isSelected 
                                ? Colors.deepPurple.withOpacity(0.05)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          );
                        },
                      ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
