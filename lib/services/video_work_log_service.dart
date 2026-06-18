import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/video_work_log_model.dart';
import './supabase_service.dart';

class VideoWorkLogService {
  VideoWorkLogService._();
  static final VideoWorkLogService instance = VideoWorkLogService._();

  VideoWorkLogEntry _fromTaskMap(Map<String, dynamic> taskRow) {
    final description = taskRow['description']?.toString() ?? '';
    Map<String, dynamic> parsed = {};
    if (description.isNotEmpty) {
      try {
        parsed = jsonDecode(description);
      } catch (_) {}
    }

    return VideoWorkLogEntry(
      id: taskRow['id']?.toString() ?? '',
      clientName: parsed['clientName']?.toString() ?? '',
      workType: parsed['workType']?.toString() ?? '',
      status: parsed['status']?.toString() ?? 'Pending',
      date: parsed['date'] != null ? DateTime.tryParse(parsed['date'].toString()) ?? DateTime.now() : DateTime.now(),
      remarks: parsed['remarks']?.toString() ?? '',
      createdAt: taskRow['created_at'] != null ? DateTime.tryParse(taskRow['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> _toTaskMap(VideoWorkLogEntry entry) {
    final user = SupabaseService.currentUser;
    final descriptionJson = jsonEncode({
      'clientName': entry.clientName,
      'workType': entry.workType,
      'status': entry.status,
      'date': entry.date.toIso8601String(),
      'remarks': entry.remarks,
    });

    final title = '[VE LOG] - ${entry.clientName} - ${entry.workType}';

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

  Future<List<VideoWorkLogEntry>> allLogs() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];
      final response = await SupabaseService.client
          .from('tasks')
          .select()
          .ilike('title', '[VE LOG] %')
          .eq('assigned_to', user.id);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map((r) => _fromTaskMap(r)).toList();
    } catch (e) {
      debugPrint('Error fetching Video logs: $e');
      return [];
    }
  }

  Future<void> addLog(VideoWorkLogEntry log) async {
    final taskMap = _toTaskMap(log);
    await SupabaseService.client.from('tasks').insert(taskMap);
  }

  Future<VideoWorkLogEntry> createAndAddLog({
    required String clientName,
    required String workType,
    required String status,
    required DateTime date,
    required String remarks,
  }) async {
    final log = VideoWorkLogEntry(
      id: '',
      clientName: clientName,
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
      debugPrint('Error deleting Video log: $e');
    }
  }

  Future<List<VideoWorkLogEntry>> filterByRange(DateTime start, DateTime end) async {
    final logs = await allLogs();
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return logs.where((log) => !log.date.isBefore(s) && !log.date.isAfter(e)).toList();
  }
}
