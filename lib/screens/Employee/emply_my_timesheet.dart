import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/task/task_bloc.dart';
import '../../models/task_model.dart';
import '../../models/work_session_model.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class MyTimesheetScreen extends StatefulWidget {
  const MyTimesheetScreen({super.key});

  @override
  State<MyTimesheetScreen> createState() => _MyTimesheetScreenState();
}

class _MyTimesheetScreenState extends State<MyTimesheetScreen> {
  String _selectedPeriod = 'Today';
  bool _isLoading = true;
  String? _error;
  List<WorkSession> _sessions = [];
  User? _currentUser;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = SupabaseService.currentUser;
      _currentUser = user;
      if (user == null) {
        if (mounted) {
          setState(() {
            _error = 'Not signed in';
            _isLoading = false;
          });
        }
        return;
      }

      final profileRows = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .limit(1);
      if (profileRows is List && profileRows.isNotEmpty) {
        _profile = Map<String, dynamic>.from(profileRows.first as Map);
      }

      final sessionRows = await SupabaseService.client
          .from('work_sessions')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: false);

      final rows = (sessionRows as List).cast<Map<String, dynamic>>();
      final sessionIds = rows.map((r) => r['id']?.toString()).where((id) => id != null).cast<String>().toList();
      Map<String, int> breakMap = {};
      if (sessionIds.isNotEmpty) {
        final breakRows = await SupabaseService.client
            .from('break_sessions')
            .select()
            .filter('work_session_id', 'in', '(${sessionIds.join(',')})');
        for (final row in (breakRows as List).cast<Map<String, dynamic>>()) {
          final sid = row['work_session_id']?.toString();
          if (sid == null) continue;
          int minutes = 0;
          if (row.containsKey('duration_minutes')) {
            minutes = int.tryParse(row['duration_minutes'].toString()) ?? 0;
          } else if (row.containsKey('minutes')) {
            minutes = int.tryParse(row['minutes'].toString()) ?? 0;
          } else if (row.containsKey('duration')) {
            minutes = int.tryParse(row['duration'].toString()) ?? 0;
          }
          breakMap[sid] = (breakMap[sid] ?? 0) + minutes;
        }
      }

      final sessions = rows.map((row) {
        final id = row['id']?.toString() ?? '';
        return WorkSession.fromMap(row, breakMinutes: breakMap[id] ?? 0);
      }).toList();

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final startMondayA = a.subtract(Duration(days: a.weekday - 1));
    final weekStartA = DateTime(startMondayA.year, startMondayA.month, startMondayA.day);
    final startMondayB = b.subtract(Duration(days: b.weekday - 1));
    final weekStartB = DateTime(startMondayB.year, startMondayB.month, startMondayB.day);
    return weekStartA == weekStartB;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime get _currentPeriodStart {
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      return DateTime(now.year, now.month, now.day, 0, 0, 0);
    }
    if (_selectedPeriod == 'This Week') {
      final startMonday = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(startMonday.year, startMonday.month, startMonday.day, 0, 0, 0);
    }
    if (_selectedPeriod == 'This Month') {
      return DateTime(now.year, now.month, 1, 0, 0, 0);
    }
    return DateTime(2000, 1, 1, 0, 0, 0);
  }

  DateTime get _currentPeriodEnd {
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    if (_selectedPeriod == 'This Week') {
      final startMonday = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startMonday.year, startMonday.month, startMonday.day, 0, 0, 0);
      return DateTime(weekStart.year, weekStart.month, weekStart.day, 23, 59, 59).add(const Duration(days: 6));
    }
    if (_selectedPeriod == 'This Month') {
      return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
    return DateTime(2100, 1, 1, 0, 0, 0);
  }

  int _sessionDurationInPeriod(WorkSession session, DateTime periodStart, DateTime periodEnd) {
    final sStart = session.startTime;
    final sEnd = session.endTime ?? DateTime.now();

    final intStart = sStart.isAfter(periodStart) ? sStart : periodStart;
    final intEnd = sEnd.isBefore(periodEnd) ? sEnd : periodEnd;

    if (intStart.isBefore(intEnd)) {
      return intEnd.difference(intStart).inSeconds;
    }
    return 0;
  }

  List<WorkSession> get _visibleSessions {
    final now = DateTime.now();
    return _sessions.where((session) {
      final start = session.startTime;
      if (_selectedPeriod == 'Today') {
        if (session.isActive) return true;
        return _isSameDay(start, now);
      }
      if (_selectedPeriod == 'This Week') {
        if (session.isActive) return true;
        return _isSameWeek(start, now);
      }
      if (_selectedPeriod == 'This Month') {
        if (session.isActive) return true;
        return _isSameMonth(start, now);
      }
      return true;
    }).toList();
  }

  List<TaskItem> _tasksForCurrentUser(TaskState state) {
    final currentId = _currentUser?.id.toString().trim().toLowerCase() ?? '';
    final currentFullName = _profile?['full_name']?.toString().trim().toLowerCase() ?? '';
    final currentEmail = _currentUser?.email?.toString().trim().toLowerCase() ?? '';

    bool containsValue(String source, String value) {
      return value.isNotEmpty && source.contains(value);
    }

    return state.tasks.where((task) {
      final ownerRaw = task.owner?.toString().trim().toLowerCase() ?? '';
      if (ownerRaw.isNotEmpty) {
        final matchesOwner = ownerRaw == currentId ||
            ownerRaw == currentFullName ||
            ownerRaw == currentEmail ||
            containsValue(ownerRaw, currentFullName) ||
            containsValue(ownerRaw, currentEmail);
        if (!matchesOwner) return false;
      }
      return true;
    }).toList();
  }

  List<TaskItem> _visibleTasks(TaskState state) {
    final tasks = _tasksForCurrentUser(state);
    final now = DateTime.now();
    return tasks.where((t) {
      final date = t.dueDate ?? now;
      if (t.dueDate == null) return true;
      if (_selectedPeriod == 'Today') return _isSameDay(date, now);
      if (_selectedPeriod == 'This Week') return _isSameWeek(date, now);
      if (_selectedPeriod == 'This Month') return _isSameMonth(date, now);
      return true;
    }).toList();
  }

  List<TaskItem> _tasksForSession(WorkSession session, List<TaskItem> tasks) {
    return tasks.where((t) {
      final date = t.dueDate ?? DateTime.now();
      return _isSameDay(date, session.startTime);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, taskState) {
          final visibleTasks = _visibleTasks(taskState);
          final tasksDoneCount = visibleTasks.where((t) => t.status == TaskStatus.done).length;

          final totalSeconds = _visibleSessions.fold<int>(0, (sum, session) => sum + _sessionDurationInPeriod(session, _currentPeriodStart, _currentPeriodEnd));
          final totalBreakMinutes = _visibleSessions.fold<int>(0, (sum, session) => sum + session.breakMinutes);
          final productiveSeconds = totalSeconds - (totalBreakMinutes * 60);
          final actualSeconds = productiveSeconds > 0 ? productiveSeconds : 0;
          
          final h = actualSeconds ~/ 3600;
          final m = (actualSeconds % 3600) ~/ 60;
          final productiveTimeString = '${h}h ${m}m';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(),
                const SizedBox(height: 12),
                Text('My Timesheet',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                Text(
                    'Evaluate your daily sign-ins, breaks, and completed tasks.',
                    style: TextStyle(
                        fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
                const SizedBox(height: 20),
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildSummaryCards(productiveTimeString, tasksDoneCount),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                else if (_visibleSessions.isEmpty)
                  _buildEmptyState()
                else
                  ..._visibleSessions.map((session) {
                    final sessionTasks = _tasksForSession(session, visibleTasks);
                    return _buildSessionCard(session, sessionTasks);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.home_outlined, size: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
        Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
        Text('Dashboard',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
        const Text('Timesheet',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF2196F3))),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            ['Today', 'This Week', 'This Month', 'All Time'].map((p) {
          final sel = _selectedPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : (isDark ? AppTheme.bgCardDark : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF2196F3)
                        : (isDark ? AppTheme.borderDark : Colors.grey[300]!)),
              ),
              child: Text(p,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? const Color(0xFF2196F3)
                          : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(String productiveTime, int tasksDone) {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 600) {
        return Column(
          children: [
            _statCard(Icons.access_time_rounded, 'PRODUCTIVE TIME', productiveTime, const Color(0xFF2196F3)),
            const SizedBox(height: 10),
            _statCard(Icons.check_box_outlined, 'TASKS DONE', '$tasksDone', const Color(0xFF10B981)),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _statCard(Icons.access_time_rounded, 'PRODUCTIVE TIME', productiveTime, const Color(0xFF2196F3))),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.check_box_outlined, 'TASKS DONE', '$tasksDone', const Color(0xFF10B981))),
        ],
      );
    });
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(fontSize: 20, color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 48, color: isDark ? const Color(0xFF334155) : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No sessions found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('There are no work sessions recorded for this period.',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSessionCard(WorkSession session, List<TaskItem> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isActive = session.isActive;
    final statusColor = isActive ? const Color(0xFF2196F3) : const Color(0xFF10B981);
    
    final sessionSecs = session.duration.inSeconds;
    final prodSecs = sessionSecs - (session.breakMinutes * 60);
    final finalSecs = prodSecs > 0 ? prodSecs : 0;
    final h = finalSecs ~/ 3600;
    final m = (finalSecs % 3600) ~/ 60;
    final totalString = '${h}h ${m}m total';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.borderDark) : Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_outlined,
                      color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMMEEEEd().format(session.startTime),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(session.displayStatus,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text(totalString,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppTheme.borderDark : Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShiftDetails(session),
                    const SizedBox(height: 12),
                    _buildBreakDetails(session),
                    const SizedBox(height: 12),
                    _buildTaskDetails(tasks),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildShiftDetails(session)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBreakDetails(session)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTaskDetails(tasks)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDetails(WorkSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SHIFT DETAILS',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        _shiftRow(Icons.login, const Color(0xFF4CAF50), 'Sign In', session.signIn),
        if (session.endTime != null) ...[
          const SizedBox(height: 8),
          _shiftRow(Icons.logout, Colors.red, 'Sign Off', session.signOut),
        ],
      ],
    );
  }

  Widget _shiftRow(IconData icon, Color color, String label, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(time, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakDetails(WorkSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BREAKS (${session.breakMinutes}M)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600], letterSpacing: 0.5)),
            Icon(Icons.coffee_outlined, size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 10),
        if (session.breakMinutes == 0)
          Text('No breaks taken.', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF596780) : Colors.grey[400]))
        else
          Text('${session.breakMinutes} minutes break taken.', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _buildTaskDetails(List<TaskItem> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ASSIGNED & SELF TASKS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600], letterSpacing: 0.5)),
            Icon(Icons.edit_outlined, size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Text('No tasks for this day.', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF596780) : Colors.grey[400]))
        else
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        t.status == TaskStatus.done ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                        size: 14,
                        color: t.status == TaskStatus.done ? Colors.green : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[400])),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.summary, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                          Text('${t.parentProject?.isNotEmpty == true ? t.parentProject : 'Self Task'} • ${t.status.label}', style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
      ],
    );
  }
}