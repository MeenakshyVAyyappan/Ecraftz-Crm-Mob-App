class VideographyWorkLogEntry {
  final String id;
  final String clientName;
  final String shootName;
  final String shootLocation;
  final String workType;
  final String status;
  final DateTime date;
  final String remarks;
  final DateTime createdAt;

  VideographyWorkLogEntry({
    required this.id,
    required this.clientName,
    required this.shootName,
    required this.shootLocation,
    required this.workType,
    required this.status,
    required this.date,
    required this.remarks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'shootName': shootName,
      'shootLocation': shootLocation,
      'workType': workType,
      'status': status,
      'date': date.toIso8601String(),
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VideographyWorkLogEntry.fromMap(Map<String, dynamic> map) {
    return VideographyWorkLogEntry(
      id: map['id']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      shootName: map['shootName']?.toString() ?? '',
      shootLocation: map['shootLocation']?.toString() ?? '',
      workType: map['workType']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Pending',
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
      remarks: map['remarks']?.toString() ?? '',
      createdAt: DateTime.parse(map['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}
