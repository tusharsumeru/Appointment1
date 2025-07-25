class Appointment {
  final String id;
  final String imageUrl;
  final String name;
  final String role;
  final String date;
  final String time;
  final String dateRange;
  final int attendeeCount;
  final String assignedTo;
  final bool isStarred;
  final String phoneNumber;
  final List<Assignee> availableAssignees;
  final String status;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.role,
    required this.date,
    required this.time,
    required this.dateRange,
    required this.attendeeCount,
    required this.assignedTo,
    this.isStarred = false,
    required this.phoneNumber,
    required this.availableAssignees,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      dateRange: json['dateRange'] ?? '',
      attendeeCount: json['attendeeCount'] ?? 0,
      assignedTo: json['assignedTo'] ?? '',
      isStarred: json['isStarred'] ?? false,
      phoneNumber: json['phoneNumber'] ?? '',
      availableAssignees: (json['availableAssignees'] as List?)
          ?.map((e) => Assignee.fromJson(e))
          .toList() ?? [],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'role': role,
      'date': date,
      'time': time,
      'dateRange': dateRange,
      'attendeeCount': attendeeCount,
      'assignedTo': assignedTo,
      'isStarred': isStarred,
      'phoneNumber': phoneNumber,
      'availableAssignees': availableAssignees.map((e) => e.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? imageUrl,
    String? name,
    String? role,
    String? date,
    String? time,
    String? dateRange,
    int? attendeeCount,
    String? assignedTo,
    bool? isStarred,
    String? phoneNumber,
    List<Assignee>? availableAssignees,
    String? status,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      role: role ?? this.role,
      date: date ?? this.date,
      time: time ?? this.time,
      dateRange: dateRange ?? this.dateRange,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      assignedTo: assignedTo ?? this.assignedTo,
      isStarred: isStarred ?? this.isStarred,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      availableAssignees: availableAssignees ?? this.availableAssignees,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Assignee {
  final String id;
  final String name;
  final String initials;

  Assignee({
    required this.id,
    required this.name,
    required this.initials,
  });

  factory Assignee.fromJson(Map<String, dynamic> json) {
    return Assignee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      initials: json['initials'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
    };
  }

  String get displayString => '$id|$name';
} 