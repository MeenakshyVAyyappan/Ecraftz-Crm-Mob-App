class Meeting {
  final String id;
  final String? organizationId;
  final String? createdBy;
  final String title;
  final String? description;
  final String? meetingType;
  final String meetingMode; // 'online', 'in_person'
  final String? location;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? meetingLink;
  final String? leadId;
  final String? leadName;
  final String? clientId;
  final String? clientName;
  final String? projectId;
  final String? projectName;
  final String status; // 'scheduled', 'completed', 'cancelled', 'rescheduled'
  final String? outcomeNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attendeeIds;

  Meeting({
    required this.id,
    this.organizationId,
    this.createdBy,
    required this.title,
    this.description,
    this.meetingType = 'Client Demo',
    this.meetingMode = 'online',
    this.location,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.meetingLink,
    this.leadId,
    this.leadName,
    this.clientId,
    this.clientName,
    this.projectId,
    this.projectName,
    this.status = 'scheduled',
    this.outcomeNotes,
    required this.createdAt,
    this.updatedAt,
    this.attendeeIds = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['clients'] is Map) {
      cName = (json['clients'] as Map)['name']?.toString();
    }
    String? pName;
    if (json['projects'] is Map) {
      pName = (json['projects'] as Map)['name']?.toString();
    }
    String? lName;
    if (json['leads'] is Map) {
      final l = json['leads'] as Map;
      lName = '${l['first_name'] ?? ''} ${l['last_name'] ?? ''}'.trim();
    }

    List<String> attendees = [];
    if (json['meeting_attendees'] is List) {
      for (final a in json['meeting_attendees']) {
        if (a is Map && a['user_id'] != null) {
          attendees.add(a['user_id'].toString());
        }
      }
    }

    return Meeting(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      title: json['title']?.toString() ?? 'Meeting',
      description: json['description']?.toString(),
      meetingType: json['meeting_type']?.toString() ?? 'General',
      meetingMode: json['meeting_mode']?.toString() ?? 'online',
      location: json['location']?.toString(),
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'].toString()) : DateTime.now(),
      durationMinutes: json['duration_minutes'] is int ? json['duration_minutes'] as int : 30,
      meetingLink: json['meeting_link']?.toString(),
      leadId: json['lead_id']?.toString(),
      leadName: lName,
      clientId: json['client_id']?.toString(),
      clientName: cName,
      projectId: json['project_id']?.toString(),
      projectName: pName,
      status: json['status']?.toString() ?? 'scheduled',
      outcomeNotes: json['outcome_notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      attendeeIds: attendees,
    );
  }
}
