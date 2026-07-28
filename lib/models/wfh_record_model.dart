class WfhRecord {
  final String biometricPin;
  final DateTime date;
  final String? markedBy;

  WfhRecord({
    required this.biometricPin,
    required this.date,
    this.markedBy,
  });

  factory WfhRecord.fromJson(Map<String, dynamic> json) {
    return WfhRecord(
      biometricPin: json['biometric_pin'] as String,
      date: DateTime.parse(json['date'] as String),
      markedBy: json['marked_by'] as String?,
    );
  }
}
