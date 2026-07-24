import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/team_timesheet_model.dart';

class TeamTimesheetService {
  TeamTimesheetService._();
  static final TeamTimesheetService instance = TeamTimesheetService._();

  Future<List<TeamTimesheetEntry>> fetchTeamTimesheets({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  }) async {
    try {
      dynamic query = SupabaseService.client
          .from('attendance_sessions')
          .select('*, profiles:profiles!employee_id(full_name, email)');

      if (employeeId != null && employeeId.isNotEmpty) {
        query = query.eq('employee_id', employeeId);
      }
      if (startDate != null) {
        query = query.gte('session_date', startDate.toIso8601String().split('T').first);
      }
      if (endDate != null) {
        query = query.lte('session_date', endDate.toIso8601String().split('T').first);
      }

      query = query.order('session_date', ascending: false);

      final res = await query;
      if (res is List && res.isNotEmpty) {
        return res.map((item) => TeamTimesheetEntry.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching attendance_sessions: $e');
    }

    // Fallback query from daily_attendance_summary or work_sessions
    try {
      dynamic fallbackQuery = SupabaseService.client
          .from('work_sessions')
          .select('*, profiles:profiles!user_id(full_name, email)');

      if (employeeId != null && employeeId.isNotEmpty) {
        fallbackQuery = fallbackQuery.eq('user_id', employeeId);
      }

      fallbackQuery = fallbackQuery.order('start_time', ascending: false);

      final fallbackRes = await fallbackQuery;
      if (fallbackRes is List) {
        return fallbackRes.map((item) => TeamTimesheetEntry.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (err) {
      debugPrint('Fallback work_sessions fetch failed: $err');
    }

    return [];
  }
}
