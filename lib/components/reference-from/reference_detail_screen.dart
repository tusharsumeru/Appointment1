import 'package:flutter/material.dart';
import '../common/profile_photo_dialog.dart'; // Add this import

class ReferenceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> referenceData;

  const ReferenceDetailScreen({
    super.key,
    required this.referenceData,
  });

  // Helper getters for cleaner access to data
  String get name => referenceData['name'] ?? '';
  String get email => referenceData['email'] ?? '';
  String get phone => referenceData['phone'] ?? '';
  String get status => referenceData['status'] ?? '';
  String? get profilePic => referenceData['photo'] ?? referenceData['profilePic'];
  String get teacherCode => referenceData['teacherCode'] ?? 'No teacher code provided';
  String get createdAt => _formatDate(referenceData['createdAt'] ?? 'No date');
  String get secretaryRemark => referenceData['secretaryRemark'] ?? 'No remarks provided';
  String get details => (referenceData['details'] ?? '').isEmpty 
      ? 'No details provided' 
      : referenceData['details'];
  String get remarks => referenceData['remarks'] ?? 'No remarks provided';
  String get reasonForForm => referenceData['reasonForForm'] ?? 'No reason provided';
  String get gurudevWhere => referenceData['gurudevWhere'] ?? 'No location provided';
  String get gurudevWhen => _formatDate(referenceData['gurudevWhen'] ?? 'No date');
  String get someoneElseWho => referenceData['someoneElseWho'] ?? 'No name provided';
  String get someoneElseWhere => referenceData['someoneElseWhere'] ?? 'No location provided';
  String get someoneElseContext => referenceData['someoneElseContext'] ?? 'No context provided';
  String get datesAtAshram => referenceData['datesAtAshram'] ?? 'No dates provided';
  String get personalFeelingDetails => referenceData['personalFeelingDetails'] ?? '';
  List<Map<String, dynamic>> get gurudevEntries => referenceData['gurudevEntries'] != null 
      ? List<Map<String, dynamic>>.from(referenceData['gurudevEntries'])
      : [];
  List<String> get coursesTaught => referenceData['coursesTaught'] != null 
      ? List<String>.from(referenceData['coursesTaught'])
      : [];

  // Helper method to format date in IST
  String _formatDate(String dateString) {
    if (dateString == 'No date') return 'No date';
    
    try {
      // Parse ISO date string (UTC)
      DateTime utcDate = DateTime.parse(dateString);
      
      // Convert to IST (UTC + 5:30)
      DateTime istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      
      // Format to user-friendly format: "3 Sep 2025, 3:05 AM"
      List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      String day = istDate.day.toString();
      String month = months[istDate.month - 1];
      String year = istDate.year.toString();
      
      // Format time in IST
      String hour = istDate.hour.toString().padLeft(2, '0');
      String minute = istDate.minute.toString().padLeft(2, '0');
      String amPm = istDate.hour >= 12 ? 'PM' : 'AM';
      int displayHour = istDate.hour > 12 ? istDate.hour - 12 : (istDate.hour == 0 ? 12 : istDate.hour);
      
      return '$day $month $year, $displayHour:$minute $amPm';
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging to see the data structure
    print('ReferenceDetailScreen - referenceData: $referenceData');
    print('ReferenceDetailScreen - name: $name');
    print('ReferenceDetailScreen - email: $email');
    print('ReferenceDetailScreen - phone: $phone');
    print('ReferenceDetailScreen - status: $status');
    print('ReferenceDetailScreen - teacherCode: $teacherCode');
    print('ReferenceDetailScreen - createdAt: $createdAt');
    print('ReferenceDetailScreen - coursesTaught: $coursesTaught');
    print('ReferenceDetailScreen - reasonForForm: $reasonForForm');
    print('ReferenceDetailScreen - gurudevWhere: $gurudevWhere');
    print('ReferenceDetailScreen - gurudevWhen: $gurudevWhen');
    print('ReferenceDetailScreen - someoneElseWho: $someoneElseWho');
    print('ReferenceDetailScreen - someoneElseWhere: $someoneElseWhere');
    print('ReferenceDetailScreen - someoneElseContext: $someoneElseContext');
    print('ReferenceDetailScreen - datesAtAshram: $datesAtAshram');
    print('ReferenceDetailScreen - remarks: $remarks');
    print('ReferenceDetailScreen - secretaryRemark: $secretaryRemark');
    print('ReferenceDetailScreen - gurudevEntries: $gurudevEntries');
    print('ReferenceDetailScreen - gurudevEntries length: ${gurudevEntries.length}');
    print('ReferenceDetailScreen - profilePic: $profilePic');
    print('ReferenceDetailScreen - photo field: ${referenceData['photo']}');
    print('ReferenceDetailScreen - profilePic field: ${referenceData['profilePic']}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reference Details',
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
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), // p-4 sm:p-6 lg:p-8
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Grid Layout
                  _buildGridLayout(context),
                  const SizedBox(height: 24), // mb-6 lg:mb-8
                  
                  // Additional Details Section
                  _buildAdditionalDetailsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 1024;
        
        return isLargeScreen 
            ? _buildDesktopGrid(context)
            : _buildMobileGrid(context);
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Profile Picture and Action Buttons
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: profilePic != null && profilePic!.isNotEmpty 
                    ? () => _showProfilePhoto(context, profilePic!) 
                    : null,
                child: Container(
                  width: 256, // w-64 = 256px
                  height: 256,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profilePic != null && profilePic!.isNotEmpty
                        ? Image.network(
                            profilePic!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Status Badge
              Center(child: _buildStatusBadge(status)),
              const SizedBox(height: 16), // Reduced from 24 to 16
              // Action Buttons
              if (status.toLowerCase() == 'pending') ...[
                SizedBox(
                  width: 192, // max-w-48 = 192px
                  child: Column(
                    children: [
                      _buildActionButton(
                        'Approve',
                        Icons.check_circle,
                        const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)], // from-green-500 to-emerald-600
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        () {
                          // Handle approve action
                        },
                      ),
                      const SizedBox(height: 12), // gap-3
                      _buildActionButton(
                        'Reject',
                        Icons.cancel,
                        const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFE11D48)], // from-red-500 to-rose-600
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        () {
                          // Handle reject action
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32), // gap-6 lg:gap-8
        // Right Column - Name and Personal Info Cards
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Date Section
              Container(
                margin: const EdgeInsets.only(bottom: 24), // mb-4 lg:mb-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 36, // text-2xl sm:text-3xl lg:text-4xl
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B), // text-zinc-900
                      ),
                    ),
                    const SizedBox(height: 8), // mb-2 lg:mb-3
                    Text(
                      'Submitted on $createdAt',
                      style: const TextStyle(
                        fontSize: 20, // text-base sm:text-lg lg:text-xl
                        color: Color(0xFF71717A), // text-zinc-600
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Personal Information Cards
              _buildPersonalInfoCards(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileGrid(BuildContext context) {
    return Column(
      children: [
        // Profile Picture
        GestureDetector(
          onTap: profilePic != null && profilePic!.isNotEmpty 
              ? () => _showProfilePhoto(context, profilePic!) 
              : null,
          child: Container(
            width: 192, // w-48 = 192px
            height: 192,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: profilePic != null && profilePic!.isNotEmpty
                  ? Image.network(
                      profilePic!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Status Badge
        Center(child: _buildStatusBadge(status)),
        const SizedBox(height: 16), // Reduced from 24 to 16
        // Action Buttons
        if (status.toLowerCase() == 'pending') ...[
          SizedBox(
            width: 192,
            child: Column(
              children: [
                _buildActionButton(
                  'Approve',
                  Icons.check_circle,
                  const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  () {
                    // Handle approve action
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Reject',
                  Icons.cancel,
                  const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFE11D48)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  () {
                    // Handle reject action
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24), // Reduced from 32 to 24
        // Name and Date Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted on $createdAt',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF71717A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Personal Information Cards
        _buildPersonalInfoCards(),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, LinearGradient gradient, VoidCallback onPressed) {
    return Container(
      height: 32, // h-8
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8), // rounded-lg
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCards() {
    return Column(
      children: [
        _buildInfoCardRow(
          Icons.email,
          'Email',
          email,
          const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)], // from-blue-50 to-indigo-50
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          const Color(0xFF2563EB), // text-blue-600
          const Color(0xFFDBEAFE), // bg-blue-100
        ),
        const SizedBox(height: 16), // space-y-3 lg:space-y-4
        _buildInfoCardRow(
          Icons.phone,
          'Phone',
          phone,
          const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)], // from-green-50 to-emerald-50
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          const Color(0xFF059669), // text-green-600
          const Color(0xFFD1FAE5), // bg-green-100
        ),
        const SizedBox(height: 16),
        _buildInfoCardRow(
          Icons.badge,
          'Teacher Code',
          teacherCode,
          const LinearGradient(
            colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)], // from-purple-50 to-violet-50
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          const Color(0xFF7C3AED), // text-purple-600
          const Color(0xFFE9D5FF), // bg-purple-100
        ),
        const SizedBox(height: 16),
        _buildInfoCardRow(
          Icons.location_on,
          'Ashram Dates',
          datesAtAshram.isNotEmpty ? datesAtAshram : 'N/A',
          const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)], // from-orange-50 to-amber-50
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          const Color(0xFFEA580C), // text-orange-600
          const Color(0xFFFED7AA), // bg-orange-100
        ),
      ],
    );
  }

  Widget _buildInfoCardRow(IconData icon, String label, String value, LinearGradient gradient, Color iconColor, Color iconBgColor) {
    return Container(
      padding: const EdgeInsets.all(20), // p-3 lg:p-5
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: iconBgColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // p-2
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8), // rounded-lg
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20, // w-4 h-4 lg:w-5 lg:h-5
            ),
          ),
          const SizedBox(width: 16), // gap-3 lg:gap-4
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.5, // tracking-wide
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16, // text-sm lg:text-base
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937), // text-zinc-800
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Container(
      padding: const EdgeInsets.only(top: 24), // pt-6
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE4E4E7)), // border-t border-zinc-100
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // from-blue-500 to-purple-600
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 24, // text-2xl
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B), // text-zinc-900
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // mb-6
          
          // Courses Taught
          _buildDetailSection(
            'Courses Taught',
            Icons.book,
            coursesTaught.isNotEmpty ? coursesTaught.join(', ') : 'No courses specified',
            isList: coursesTaught.isNotEmpty,
          ),
          const SizedBox(height: 20),
          
          // Teaching Details
          _buildDetailSection(
            'Teaching Details',
            Icons.info,
            details.isNotEmpty ? details : 'No details provided',
          ),
          const SizedBox(height: 20),
          
          // Registration Reason
          _buildRegistrationReasonSection(),
          const SizedBox(height: 20),
          
          // Applicant Remarks
          _buildDetailSection(
            'Applicant Remarks',
            Icons.comment,
            remarks,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, String content, {bool isList = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF71717A)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // bg-zinc-50
            borderRadius: BorderRadius.circular(8),
          ),
          child: isList
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: coursesTaught.map((course) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Text(
                      course,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  )).toList(),
                )
              : Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF71717A),
                    height: 1.5,
                    fontStyle: content == 'No details provided' ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRegistrationReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, size: 16, color: const Color(0xFF71717A)),
            const SizedBox(width: 8),
            const Text(
              'Registration Reason',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gurudev told you section
              _buildReasonSubsection(
                'Gurudev told you:',
                gurudevEntries.isNotEmpty ? _buildGurudevEntries() : null,
              ),
              const SizedBox(height: 16),
              
              // Someone else told you section
              _buildReasonSubsection(
                'Someone else told you:',
                _buildSomeoneElseInfo(),
              ),
              const SizedBox(height: 16),
              
              // Personal feeling section
              _buildReasonSubsection(
                'Personal feeling/intuition:',
                _buildPersonalFeelingInfo(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSubsection(String title, Widget? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 8),
        if (content != null) content,
      ],
    );
  }

  Widget _buildGurudevEntries() {
    return Column(
      children: gurudevEntries.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> gurudevEntry = entry.value;
        String where = gurudevEntry['where'] ?? '';
        String when = gurudevEntry['when'] ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entry ${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${gurudevEntry['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHERE:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          where,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHEN:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          when,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSomeoneElseInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WHO:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  someoneElseWho.isNotEmpty ? someoneElseWho : 'Not specified',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WHERE:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  someoneElseWhere.isNotEmpty ? someoneElseWhere : 'Not specified',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalFeelingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAILS:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71717A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            personalFeelingDetails.isNotEmpty ? personalFeelingDetails : 'Not specified',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case 'under review':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.visibility;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to show profile photo dialog
  void _showProfilePhoto(BuildContext context, String imageUrl) {
    ProfilePhotoDialog.showWithErrorHandling(
      context,
      imageUrl: imageUrl,
      userName: name,
      description: "$name's profile photo",
    );
  }
}