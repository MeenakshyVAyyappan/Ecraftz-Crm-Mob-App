import 'package:xml/xml.dart';

class AttendancePunch {
  final String id;
  final String? organizationId;
  final String? deviceId;
  final String employeeId;
  final DateTime punchTime;
  final String? punchType;
  final String? verificationMode;
  final bool? isProcessed;

  // From XML direct parse
  final String? pin;

  AttendancePunch({
    required this.id,
    this.organizationId,
    this.deviceId,
    required this.employeeId,
    required this.punchTime,
    this.punchType,
    this.verificationMode,
    this.isProcessed,
    this.pin,
  });

  factory AttendancePunch.fromJson(Map<String, dynamic> json) {
    return AttendancePunch(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      deviceId: json['device_id'] as String?,
      employeeId: json['employee_id'] as String,
      punchTime: DateTime.parse(json['punch_time'] as String).toLocal(),
      punchType: json['punch_type'] as String?,
      verificationMode: json['verification_mode'] as String?,
      isProcessed: json['is_processed'] as bool?,
    );
  }

  // XML Parser for eSSL SOAP API response
  static List<AttendancePunch> parseXmlLogs(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final rows = document.findAllElements('Row');
    List<AttendancePunch> punches = [];

    for (var row in rows) {
      final pinElement = row.findElements('PIN').firstOrNull;
      final dateTimeElement = row.findElements('DateTime').firstOrNull;

      if (pinElement != null && dateTimeElement != null) {
        final pin = pinElement.innerText;
        final dateTimeStr = dateTimeElement.innerText;
        
        // eSSL typically returns 'YYYY-MM-DD HH:mm:ss'
        try {
          final dt = DateTime.parse(dateTimeStr.replaceFirst(' ', 'T'));
          
          punches.add(AttendancePunch(
            id: DateTime.now().millisecondsSinceEpoch.toString() + pin,
            employeeId: '', // To be mapped later
            punchTime: dt,
            pin: pin,
          ));
        } catch (e) {
          // ignore parsing error
        }
      }
    }
    return punches;
  }
}
