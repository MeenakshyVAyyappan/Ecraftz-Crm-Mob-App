class GraphicWorkLogEntry {
  final String id;
  final String clientName;
  final String workType;
  final String status;
  final DateTime date;
  final String remarks;
  final DateTime createdAt;

  GraphicWorkLogEntry({
    required this.id,
    required this.clientName,
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
      'workType': workType,
      'status': status,
      'date': date.toIso8601String(),
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GraphicWorkLogEntry.fromMap(Map<String, dynamic> map) {
    return GraphicWorkLogEntry(
      id: map['id']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      workType: map['workType']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Pending',
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
      remarks: map['remarks']?.toString() ?? '',
      createdAt: DateTime.parse(map['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}
