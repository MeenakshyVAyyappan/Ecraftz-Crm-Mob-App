import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class CrmReportSummary {
  final int totalLeads;
  final double pipelineValue;
  final int convertedLeads;
  final int totalClients;
  final int totalInvoices;
  final double totalBilledAmount;
  final double totalPaidAmount;
  final double totalPendingAmount;
  final int totalMeetings;
  final int completedMeetings;
  final int totalFeedback;
  final double averageRating;
  final int totalWorkTasks;
  final int totalLoggedMinutes;

  CrmReportSummary({
    required this.totalLeads,
    required this.pipelineValue,
    required this.convertedLeads,
    required this.totalClients,
    required this.totalInvoices,
    required this.totalBilledAmount,
    required this.totalPaidAmount,
    required this.totalPendingAmount,
    required this.totalMeetings,
    required this.completedMeetings,
    required this.totalFeedback,
    required this.averageRating,
    required this.totalWorkTasks,
    required this.totalLoggedMinutes,
  });
}

class CrmReportsService {
  CrmReportsService._();
  static final CrmReportsService instance = CrmReportsService._();

  Future<CrmReportSummary> fetchReportSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? clientId,
  }) async {
    int totalLeads = 0;
    double pipelineValue = 0.0;
    int convertedLeads = 0;

    int totalClients = 0;

    int totalInvoices = 0;
    double totalBilled = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;

    int totalMeetings = 0;
    int completedMeetings = 0;

    int totalFeedback = 0;
    double totalRatingSum = 0.0;

    int totalWorkTasks = 0;
    int totalLoggedMinutes = 0;

    try {
      // 1. Leads Analytics
      var leadsQuery = SupabaseService.client.from('leads').select();
      if (startDate != null) leadsQuery = leadsQuery.gte('created_at', startDate.toIso8601String());
      if (endDate != null) leadsQuery = leadsQuery.lte('created_at', endDate.toIso8601String());
      final leadsRes = await leadsQuery;
      if (leadsRes is List) {
        totalLeads = leadsRes.length;
        for (final l in leadsRes) {
          final val = (l['value'] is num) ? (l['value'] as num).toDouble() : 0.0;
          pipelineValue += val;
          final status = l['status']?.toString().toLowerCase();
          if (status == 'converted' || status == 'closed_won' || status == 'won') {
            convertedLeads++;
          }
        }
      }
    } catch (e) {
      debugPrint('Leads report fetch error: $e');
    }

    try {
      // 2. Clients Count
      var clientsQuery = SupabaseService.client.from('clients').select('id');
      if (startDate != null) clientsQuery = clientsQuery.gte('created_at', startDate.toIso8601String());
      final clientsRes = await clientsQuery;
      if (clientsRes is List) {
        totalClients = clientsRes.length;
      }
    } catch (e) {
      debugPrint('Clients report fetch error: $e');
    }

    try {
      // 3. Invoices Analytics
      var invQuery = SupabaseService.client.from('invoices').select();
      if (startDate != null) invQuery = invQuery.gte('created_at', startDate.toIso8601String());
      if (endDate != null) invQuery = invQuery.lte('created_at', endDate.toIso8601String());
      if (clientId != null && clientId.isNotEmpty) invQuery = invQuery.eq('client_id', clientId);
      final invRes = await invQuery;
      if (invRes is List) {
        totalInvoices = invRes.length;
        for (final inv in invRes) {
          final gTotal = (inv['grand_total'] is num) ? (inv['grand_total'] as num).toDouble() : 0.0;
          final aPaid = (inv['amount_paid'] is num) ? (inv['amount_paid'] as num).toDouble() : 0.0;
          final aDue = (inv['amount_due'] is num) ? (inv['amount_due'] as num).toDouble() : (gTotal - aPaid);
          totalBilled += gTotal;
          totalPaid += aPaid;
          totalPending += (aDue > 0 ? aDue : 0);
        }
      }
    } catch (e) {
      debugPrint('Invoices report fetch error: $e');
    }

    try {
      // 4. Meetings Analytics
      var meetingsQuery = SupabaseService.client.from('meetings').select();
      if (startDate != null) meetingsQuery = meetingsQuery.gte('scheduled_at', startDate.toIso8601String());
      if (endDate != null) meetingsQuery = meetingsQuery.lte('scheduled_at', endDate.toIso8601String());
      final meetingsRes = await meetingsQuery;
      if (meetingsRes is List) {
        totalMeetings = meetingsRes.length;
        for (final m in meetingsRes) {
          if (m['status']?.toString().toLowerCase() == 'completed') {
            completedMeetings++;
          }
        }
      }
    } catch (e) {
      debugPrint('Meetings report fetch error: $e');
    }

    try {
      // 5. Feedback Analytics
      var feedbackQuery = SupabaseService.client.from('client_feedback').select();
      if (startDate != null) feedbackQuery = feedbackQuery.gte('created_at', startDate.toIso8601String());
      final fbRes = await feedbackQuery;
      if (fbRes is List) {
        totalFeedback = fbRes.length;
        for (final fb in fbRes) {
          final r = (fb['rating'] is num) ? (fb['rating'] as num).toDouble() : 5.0;
          totalRatingSum += r;
        }
      }
    } catch (e) {
      debugPrint('Feedback report fetch error: $e');
    }

    try {
      // 6. Tasks Analytics
      var tasksQuery = SupabaseService.client.from('tasks').select('id, description');
      if (employeeId != null && employeeId.isNotEmpty) {
        tasksQuery = tasksQuery.eq('user_id', employeeId);
      }
      final tasksRes = await tasksQuery;
      if (tasksRes is List) {
        totalWorkTasks = tasksRes.length;
      }
    } catch (e) {
      debugPrint('Tasks report fetch error: $e');
    }

    double avgRating = totalFeedback > 0 ? (totalRatingSum / totalFeedback) : 5.0;

    return CrmReportSummary(
      totalLeads: totalLeads,
      pipelineValue: pipelineValue,
      convertedLeads: convertedLeads,
      totalClients: totalClients,
      totalInvoices: totalInvoices,
      totalBilledAmount: totalBilled,
      totalPaidAmount: totalPaid,
      totalPendingAmount: totalPending,
      totalMeetings: totalMeetings,
      completedMeetings: completedMeetings,
      totalFeedback: totalFeedback,
      averageRating: avgRating,
      totalWorkTasks: totalWorkTasks,
      totalLoggedMinutes: totalLoggedMinutes,
    );
  }
}
