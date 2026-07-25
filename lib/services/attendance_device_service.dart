import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'etime_track_api_service.dart';
import '../models/attendance_device_model.dart';

class AttendanceDeviceService {
  AttendanceDeviceService._();
  static final AttendanceDeviceService instance = AttendanceDeviceService._();

  // ─── DEVICES CRUD ────────────────────────────────────────────────────────────

  Future<List<AttendanceDevice>> fetchDevices({String? organizationId}) async {
    try {
      var query = SupabaseService.client.from('attendance_devices').select();
      if (organizationId != null && organizationId.isNotEmpty) {
        query = query.eq('organization_id', organizationId);
      }
      final res = await query.order('created_at', ascending: false);
      final list = res as List;
      return list.map((item) => AttendanceDevice.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Error fetching attendance_devices: $e');
      return [];
    }
  }

  Future<AttendanceDevice?> createDevice({
    String? organizationId,
    required String deviceName,
    required String serialNumber,
    String? ipAddress,
    int? port,
    required String apiUrl,
    required String apiKey,
    required String username,
    required String password,
    String status = 'active',
  }) async {
    final user = SupabaseService.currentUser;
    String orgId = organizationId ?? '00000000-0000-0000-0000-000000000000';
    if (user != null && (organizationId == null || organizationId.isEmpty)) {
      try {
        final profileRes = await SupabaseService.client
            .from('profiles')
            .select('organization_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null && profileRes['organization_id'] != null) {
          orgId = profileRes['organization_id'].toString();
        }
      } catch (_) {}
    }

    final payload = <String, dynamic>{
      'organization_id': orgId,
      'device_name': deviceName,
      'serial_number': serialNumber,
      if (ipAddress != null && ipAddress.isNotEmpty) 'ip_address': ipAddress,
      if (port != null) 'port': port,
      'api_url': apiUrl,
      'api_key': apiKey,
      'username': username,
      'password': password,
      'status': status,
    };

    try {
      final res = await SupabaseService.client
          .from('attendance_devices')
          .insert(payload)
          .select()
          .single();
      return AttendanceDevice.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('Error creating attendance device: $e');
      rethrow;
    }
  }

  Future<AttendanceDevice?> updateDevice({
    required String id,
    String? deviceName,
    String? serialNumber,
    String? ipAddress,
    int? port,
    String? apiUrl,
    String? apiKey,
    String? username,
    String? password,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (deviceName != null) payload['device_name'] = deviceName;
    if (serialNumber != null) payload['serial_number'] = serialNumber;
    if (ipAddress != null) payload['ip_address'] = ipAddress;
    if (port != null) payload['port'] = port;
    if (apiUrl != null) payload['api_url'] = apiUrl;
    if (apiKey != null) payload['api_key'] = apiKey;
    if (username != null) payload['username'] = username;
    if (password != null) payload['password'] = password;
    if (status != null) payload['status'] = status;

    try {
      final res = await SupabaseService.client
          .from('attendance_devices')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return AttendanceDevice.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('Error updating attendance device: $e');
      rethrow;
    }
  }

  Future<void> deleteDevice(String id) async {
    await SupabaseService.client.from('attendance_devices').delete().eq('id', id);
  }

  // ─── DEVICE EMPLOYEE SYNC & API INTEGRATION ────────────────────────────────

  Future<List<DeviceEmployeeSync>> fetchSyncRecords({String? deviceId}) async {
    try {
      var query = SupabaseService.client.from('device_employee_sync').select('*, attendance_devices(device_name, serial_number)');
      if (deviceId != null && deviceId.isNotEmpty) {
        query = query.eq('device_id', deviceId);
      }
      final res = await query.order('created_at', ascending: false);
      final list = res as List;
      return list.map((item) => DeviceEmployeeSync.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Error fetching device_employee_sync: $e');
      try {
        final resFallback = await SupabaseService.client
            .from('device_employee_sync')
            .select()
            .order('created_at', ascending: false);
        final listFallback = resFallback as List;
        return listFallback.map((item) => DeviceEmployeeSync.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (_) {}
      return [];
    }
  }

  Future<DeviceEmployeeSync> addEmployeeToDevice({
    required AttendanceDevice device,
    required String employeeId,
    required String employeeName,
    required String employeeCode,
    String? cardNumber,
    String? commandId,
  }) async {
    final cmdId = (commandId != null && commandId.isNotEmpty)
        ? commandId
        : 'CMD_${DateTime.now().millisecondsSinceEpoch}';
    final cardNo = (cardNumber != null && cardNumber.isNotEmpty) ? cardNumber : employeeCode;

    // Check duplicate
    try {
      final dupCheck = await SupabaseService.client
          .from('device_employee_sync')
          .select('id, status')
          .eq('device_id', device.id)
          .eq('employee_id', employeeId)
          .maybeSingle();

      if (dupCheck != null && dupCheck['status'] == 'synced') {
        throw Exception('Employee "$employeeName" is already synced to device "${device.deviceName}".');
      }
    } catch (e) {
      if (e.toString().contains('already synced')) rethrow;
    }

    // Call eTimeTrackLite Web API
    final apiResult = await ETimeTrackApiService.instance.addEmployee(
      apiUrl: device.apiUrl,
      apiKey: device.apiKey,
      employeeCode: employeeCode,
      employeeName: employeeName,
      cardNumber: cardNo,
      serialNumber: device.serialNumber,
      username: device.username,
      password: device.password,
      commandId: cmdId,
    );

    final syncStatus = apiResult.isSuccess ? 'synced' : 'failed';
    final errorLog = apiResult.isSuccess ? null : apiResult.statusMessage;

    // Upsert into device_employee_sync
    final payload = <String, dynamic>{
      'device_id': device.id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_code': employeeCode,
      'card_number': cardNo,
      'command_id': apiResult.commandId,
      'status': syncStatus,
      'error_log': errorLog,
      if (apiResult.isSuccess) 'synced_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    Map<String, dynamic> savedRow = {};
    try {
      final res = await SupabaseService.client
          .from('device_employee_sync')
          .upsert(payload, onConflict: 'device_id, employee_id')
          .select()
          .single();
      savedRow = Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('Error saving device_employee_sync: $e');
      try {
        final resInsert = await SupabaseService.client
            .from('device_employee_sync')
            .insert(payload)
            .select()
            .single();
        savedRow = Map<String, dynamic>.from(resInsert);
      } catch (err) {
        debugPrint('Fallback insert device_employee_sync failed: $err');
      }
    }

    // Save Log
    try {
      await SupabaseService.client.from('device_sync_logs').insert({
        'device_id': device.id,
        'employee_id': employeeId,
        'action': 'AddEmployee',
        'request_payload': apiResult.rawRequest,
        'response_payload': apiResult.rawResponse,
        'status': apiResult.isSuccess ? 'success' : (apiResult.isAuthError ? 'auth_failed' : 'failed'),
      });
    } catch (e) {
      debugPrint('Failed to insert device_sync_log: $e');
    }

    if (!apiResult.isSuccess) {
      throw Exception(apiResult.statusMessage);
    }

    return DeviceEmployeeSync.fromJson(savedRow);
  }

  Future<DeviceEmployeeSync> retrySync(DeviceEmployeeSync syncRecord) async {
    // Fetch device details
    final devRes = await SupabaseService.client
        .from('attendance_devices')
        .select()
        .eq('id', syncRecord.deviceId)
        .single();
    final device = AttendanceDevice.fromJson(Map<String, dynamic>.from(devRes));

    return await addEmployeeToDevice(
      device: device,
      employeeId: syncRecord.employeeId,
      employeeName: syncRecord.employeeName,
      employeeCode: syncRecord.employeeCode,
      cardNumber: syncRecord.cardNumber,
      commandId: syncRecord.commandId,
    );
  }

  Future<ETimeTrackAddEmployeeResult> blockUnblockEmployeeOnDevice({
    required AttendanceDevice device,
    required String employeeCode,
    required String employeeName,
    required bool isBlock,
    required String commandId,
  }) async {
    final apiResult = await ETimeTrackApiService.instance.blockUnblockUser(
      apiUrl: device.apiUrl,
      apiKey: device.apiKey,
      employeeCode: employeeCode,
      employeeName: employeeName,
      serialNumber: device.serialNumber,
      isBlock: isBlock,
      username: device.username,
      password: device.password,
      commandId: commandId,
    );

    // Save Log
    try {
      await SupabaseService.client.from('device_sync_logs').insert({
        'device_id': device.id,
        'action': isBlock ? 'BlockUser' : 'UnblockUser',
        'request_payload': apiResult.rawRequest,
        'response_payload': apiResult.rawResponse,
        'status': apiResult.isSuccess ? 'success' : 'failed',
      });
    } catch (_) {}

    return apiResult;
  }

  Future<ETimeTrackAddEmployeeResult> deleteEmployeeFromDevice({
    required AttendanceDevice device,
    required String employeeCode,
    required String commandId,
  }) async {
    final apiResult = await ETimeTrackApiService.instance.deleteUser(
      apiUrl: device.apiUrl,
      apiKey: device.apiKey,
      employeeCode: employeeCode,
      serialNumber: device.serialNumber,
      username: device.username,
      password: device.password,
      commandId: commandId,
    );

    // Save Log
    try {
      await SupabaseService.client.from('device_sync_logs').insert({
        'device_id': device.id,
        'action': 'DeleteUser',
        'request_payload': apiResult.rawRequest,
        'response_payload': apiResult.rawResponse,
        'status': apiResult.isSuccess ? 'success' : 'failed',
      });
    } catch (_) {}

    return apiResult;
  }

  Future<ETimeTrackAddEmployeeResult> checkCommandStatus({
    required AttendanceDevice device,
    required String commandId,
  }) async {
    final apiResult = await ETimeTrackApiService.instance.getCommandStatus(
      apiUrl: device.apiUrl,
      commandId: commandId,
      username: device.username,
      password: device.password,
    );

    try {
      await SupabaseService.client.from('device_sync_logs').insert({
        'device_id': device.id,
        'action': 'GetCommandStatus',
        'request_payload': apiResult.rawRequest,
        'response_payload': apiResult.rawResponse,
        'status': apiResult.isSuccess ? 'success' : 'failed',
      });
    } catch (_) {}

    return apiResult;
  }

  // ─── SYNC LOGS ─────────────────────────────────────────────────────────────

  Future<List<DeviceSyncLog>> fetchSyncLogs({String? deviceId}) async {
    try {
      var query = SupabaseService.client.from('device_sync_logs').select();
      if (deviceId != null && deviceId.isNotEmpty) {
        query = query.eq('device_id', deviceId);
      }
      final res = await query.order('created_at', ascending: false).limit(100);
      final list = res as List;
      return list.map((item) => DeviceSyncLog.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Error fetching device_sync_logs: $e');
      return [];
    }
  }
}
