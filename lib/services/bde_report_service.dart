import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/bde_report_model.dart';
import './supabase_service.dart';

class BdeReportService {
  BdeReportService._();
  static final BdeReportService instance = BdeReportService._();

  // Parse a BDE report entry from a task map
  BdeReportEntry _fromTaskMap(Map<String, dynamic> taskRow) {
    final title = taskRow['title']?.toString() ?? '';
    final description = taskRow['description']?.toString() ?? '';
    final reportDate = taskRow['due_date'] != null
        ? DateTime.tryParse(taskRow['due_date'].toString()) ?? DateTime.now()
        : DateTime.now();
    final createdAt = taskRow['created_at'] != null
        ? DateTime.tryParse(taskRow['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    String staffName = 'Employee';
    if (title.startsWith('[BDE REPORT] ')) {
      final suffix = title.substring('[BDE REPORT] '.length);
      final hyphenIdx = suffix.lastIndexOf(' - ');
      if (hyphenIdx != -1) {
        staffName = suffix.substring(0, hyphenIdx).trim();
      } else {
        staffName = suffix.trim();
      }
    }

    Map<String, dynamic> parsed = {};
    if (description.isNotEmpty) {
      try {
        parsed = jsonDecode(description);
      } catch (_) {}
    }

    BdeLoginDetails login;
    if (parsed['login'] != null) {
      final loginMap = parsed['login'] as Map<String, dynamic>;
      login = BdeLoginDetails(
        staffName: staffName,
        reportDate: reportDate,
        databasePlanned: loginMap['databasePlanned'] ?? 0,
        databaseCount: loginMap['databaseCount'] ?? 0,
        socialMediaLeads: loginMap['socialMediaLeads'] ?? 0,
        justDialLeads: loginMap['justDialLeads'] ?? 0,
        otherPlatformLeads: loginMap['otherPlatformLeads'] ?? 0,
        meetingsScheduled: loginMap['meetingsScheduled'] ?? 0,
      );
    } else {
      login = BdeLoginDetails(
        staffName: staffName,
        reportDate: reportDate,
        databasePlanned: 0,
        databaseCount: 0,
        socialMediaLeads: 0,
        justDialLeads: 0,
        otherPlatformLeads: 0,
        meetingsScheduled: 0,
      );
    }

    BdeLogoutDetails? logout;
    if (parsed['logout'] != null) {
      final logoutMap = parsed['logout'] as Map<String, dynamic>;
      logout = BdeLogoutDetails(
        meetingsAttended: logoutMap['meetingsAttended'] ?? 0,
        callsConnected: logoutMap['callsConnected'] ?? 0,
        amountCollected: (logoutMap['amountCollected'] as num?)?.toDouble() ?? 0.0,
        remarks: logoutMap['remarks']?.toString() ?? '',
      );
    }

    return BdeReportEntry(
      id: taskRow['id']?.toString() ?? '',
      staffName: staffName,
      reportDate: reportDate,
      createdAt: createdAt,
      login: login,
      logout: logout,
    );
  }

  // Convert a BDE report entry to task map for saving
  Map<String, dynamic> _toTaskMap(BdeReportEntry entry) {
    final user = SupabaseService.currentUser;
    final descriptionJson = jsonEncode({
      'login': entry.login.toMap(),
      'logout': entry.logout?.toMap(),
    });

    final title = '[BDE REPORT] ${entry.staffName} - ${DateFormat('yyyy-MM-dd').format(entry.reportDate)}';

    return {
      'title': title,
      'description': descriptionJson,
      'due_date': entry.reportDate.toIso8601String(),
      'assigned_to': user?.id,
      'organization_id': '00000000-0000-0000-0000-000000000000',
      'status': 'done',
      'priority': 'medium',
    };
  }

  Future<List<BdeReportEntry>> allReports({bool forAdmin = true}) async {
    try {
      var query = SupabaseService.client
          .from('tasks')
          .select()
          .ilike('title', '[BDE REPORT] %');
          
      if (!forAdmin) {
        final user = SupabaseService.currentUser;
        if (user == null) return [];
        query = query.eq('assigned_to', user.id);
      }

      final response = await query;
      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map((r) => _fromTaskMap(r)).toList();
    } catch (e) {
      debugPrint('Error fetching BDE reports: $e');
      return [];
    }
  }

  Future<List<BdeReportEntry>> reportsForStaff(String staffName) async {
    final reports = await allReports();
    return reports.where((entry) => entry.staffName.toLowerCase() == staffName.toLowerCase()).toList();
  }

  Future<BdeReportEntry> addOrUpdateLogin(BdeLoginDetails login) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final reportDate = DateTime(login.reportDate.year, login.reportDate.month, login.reportDate.day);
    final existingReports = await allReports();
    BdeReportEntry? existing;
    for (final r in existingReports) {
      if (r.staffName.toLowerCase() == login.staffName.toLowerCase() &&
          r.reportDate.year == reportDate.year &&
          r.reportDate.month == reportDate.month &&
          r.reportDate.day == reportDate.day) {
        existing = r;
        break;
      }
    }

    if (existing != null) {
      final updated = BdeReportEntry(
        id: existing.id,
        staffName: login.staffName,
        reportDate: reportDate,
        createdAt: existing.createdAt,
        login: login,
        logout: existing.logout,
      );

      final taskMap = _toTaskMap(updated);
      await SupabaseService.client
          .from('tasks')
          .update(taskMap)
          .eq('id', existing.id);

      return updated;
    } else {
      final entry = BdeReportEntry(
        id: '',
        staffName: login.staffName,
        reportDate: reportDate,
        createdAt: DateTime.now(),
        login: login,
      );

      final taskMap = _toTaskMap(entry);
      final insertedRow = await SupabaseService.client
          .from('tasks')
          .insert(taskMap)
          .select()
          .single();

      return _fromTaskMap(insertedRow);
    }
  }

  Future<BdeReportEntry> addOrUpdateLogout(String staffName, DateTime reportDate, BdeLogoutDetails logout) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final normalizedDate = DateTime(reportDate.year, reportDate.month, reportDate.day);
    final existingReports = await allReports();
    BdeReportEntry? existing;
    for (final r in existingReports) {
      if (r.staffName.toLowerCase() == staffName.toLowerCase() &&
          r.reportDate.year == normalizedDate.year &&
          r.reportDate.month == normalizedDate.month &&
          r.reportDate.day == normalizedDate.day) {
        existing = r;
        break;
      }
    }

    if (existing != null) {
      final updated = existing.copyWith(logout: logout);
      final taskMap = _toTaskMap(updated);
      await SupabaseService.client
          .from('tasks')
          .update(taskMap)
          .eq('id', existing.id);

      return updated;
    } else {
      final defaultLogin = BdeLoginDetails(
        staffName: staffName,
        reportDate: normalizedDate,
        databasePlanned: 0,
        databaseCount: 0,
        socialMediaLeads: 0,
        justDialLeads: 0,
        otherPlatformLeads: 0,
        meetingsScheduled: 0,
      );
      final entry = BdeReportEntry(
        id: '',
        staffName: staffName,
        reportDate: normalizedDate,
        createdAt: DateTime.now(),
        login: defaultLogin,
        logout: logout,
      );

      final taskMap = _toTaskMap(entry);
      final insertedRow = await SupabaseService.client
          .from('tasks')
          .insert(taskMap)
          .select()
          .single();

      return _fromTaskMap(insertedRow);
    }
  }

  Future<List<BdeReportEntry>> filterByRange(DateTime start, DateTime end) async {
    final reports = await allReports();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return reports.where((entry) {
      final entryDate = DateTime(entry.reportDate.year, entry.reportDate.month, entry.reportDate.day);
      return !entryDate.isBefore(normalizedStart) && !entryDate.isAfter(normalizedEnd);
    }).toList();
  }

  Future<List<BdeReportEntry>> filterByPeriod(String period) async {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return filterByRange(now, now);
      case 'This Week':
        final first = now.subtract(Duration(days: now.weekday - 1));
        return filterByRange(first, now);
      case 'This Month':
        final first = DateTime(now.year, now.month, 1);
        return filterByRange(first, now);
      default:
        return allReports();
    }
  }
}
