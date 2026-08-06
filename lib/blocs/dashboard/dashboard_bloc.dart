import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/dashboard_models.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

bool _isSuperAdminRole(String? role) {
  if (role == null) return false;
  final r = role.trim().toLowerCase();
  return r == 'super_admin' ||
      r == 'superadmin' ||
      r == 'super admin' ||
      r == 'admin' ||
      r == 'administrator' ||
      r == 'crm' ||
      r == 'crm_admin' ||
      r == 'crm admin' ||
      r == 'bde' ||
      r == 'manager';
}

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends DashboardEvent {
  final DateTimeRange? dateRange;
  final BranchState? branchState;
  const LoadDashboardEvent({this.dateRange, this.branchState});
  @override
  List<Object?> get props => [dateRange, branchState];
}

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<DashboardStats> stats;
  final List<ActivityItem> activities;
  final List<ProjectItem> projects;
  final List<RecentTask> tasks;
  final List<RevenuePoint> revenueData;
  final DateTimeRange? dateRange;
  final double totalRevenue;
  final double receivables;

  const DashboardLoaded({
    required this.stats,
    required this.activities,
    required this.projects,
    required this.tasks,
    required this.revenueData,
    this.dateRange,
    required this.totalRevenue,
    required this.receivables,
  });

  @override
  List<Object?> get props => [stats, activities, projects, tasks, revenueData, dateRange, totalRevenue, receivables];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _client = SupabaseService.client;

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardEvent>((event, emit) async {
      emit(DashboardLoading());
      try {
        final start = event.dateRange?.start;
        final end = event.dateRange?.end;

        // Determine branch_id filter (null = All Branches)
        final branchId = event.branchState?.activeBranchId;

        // 1. Fetch Invoices
        var invoiceQuery = _client.from('invoices').select('*, clients(name)').isFilter('deleted_at', null);
        if (start != null && end != null) {
          invoiceQuery = invoiceQuery
              .gte('date', start.toIso8601String().split('T')[0])
              .lte('date', end.toIso8601String().split('T')[0]);
        }
        if (branchId != null && branchId.isNotEmpty) {
          invoiceQuery = invoiceQuery.eq('branch_id', branchId);
        }
        final invoicesRes = await invoiceQuery;
        final invoices = invoicesRes as List;

        // 2. Fetch Projects
        var projectQuery = _client.from('projects').select('*, clients(name)').isFilter('deleted_at', null);
        if (start != null && end != null) {
          projectQuery = projectQuery
              .gte('created_at', start.toIso8601String())
              .lte('created_at', end.toIso8601String());
        }
        if (branchId != null && branchId.isNotEmpty) {
          projectQuery = projectQuery.eq('branch_id', branchId);
        }
        final projectsRes = await projectQuery;
        final projects = projectsRes as List;

        // 3. Fetch Tasks
        var taskQuery = _client.from('tasks').select('*, projects(name, client_id, clients(name))').isFilter('deleted_at', null);
        if (start != null && end != null) {
          taskQuery = taskQuery
              .gte('created_at', start.toIso8601String())
              .lte('created_at', end.toIso8601String());
        }
        final tasksRes = await taskQuery;
        final tasks = tasksRes as List;

        // 4. Fetch Activities
        final activitiesRes = await _client.from('activities').select().order('created_at', ascending: false).limit(5);
        final activities = activitiesRes as List;

        // 5. Fetch Leads
        final currentUser = _client.auth.currentUser;
        String? userRole;
        if (currentUser != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            userRole = prefs.getString('user_role');
          } catch (_) {}
          if (userRole == null || userRole.isEmpty) {
            try {
              final prof = await _client.from('profiles').select('role').eq('id', currentUser.id).maybeSingle();
              userRole = prof?['role']?.toString();
            } catch (_) {}
          }
        }
        final isSuperAdmin = _isSuperAdminRole(userRole);

        var leadsQuery = _client.from('leads').select().isFilter('deleted_at', null);
        if (!isSuperAdmin && currentUser != null) {
          leadsQuery = leadsQuery.or('user_id.eq.${currentUser.id},assigned_to.eq.${currentUser.id}');
        }
        if (start != null && end != null) {
          leadsQuery = leadsQuery
              .gte('created_at', start.toIso8601String())
              .lte('created_at', end.toIso8601String());
        }
        if (branchId != null && branchId.isNotEmpty) {
          leadsQuery = leadsQuery.eq('branch_id', branchId);
        }
        List leads = [];
        try {
          final res = await leadsQuery;
          leads = res as List;
        } catch (_) {
          var fallback = _client.from('leads').select().isFilter('deleted_at', null);
          if (!isSuperAdmin && currentUser != null) {
            fallback = fallback.or('user_id.eq.${currentUser.id},assigned_to.eq.${currentUser.id}');
          }
          if (start != null && end != null) {
            fallback = fallback
                .gte('created_at', start.toIso8601String())
                .lte('created_at', end.toIso8601String());
          }
          try {
            final res = await fallback;
            leads = res as List;
          } catch (_) {}
        }

        if (!isSuperAdmin && currentUser != null) {
          final uid = currentUser.id;
          leads = leads.where((l) {
            if (l is Map) {
              final cb = l['created_by']?.toString() ?? l['user_id']?.toString();
              final at = l['assigned_to']?.toString();
              return cb == uid || at == uid;
            }
            return true;
          }).toList();
        }

        // 6. Fetch Proposals
        var proposalsQuery = _client.from('proposals').select();
        if (start != null && end != null) {
          proposalsQuery = proposalsQuery
              .gte('created_at', start.toIso8601String())
              .lte('created_at', end.toIso8601String());
        }
        List proposals = [];
        try {
          final res = await proposalsQuery;
          proposals = res as List;
        } catch (_) {}

        // 7. Fetch Payments
        var paymentsQuery = _client.from('payments').select().isFilter('deleted_at', null);
        if (start != null && end != null) {
          paymentsQuery = paymentsQuery
              .gte('date', start.toIso8601String().split('T')[0])
              .lte('date', end.toIso8601String().split('T')[0]);
        }
        if (branchId != null && branchId.isNotEmpty) {
          paymentsQuery = paymentsQuery.eq('branch_id', branchId);
        }
        List payments = [];
        try {
          final res = await paymentsQuery;
          payments = res as List;
        } catch (_) {
          var fallback = _client.from('payments').select().isFilter('deleted_at', null);
          if (start != null && end != null) {
            fallback = fallback
                .gte('date', start.toIso8601String().split('T')[0])
                .lte('date', end.toIso8601String().split('T')[0]);
          }
          try {
            final res = await fallback;
            payments = res as List;
          } catch (_) {
            try {
              final res = await _client.from('payments').select();
              payments = res as List;
            } catch (_) {}
          }
        }

        // --- Aggregations & Calculations ---
        
        double unpaidRev = 0.0;
        for (final inv in invoices) {
          final amt = (inv['grand_total'] is num)
              ? (inv['grand_total'] as num).toDouble()
              : double.tryParse(inv['grand_total']?.toString() ?? '') ?? 0.0;
          final paidAmt = (inv['amount_paid'] is num)
              ? (inv['amount_paid'] as num).toDouble()
              : double.tryParse(inv['amount_paid']?.toString() ?? '') ?? 0.0;
          final dueAmt = (inv['amount_due'] is num)
              ? (inv['amount_due'] as num).toDouble()
              : double.tryParse(inv['amount_due']?.toString() ?? '') ?? 0.0;
          final status = inv['status']?.toString().toLowerCase() ?? '';

          if (status != 'cancelled') {
            unpaidRev += (status == 'paid' ? 0.0 : (dueAmt > 0 ? dueAmt : (amt - paidAmt)));
          }
        }

        // Active Projects count
        int activeProjectsCount = projects.where((p) => p['status']?.toString().toLowerCase() == 'in_progress').length;

        // Overdue Tasks count
        int overdueTasksCount = 0;
        final now = DateTime.now();
        for (final t in tasks) {
          final tStatus = t['status']?.toString().toLowerCase() ?? '';
          if (tStatus != 'done' && t['due_date'] != null) {
            final due = DateTime.tryParse(t['due_date'].toString());
            if (due != null && due.isBefore(now)) {
              overdueTasksCount++;
            }
          }
        }

        // Resource Load
        int inProgressTasksCount = tasks.where((t) => t['status']?.toString().toLowerCase() == 'in_progress').length;
        int resourceLoadPercent = tasks.isNotEmpty ? ((inProgressTasksCount / tasks.length) * 100).round() : 0;

        // Total Leads count
        int totalLeadsCount = leads.length;

        // New Leads count
        int newLeadsCount = leads.where((l) => l['status']?.toString().toLowerCase() == 'new').length;

        // Total Collections (only verified, paid, or success payments)
        double totalCollectionsVal = 0.0;
        for (final pay in payments) {
          final status = pay['status']?.toString().toLowerCase() ?? '';
          if (status == 'verified' || status == 'paid' || status == 'success') {
            final amt = (pay['amount'] is num)
                ? (pay['amount'] as num).toDouble()
                : double.tryParse(pay['amount']?.toString() ?? '') ?? 0.0;
            totalCollectionsVal += amt;
          }
        }

        // Total Revenue equals Total Collections (All Time Earnings from verified payments)
        double totalRevenueVal = totalCollectionsVal;

        // Total Proposals count
        int totalProposalsCount = proposals.length;

        // Stats Cards List matching Web CRM (8 boxes)
        final statsList = [
          DashboardStats(
            label: 'TOTAL LEADS',
            value: '$totalLeadsCount',
            subtitle: 'ALL LEADS IN SYSTEM',
            status: 'STABLE',
            icon: 'people_outline',
            colorIndex: 0,
          ),
          DashboardStats(
            label: 'NEW LEADS',
            value: '$newLeadsCount',
            subtitle: 'AWAITING RESPONSE',
            status: newLeadsCount > 0 ? 'ALERT' : 'STABLE',
            icon: 'star_outline_rounded',
            colorIndex: 1,
          ),
          DashboardStats(
            label: 'TOTAL COLLECTIONS',
            value: '₹${totalCollectionsVal.toStringAsFixed(0)}',
            subtitle: 'TOTAL PAYMENTS COLLECTED',
            status: 'STABLE',
            icon: 'payments_outlined',
            colorIndex: 2,
          ),
          DashboardStats(
            label: 'TOTAL PROPOSALS',
            value: '$totalProposalsCount',
            subtitle: 'GENERATED PROPOSALS',
            status: 'STABLE',
            icon: 'description_outlined',
            colorIndex: 3,
          ),
          DashboardStats(
            label: 'TOTAL REVENUE',
            value: '₹${totalRevenueVal.toStringAsFixed(0)}',
            subtitle: 'ALL TIME EARNINGS',
            status: 'STABLE',
            icon: 'currency_rupee_rounded',
            colorIndex: 4,
          ),
          DashboardStats(
            label: 'ACTIVE PROJECTS',
            value: '$activeProjectsCount',
            subtitle: 'ONGOING OPERATIONS',
            status: 'STABLE',
            icon: 'work_outline',
            colorIndex: 5,
          ),
          DashboardStats(
            label: 'OVERDUE TASKS',
            value: '$overdueTasksCount',
            subtitle: overdueTasksCount == 0 ? 'ALL CLEAR' : '$overdueTasksCount OVERDUE',
            status: overdueTasksCount == 0 ? 'STABLE' : 'ALERT',
            icon: 'warning_amber_rounded',
            colorIndex: 6,
          ),
          DashboardStats(
            label: 'RESOURCE LOAD',
            value: '$resourceLoadPercent%',
            subtitle: 'WORKLOAD DISTRIBUTION',
            status: 'STABLE',
            icon: 'access_time',
            colorIndex: 7,
          ),
        ];

        // Format Activities with real-time actor names
        final activityList = activities.map((a) {
          final action = a['action']?.toString() ?? 'action';
          final target = a['target_name']?.toString() ?? a['target']?.toString() ?? a['entity_type']?.toString() ?? '';
          final rawUser = a['actor_name']?.toString() ?? a['user_name']?.toString() ?? a['created_by_name']?.toString() ?? a['user']?.toString() ?? '';
          final user = rawUser.isNotEmpty ? rawUser : (a['role']?.toString().toUpperCase() ?? 'Admin');
          final dateStr = a['created_at']?.toString() ?? '';
          final date = dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();
          return ActivityItem(
            user: user,
            action: action.toUpperCase(),
            target: target,
            timeAgo: _formatTimeAgo(date),
            colorIndex: action.contains('status') ? 0 : (action.contains('delete') ? 2 : 1),
          );
        }).toList();

        // Format Projects List (first 5)
        final projectList = projects.take(5).map((p) {
          final pId = p['id']?.toString() ?? '';
          final name = p['name']?.toString() ?? '';
          final clientsMap = p['clients'];
          final cName = (clientsMap is Map) ? (clientsMap['name']?.toString() ?? '') : '';
          
          // Compute tasks counts for progress
          final pTasks = tasks.where((t) => t['project_id'] == pId).toList();
          final completed = pTasks.where((t) => t['status']?.toString().toLowerCase() == 'done').length;
          final total = pTasks.length;
          final double progress = total > 0 ? (completed / total) : 0.0;
          return ProjectItem(
            name: name,
            client: cName.isNotEmpty ? cName : 'General',
            progress: progress,
            taskCount: completed,
            totalTasks: total,
            status: p['status']?.toString() ?? 'planning',
          );
        }).toList();

        // Format Tasks List (first 5)
        final taskList = tasks.take(5).map((t) {
          final title = t['title']?.toString() ?? '';
          final pMap = t['projects'];
          String pName = '';
          if (pMap is Map) {
            pName = pMap['name']?.toString() ?? '';
            final cMap = pMap['clients'];
            if (cMap is Map && cMap['name'] != null) {
              pName = '${cMap['name'].toString()} - $pName';
            }
          }
          return RecentTask(
            title: title,
            project: pName.isNotEmpty ? pName : 'General',
            status: (t['status']?.toString() ?? 'todo').toUpperCase(),
          );
        }).toList();

        // Aggregate Revenue Velocity (month by month)
        final Map<String, List<double>> revenueByMonth = {}; 
        final monthsList = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        
        // Initialize last 6 months
        for (int i = 5; i >= 0; i--) {
          final mDate = DateTime.now().subtract(Duration(days: 30 * i));
          revenueByMonth[monthsList[mDate.month - 1]] = [0.0, 0.0];
        }

        for (final inv in invoices) {
          final dateStr = inv['date']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final dt = DateTime.tryParse(dateStr);
            if (dt != null) {
              final mName = monthsList[dt.month - 1];
              final amt = (inv['grand_total'] is num) ? (inv['grand_total'] as num).toDouble() : double.tryParse(inv['grand_total']?.toString() ?? '') ?? 0.0;
              final status = inv['status']?.toString().toLowerCase() ?? '';
              
              if (revenueByMonth.containsKey(mName)) {
                revenueByMonth[mName]![0] += amt; 
                if (status == 'paid') {
                  revenueByMonth[mName]![1] += amt; 
                }
              }
            }
          }
        }

        final revenuePoints = revenueByMonth.entries.map((e) => RevenuePoint(
          month: e.key,
          pipeline: e.value[0],
          actual: e.value[1],
        )).toList();

        emit(DashboardLoaded(
          stats: statsList,
          activities: activityList,
          projects: projectList,
          tasks: taskList,
          revenueData: revenuePoints,
          dateRange: event.dateRange,
          totalRevenue: totalRevenueVal,
          receivables: unpaidRev,
        ));
      } catch (e, stack) {
        print('DASHBOARD_BLOC ERROR: $e');
        print('DASHBOARD_BLOC STACKTRACE: $stack');
        emit(DashboardError(e.toString()));
      }
    });
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} YEARS AGO';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} MONTHS AGO';
    if (diff.inDays > 0) return '${diff.inDays} ${diff.inDays == 1 ? "DAY" : "DAYS"} AGO';
    if (diff.inHours > 0) return '${diff.inHours} ${diff.inHours == 1 ? "HOUR" : "HOURS"} AGO';
    if (diff.inMinutes > 0) return '${diff.inMinutes} ${diff.inMinutes == 1 ? "MIN" : "MINS"} AGO';
    return 'JUST NOW';
  }
}
