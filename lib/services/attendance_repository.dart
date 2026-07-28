import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_punch_model.dart';
import '../models/wfh_record_model.dart';

class AttendanceRepository {
  AttendanceRepository._();
  static final AttendanceRepository instance = AttendanceRepository._();
  
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> syncPunchesBatch(List<AttendancePunch> punches, String deviceId) async {
    // Process in batches of 50 as mentioned in PDF
    const int batchSize = 50;
    
    for (int i = 0; i < punches.length; i += batchSize) {
      final end = (i + batchSize < punches.length) ? i + batchSize : punches.length;
      final batch = punches.sublist(i, end);
      
      final List<Map<String, dynamic>> payload = batch.map((p) => {
        'p_pin': p.pin,
        'p_punch_time': p.punchTime.toUtc().toIso8601String(), // Ensure UTC
        'p_device_id': deviceId,
      }).toList();

      for(var punchMap in payload) {
        try {
          await _client.rpc('process_biometric_punch', params: punchMap);
        } catch (e) {
          debugPrint("Error syncing punch ${punchMap['p_pin']}: $e");
        }
      }
    }
  }

  Future<List<AttendancePunch>> fetchBiometricLogs(DateTime fromDate, DateTime toDate) async {
    List<AttendancePunch> allLogs = [];
    int offset = 0;
    const int pageSize = 1000;
    bool hasMore = true;

    final startOfFrom = DateTime(fromDate.year, fromDate.month, fromDate.day, 0, 0, 0);
    final endOfTo = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
    final fromStr = startOfFrom.toUtc().toIso8601String();
    final toStr = endOfTo.toUtc().toIso8601String();

    while (hasMore) {
      final res = await _client
          .from('biometric_logs')
          .select('*, profiles!inner(biometric_id)')
          .gte('punch_time', fromStr)
          .lte('punch_time', toStr)
          .order('punch_time', ascending: true)
          .range(offset, offset + pageSize - 1);
          
      final list = res as List;
      
      for (var item in list) {
        var map = Map<String, dynamic>.from(item);
        // Map PIN from joined profile if needed, or if stored directly.
        // Assuming pin is available via profiles.biometric_id
        String? pin;
        if (item['profiles'] != null) {
          pin = item['profiles']['biometric_id']?.toString();
        }
        
        var punch = AttendancePunch.fromJson(map);
        allLogs.add(AttendancePunch(
          id: punch.id,
          organizationId: punch.organizationId,
          deviceId: punch.deviceId,
          employeeId: punch.employeeId,
          punchTime: punch.punchTime,
          punchType: punch.punchType,
          verificationMode: punch.verificationMode,
          isProcessed: punch.isProcessed,
          pin: pin ?? punch.pin,
        ));
      }

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        offset += pageSize;
      }
    }
    return allLogs;
  }

  Future<List<WfhRecord>> fetchWfhRecords(DateTime fromDate, DateTime toDate) async {
    List<WfhRecord> allRecords = [];
    int offset = 0;
    const int pageSize = 1000;
    bool hasMore = true;

    // Assuming wfh_records date column is simple DATE type YYYY-MM-DD
    final fromStr = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
    final toStr = "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";

    while (hasMore) {
      final res = await _client
          .from('wfh_records')
          .select()
          .gte('date', fromStr)
          .lte('date', toStr)
          .range(offset, offset + pageSize - 1);
          
      final list = res as List;
      allRecords.addAll(list.map((item) => WfhRecord.fromJson(Map<String, dynamic>.from(item))));

      if (list.length < pageSize) {
        hasMore = false;
      } else {
        offset += pageSize;
      }
    }
    return allRecords;
  }
  
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final res = await _client.from('profiles').select('id, full_name, biometric_id').not('biometric_id', 'is', null);
    return List<Map<String, dynamic>>.from(res as List);
  }
  
  Future<void> toggleWfh(String pin, DateTime date, bool isWfh) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    if (isWfh) {
      await _client.from('wfh_records').upsert({
        'biometric_pin': pin,
        'date': dateStr,
        'marked_by': _client.auth.currentUser?.id,
      });
    } else {
      await _client
          .from('wfh_records')
          .delete()
          .match({'biometric_pin': pin, 'date': dateStr});
    }
  }
}
