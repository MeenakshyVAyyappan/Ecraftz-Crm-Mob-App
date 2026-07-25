class AttendanceDevice {
  final String id;
  final String? organizationId;
  final String deviceName;
  final String serialNumber;
  final String? ipAddress;
  final int? port;
  final String apiUrl;
  final String apiKey;
  final String username;
  final String password;
  final String status; // 'active', 'inactive', 'offline'
  final DateTime createdAt;

  AttendanceDevice({
    required this.id,
    this.organizationId,
    required this.deviceName,
    required this.serialNumber,
    this.ipAddress,
    this.port,
    required this.apiUrl,
    required this.apiKey,
    required this.username,
    required this.password,
    this.status = 'active',
    required this.createdAt,
  });

  factory AttendanceDevice.fromJson(Map<String, dynamic> json) {
    return AttendanceDevice(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      deviceName: json['device_name']?.toString() ?? json['name']?.toString() ?? 'Attendance Device',
      serialNumber: json['serial_number']?.toString() ?? json['serial_no']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      port: json['port'] is int ? json['port'] as int : int.tryParse(json['port']?.toString() ?? ''),
      apiUrl: json['api_url']?.toString() ?? json['web_api_url']?.toString() ?? '',
      apiKey: json['api_key']?.toString() ?? '',
      username: json['username']?.toString() ?? json['user_name']?.toString() ?? '',
      password: json['password']?.toString() ?? json['user_password']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (organizationId != null) 'organization_id': organizationId,
    'device_name': deviceName,
    'serial_number': serialNumber,
    'ip_address': ipAddress,
    'port': port,
    'api_url': apiUrl,
    'api_key': apiKey,
    'username': username,
    'password': password,
    'status': status,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class DeviceEmployeeSync {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? serialNumber;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? cardNumber;
  final String commandId;
  final String status; // 'synced', 'pending', 'failed'
  final String? errorLog;
  final DateTime? syncedAt;
  final DateTime createdAt;

  DeviceEmployeeSync({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.serialNumber,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.cardNumber,
    required this.commandId,
    this.status = 'pending',
    this.errorLog,
    this.syncedAt,
    required this.createdAt,
  });

  factory DeviceEmployeeSync.fromJson(Map<String, dynamic> json) {
    String? dName;
    String? sNum;
    if (json['attendance_devices'] is Map) {
      final d = json['attendance_devices'] as Map;
      dName = d['device_name']?.toString();
      sNum = d['serial_number']?.toString();
    }

    return DeviceEmployeeSync(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: dName ?? json['device_name']?.toString(),
      serialNumber: sNum ?? json['serial_number']?.toString(),
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? json['full_name']?.toString() ?? 'Employee',
      employeeCode: json['employee_code']?.toString() ?? '',
      cardNumber: json['card_number']?.toString(),
      commandId: json['command_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      errorLog: json['error_log']?.toString() ?? json['error_message']?.toString(),
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'].toString()).toLocal() : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'employee_id': employeeId,
    'employee_name': employeeName,
    'employee_code': employeeCode,
    'card_number': cardNumber,
    'command_id': commandId,
    'status': status,
    'error_log': errorLog,
    'synced_at': syncedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class DeviceSyncLog {
  final String id;
  final String? deviceId;
  final String? employeeId;
  final String action; // 'AddEmployee', etc.
  final String requestPayload;
  final String responsePayload;
  final String status; // 'success', 'failed', 'auth_failed'
  final DateTime createdAt;

  DeviceSyncLog({
    required this.id,
    this.deviceId,
    this.employeeId,
    required this.action,
    required this.requestPayload,
    required this.responsePayload,
    required this.status,
    required this.createdAt,
  });

  factory DeviceSyncLog.fromJson(Map<String, dynamic> json) {
    return DeviceSyncLog(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString(),
      employeeId: json['employee_id']?.toString(),
      action: json['action']?.toString() ?? 'AddEmployee',
      requestPayload: json['request_payload']?.toString() ?? json['request_xml']?.toString() ?? '',
      responsePayload: json['response_payload']?.toString() ?? json['response_xml']?.toString() ?? '',
      status: json['status']?.toString() ?? 'success',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
    );
  }
}
