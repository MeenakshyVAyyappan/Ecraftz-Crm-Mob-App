import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/videography_work_log_model.dart';
import './supabase_service.dart';

class VideographyWorkLogService {
  VideographyWorkLogService._();
  static final VideographyWorkLogService instance = VideographyWorkLogService._();

  VideographyWorkLogEntry _fromTaskMap(Map<String, dynamic> taskRow) {
    final description = taskRow['description']?.toString() ?? '';
    Map<String, dynamic> parsed = {};
    if (description.isNotEmpty) {
      try {
        parsed = jsonDecode(description);
      } catch (_) {}
    }

    return VideographyWorkLogEntry(
      id: taskRow['id']?.toString() ?? '',
      clientName: parsed['clientName']?.toString() ?? '',
      shootName: parsed['shootName']?.toString() ?? '',
      shootLocation: parsed['shootLocation']?.toString() ?? '',
      workType: parsed['workType']?.toString() ?? '',
      status: parsed['status']?.toString() ?? 'Pending',
      date: parsed['date'] != null ? DateTime.tryParse(parsed['date'].toString()) ?? DateTime.now() : DateTime.now(),
      remarks: parsed['remarks']?.toString() ?? '',
      createdAt: taskRow['created_at'] != null ? DateTime.tryParse(taskRow['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> _toTaskMap(VideographyWorkLogEntry entry) {
    final user = SupabaseService.currentUser;
    final descriptionJson = jsonEncode({
      'clientName': entry.clientName,
      'shootName': entry.shootName,
      'shootLocation': entry.shootLocation,
      'workType': entry.workType,
      'status': entry.status,
      'date': entry.date.toIso8601String(),
      'remarks': entry.remarks,
    });

    final title = '[VG LOG] - ${entry.clientName} - ${entry.shootName}';

    return {
      'title': title,
      'description': descriptionJson,
      'due_date': entry.date.toIso8601String(),
      'assigned_to': user?.id,
      'organization_id': '00000000-0000-0000-0000-000000000000',
      'status': 'done',
      'priority': 'medium',
    };
  }

  Future<List<VideographyWorkLogEntry>> allLogs() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];
      final response = await SupabaseService.client
          .from('tasks')
          .select()
          .ilike('title', '[VG LOG] %')
          .eq('assigned_to', user.id);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map((r) => _fromTaskMap(r)).toList();
    } catch (e) {
      debugPrint('Error fetching Videography logs: $e');
      return [];
    }
  }

  Future<void> addLog(VideographyWorkLogEntry log) async {
    final taskMap = _toTaskMap(log);
    await SupabaseService.client.from('tasks').insert(taskMap);
  }

  Future<VideographyWorkLogEntry> createAndAddLog({
    required String clientName,
    required String shootName,
    required String shootLocation,
    required String workType,
    required String status,
    required DateTime date,
    required String remarks,
  }) async {
    final log = VideographyWorkLogEntry(
      id: '',
      clientName: clientName,
      shootName: shootName,
      shootLocation: shootLocation,
      workType: workType,
      status: status,
      date: date,
      remarks: remarks,
      createdAt: DateTime.now(),
    );
    final taskMap = _toTaskMap(log);
    final insertedRow = await SupabaseService.client
        .from('tasks')
        .insert(taskMap)
        .select()
        .single();
    return _fromTaskMap(insertedRow);
  }

  Future<void> deleteLog(String id) async {
    try {
      await SupabaseService.client.from('tasks').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting Videography log: $e');
    }
  }

  Future<List<VideographyWorkLogEntry>> filterByRange(DateTime start, DateTime end) async {
    final logs = await allLogs();
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return logs.where((log) => !log.date.isBefore(s) && !log.date.isAfter(e)).toList();
  }
}
