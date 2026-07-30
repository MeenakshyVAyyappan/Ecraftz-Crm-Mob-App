import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../services/supabase_service.dart';


// ─── Data Models ────────────────────────────────────────────────────────────

enum TimesheetStatus { completed, inProgress, absent }

class TimesheetEntry {
  final String employeeName;
  final String role;
  final String? avatarInitials;
  final Color avatarColor;
  final DateTime date;
  final TimeOfDay? signIn;
  final TimeOfDay? signOut;
  final Duration duration;
  final int breakMinutes;
  final int tasksDone;
  final int tasksTotal;
  final TimesheetStatus status;
  final String department;

  const TimesheetEntry({
    required this.employeeName,
    required this.role,
    this.avatarInitials,
    required this.avatarColor,
    required this.date,
    this.signIn,
    this.signOut,
    required this.duration,
    required this.breakMinutes,
    required this.tasksDone,
    required this.tasksTotal,
    required this.status,
    required this.department,
  });

  factory TimesheetEntry.fromSupabase(Map<String, dynamic> row, {Map<String, dynamic>? profile, int breakMinutes = 0}) {
    final fullName = (profile != null && profile['full_name'] != null)
        ? profile['full_name'].toString()
        : (row['employee_name']?.toString() ?? row['full_name']?.toString() ?? '');
    final role = (profile != null && profile['role'] != null) ? profile['role'].toString() : (row['role']?.toString() ?? 'EMPLOYEE');
    
    final profileDept = profile != null
        ? (profile['departments'] != null
            ? profile['departments']['name']?.toString()
            : profile['department']?.toString())
        : null;
    final department = profileDept ?? row['department']?.toString() ?? 'No Department';

    DateTime? startedAt;
    DateTime? endedAt;

    // CORRECTED: Actual columns are start_time and end_time (not started_at/ended_at)
    if (row['start_time'] != null) {
      try { startedAt = DateTime.parse(row['start_time'].toString()); } catch (_) {}
    }
    if (row['end_time'] != null) {
      try { endedAt = DateTime.parse(row['end_time'].toString()); } catch (_) {}
    }

    TimeOfDay? signIn = startedAt != null ? TimeOfDay(hour: startedAt.hour, minute: startedAt.minute) : null;
    TimeOfDay? signOut = endedAt != null ? TimeOfDay(hour: endedAt.hour, minute: endedAt.minute) : null;

    Duration duration = Duration.zero;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt);
    } else if (startedAt != null && endedAt == null) {
      // Active session: duration is from start until now
      duration = DateTime.now().difference(startedAt);
    }

    // Use the status from DB if available, otherwise derive it
    final dbStatus = (row['status']?.toString() ?? '').toLowerCase();
    final TimesheetStatus status;
    
    if (startedAt == null) {
      status = TimesheetStatus.absent;
    } else if (dbStatus == 'completed' && endedAt != null) {
      status = TimesheetStatus.completed;
    } else if (endedAt != null) {
      status = TimesheetStatus.completed;
    } else {
      status = TimesheetStatus.inProgress;
    }

    final avatarInitials = (fullName.isNotEmpty ? fullName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join() : null);

    print('✓ Loaded: $fullName | $startedAt → $endedAt | status=$status | breaks=$breakMinutes min');

    return TimesheetEntry(
      employeeName: fullName.isNotEmpty ? fullName : 'Unknown',
      role: role.toUpperCase(),
      avatarInitials: avatarInitials,
      avatarColor: Colors.blueGrey,
      date: startedAt ?? DateTime.now(),
      signIn: signIn,
      signOut: signOut,
      duration: duration,
      breakMinutes: breakMinutes,
      tasksDone: 0,
      tasksTotal: 0,
      status: status,
      department: department,
    );
  }
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

// Data will be loaded from Supabase `work_sessions` and `break_sessions` tables.

final List<String> departments = [
  'All Departments',
  'BDE',
  'Content Writer',
  'CRM',
  'Digital Marketing',
  'Graphic Designing',
  'Video Editing',
  'Videography',
  'Web Developing',
];

// ─── Main Screen ─────────────────────────────────────────────────────────────

class TeamTimesheetsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const TeamTimesheetsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<TeamTimesheetsScreen> createState() => _TeamTimesheetsScreenState();
}

class _TeamTimesheetsScreenState extends State<TeamTimesheetsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'All Departments';
  String? _selectedStatus;
  late DateTime _selectedDate;
  String _searchQuery = '';
  List<TimesheetEntry> _entries = [];
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _allProjects = [];
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    // Initialize to today's date
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _loadSessions();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted => AppTheme.textMutedOf(context);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TimesheetEntry> get _filteredEntries {
    return _entries.where((e) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.employeeName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDepartment == 'All Departments' ||
          e.department == _selectedDepartment;
      final matchesStatus =
          _selectedStatus == null ||
          (_selectedStatus == 'Completed' &&
              e.status == TimesheetStatus.completed) ||
          (_selectedStatus == 'In Progress' &&
              e.status == TimesheetStatus.inProgress);
      // Filter by selected date (compare only date part, not time)
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      final matchesDate = entryDate == _selectedDate;
      return matchesSearch && matchesDept && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _loadSessions() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final client = SupabaseService.client;
      
      // Load projects
      final projectsRaw = await client.from('projects').select().isFilter('deleted_at', null);
      final fetchedProjects = (projectsRaw as List).cast<Map<String, dynamic>>();

      // Load tasks
      final tasksRaw = await client.from('tasks').select().isFilter('deleted_at', null);
      final fetchedTasks = (tasksRaw as List).cast<Map<String, dynamic>>();

      // Query work_sessions with full record to see actual schema
      final rowsRaw = await client.from('work_sessions').select();
      final rows = (rowsRaw as List).cast<Map<String, dynamic>>();

      print('SCHEMA: work_sessions found ${rows.length} rows');
      if (rows.isNotEmpty) {
        print('SCHEMA: First row keys = ${rows.first.keys.toList()}');
      }
      
      if (rows.isEmpty) {
        setState(() {
          _entries = [];
          _allProjects = fetchedProjects;
          _allTasks = fetchedTasks;
          _profiles = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch and join profiles
      final profileIds = rows.map((r) => r['user_id']?.toString()).where((id) => id != null).cast<String>().toSet().toList();
      Map<String, Map<String, dynamic>> profileMap = {};
      List<Map<String, dynamic>> fetchedProfiles = [];
      if (profileIds.isNotEmpty) {
        final profRaw = await client.from('profiles').select('*, departments:departments!fk_profiles_dept(id, name)');
        fetchedProfiles = (profRaw as List).cast<Map<String, dynamic>>();
        for (final p in fetchedProfiles) {
          final uid = p['id']?.toString();
          if (uid != null) profileMap[uid] = p;
        }
      }

      // Fetch and aggregate break sessions
      final sessionIds = rows.map((r) => r['id']?.toString()).where((id) => id != null).cast<String>().toList();
      Map<String, int> breakMap = {};
      if (sessionIds.isNotEmpty) {
        final brRaw = await client.from('break_sessions').select();
        final breaksAll = (brRaw as List).cast<Map<String, dynamic>>();
        for (final b in breaksAll) {
          final sid = b['work_session_id']?.toString() ?? '';
          if (sessionIds.contains(sid)) {
            int minutes = 0;
            if (b.containsKey('duration_minutes')) minutes = (b['duration_minutes'] is num) ? (b['duration_minutes'] as num).toInt() : int.tryParse(b['duration_minutes'].toString()) ?? 0;
            else if (b.containsKey('minutes')) minutes = (b['minutes'] is num) ? (b['minutes'] as num).toInt() : int.tryParse(b['minutes'].toString()) ?? 0;
            else if (b.containsKey('duration')) minutes = (b['duration'] is num) ? (b['duration'] as num).toInt() : int.tryParse(b['duration'].toString()) ?? 0;
            breakMap[sid] = (breakMap[sid] ?? 0) + minutes;
          }
        }
      }

      // Map rows to TimesheetEntry, passing profile data
      final mapped = rows.map((r) {
        final id = r['id']?.toString() ?? '';
        final uid = r['user_id']?.toString() ?? '';
        final profile = profileMap[uid];
        final bm = breakMap[id] ?? 0;
        return TimesheetEntry.fromSupabase(r, profile: profile, breakMinutes: bm);
      }).toList();

      setState(() {
        _entries = mapped;
        _allProjects = fetchedProjects;
        _allTasks = fetchedTasks;
        _profiles = fetchedProfiles;
        _isLoading = false;
      });
    } catch (e, st) {
      print('ERROR loading sessions: $e');
      print(st);
      setState(() { _isLoading = false; _loadError = e.toString(); });
    }
  }

  List<String> get _matchingProfileIdsForStats {
    if (_selectedDepartment == 'All Departments') {
      return _profiles.map((p) => p['id']?.toString() ?? '').toList();
    }
    return _profiles.where((p) {
      final deptMap = p['departments'];
      final deptName = deptMap != null ? (deptMap['name']?.toString() ?? 'No Department') : 'No Department';
      return deptName == _selectedDepartment;
    }).map((p) => p['id']?.toString() ?? '').toList();
  }

  List<Map<String, dynamic>> get _filteredProjectsForStats {
    final profileIds = _matchingProfileIdsForStats;
    return _allProjects.where((proj) {
      final projId = proj['id']?.toString() ?? '';

      // 1. Department Filter
      if (_selectedDepartment != 'All Departments') {
        final projectTasks = _allTasks.where((t) => t['project_id']?.toString() == projId);
        final hasDeptAssignee = projectTasks.any((t) {
          final assignedTo = t['assigned_to']?.toString();
          return assignedTo != null && profileIds.contains(assignedTo);
        });
        if (!hasDeptAssignee) return false;
      }

      // 2. Date Filter
      DateTime? projDate;
      if (proj['start_date'] != null) {
        projDate = DateTime.tryParse(proj['start_date'].toString());
      } else if (proj['created_at'] != null) {
        projDate = DateTime.tryParse(proj['created_at'].toString());
      }
      if (projDate != null) {
        final dayOnly = DateTime(projDate.year, projDate.month, projDate.day);
        final filterDayOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        if (dayOnly != filterDayOnly) return false;
      }

      // 3. Status Filter
      if (_selectedStatus != null) {
        final projStatus = (proj['status']?.toString() ?? '').toLowerCase();
        if (_selectedStatus == 'Completed' && projStatus != 'completed') return false;
        if (_selectedStatus == 'In Progress' && projStatus != 'in_progress') return false;
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredTasksForStats {
    final profileIds = _matchingProfileIdsForStats;
    return _allTasks.where((task) {
      // 1. Department Filter
      final assignedTo = task['assigned_to']?.toString();
      if (_selectedDepartment != 'All Departments') {
        if (assignedTo == null || !profileIds.contains(assignedTo)) {
          return false;
        }
      }

      // 2. Date Filter
      DateTime? taskDate;
      if (task['due_date'] != null) {
        taskDate = DateTime.tryParse(task['due_date'].toString());
      } else if (task['created_at'] != null) {
        taskDate = DateTime.tryParse(task['created_at'].toString());
      }
      if (taskDate != null) {
        final dayOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
        final filterDayOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        if (dayOnly != filterDayOnly) return false;
      }

      // 3. Status Filter
      if (_selectedStatus != null) {
        final taskStatus = (task['status']?.toString() ?? '').toLowerCase();
        if (_selectedStatus == 'Completed' && taskStatus != 'done') return false;
        if (_selectedStatus == 'In Progress' && taskStatus != 'in_progress' && taskStatus != 'todo') return false;
      }

      return true;
    }).toList();
  }

  List<TimesheetEntry> get _filteredSessionsForStats {
    return _entries.where((e) {
      // 1. Department Filter
      if (_selectedDepartment != 'All Departments' && e.department != _selectedDepartment) {
        return false;
      }

      // 2. Date Filter
      final eDate = DateTime(e.date.year, e.date.month, e.date.day);
      final filterDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (eDate != filterDate) return false;

      // 3. Status Filter
      if (_selectedStatus != null) {
        if (_selectedStatus == 'Completed' && e.status != TimesheetStatus.completed) return false;
        if (_selectedStatus == 'In Progress' && e.status != TimesheetStatus.inProgress) return false;
      }

      return true;
    }).toList();
  }

  int get totalProjectsCount => _filteredProjectsForStats.length;

  int get completedProjectsCount {
    return _filteredProjectsForStats.where((p) {
      final statusStr = (p['status']?.toString() ?? '').toLowerCase();
      return statusStr == 'completed';
    }).length;
  }

  int get totalTasksCount => _filteredTasksForStats.length;

  int get totalHoursCount {
    final sessions = _filteredSessionsForStats;
    return sessions.fold<int>(0, (sum, e) => sum + e.duration.inHours);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _showDepartmentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepartmentPicker(
        departments: departments,
        selected: _selectedDepartment,
        onSelect: (d) {
          setState(() => _selectedDepartment = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusPicker(
        selected: _selectedStatus,
        onSelect: (s) {
          setState(() => _selectedStatus = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEvaluateMenu(BuildContext context, TimesheetEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EvaluateMenu(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: _isDark ? Colors.white : const Color(0xFF1E293B)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(
          'Team Timesheets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        actions: [
          AppRefreshButton(
            onRefresh: () async {
              await _loadSessions();
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            color: _textSecondary,
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header description ──
          Container(
            color: _cardBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluate and audit organization-wide daily sign-ins, breaks, and tasks.',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: _textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: _textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: _textMuted,
                    ),
                    filled: true,
                    fillColor: _isDark ? const Color(0xFF132238) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        icon: Icons.business_outlined,
                        label: _selectedDepartment == 'All Departments'
                            ? 'All Departments'
                            : _selectedDepartment,
                        onTap: _showDepartmentPicker,
                        active: _selectedDepartment != 'All Departments',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat('MMM d, yyyy').format(_selectedDate),
                        onTap: _pickDate,
                        active: true,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        icon: Icons.filter_list_rounded,
                        label: _selectedStatus ?? 'Status',
                        onTap: _showStatusPicker,
                        active: _selectedStatus != null,
                      ),
                      if (_selectedDepartment != 'All Departments' ||
                          _selectedStatus != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedDepartment = 'All Departments';
                            _selectedStatus = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Summary bar ──
          if (_loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to load timesheets: $_loadError', style: const TextStyle(color: Colors.red))),
                  TextButton(onPressed: _loadSessions, child: const Text('Retry')),
                ],
              ),
            ),
          _SummaryBar(
            totalProjects: totalProjectsCount,
            completedProjects: completedProjectsCount,
            totalHours: totalHoursCount,
            totalTasks: totalTasksCount,
          ),
          // ── List ──
          Expanded(
            child: Builder(
              builder: (ctx) {
                if (_isLoading) return const Center(child: CircularProgressIndicator());
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No timesheets found',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Main list (wrap with RefreshIndicator for pull-to-refresh)
                if (isTablet) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: ((w - 32 - 12) / 2) / 210.0,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _TimesheetCard(
                      entry: filtered[i],
                      formatDuration: _formatDuration,
                      formatTime: _formatTime,
                      onEvaluate: () => _showEvaluateMenu(ctx, filtered[i]),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _TimesheetCard(
                    entry: filtered[i],
                    formatDuration: _formatDuration,
                    formatTime: _formatTime,
                    onEvaluate: () => _showEvaluateMenu(ctx, filtered[i]),
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: () => _showQuickCreate(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showQuickCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickCreateSheet(onItemSelected: widget.onItemSelected),
    );
  }
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int totalProjects;
  final int completedProjects;
  final int totalHours;
  final int totalTasks;

  const _SummaryBar({
    required this.totalProjects,
    required this.completedProjects,
    required this.totalHours,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardBg = Theme.of(context).colorScheme.surface;

    return Container(
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          _SummaryStat(
            label: 'Projects',
            value: '$totalProjects',
            color: const Color(0xFF0EA5E9),
          ),
          _divider(context, w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'Completed',
            value: '$completedProjects',
            color: const Color(0xFF10B981),
          ),
          _divider(context, w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'Total Hours',
            value: '${totalHours}h',
            color: const Color(0xFF8B5CF6),
          ),
          _divider(context, w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'Total Tasks',
            value: '$totalTasks',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context, double horizontalMargin) => Container(
    width: 1,
    height: 28,
    color: AppTheme.borderOf(context),
    margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
  );
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isCompact = w < 360;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 15 : 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: isCompact ? 9 : 11, color: AppTheme.textSecondaryOf(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = AppTheme.textSecondaryOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF0F2547) : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: const Color(0xFF0EA5E9), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? const Color(0xFF0EA5E9)
                  : (isDark ? textSecondary : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active
                    ? (isDark ? Colors.white : const Color(0xFF0369A1))
                    : (isDark ? textSecondary : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: active
                  ? const Color(0xFF0EA5E9)
                  : (isDark ? textSecondary : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timesheet Card ───────────────────────────────────────────────────────────

class _TimesheetCard extends StatelessWidget {
  final TimesheetEntry entry;
  final String Function(Duration) formatDuration;
  final String Function(TimeOfDay?) formatTime;
  final VoidCallback onEvaluate;

  const _TimesheetCard({
    required this.entry,
    required this.formatDuration,
    required this.formatTime,
    required this.onEvaluate,
  });

  Color _statusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (entry.status) {
      case TimesheetStatus.completed:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case TimesheetStatus.inProgress:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      case TimesheetStatus.absent:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    }
  }

  Color _statusBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (entry.status) {
      case TimesheetStatus.completed:
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      case TimesheetStatus.inProgress:
        return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      case TimesheetStatus.absent:
        return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
    }
  }

  String get _statusLabel {
    switch (entry.status) {
      case TimesheetStatus.completed:
        return 'COMPLETED';
      case TimesheetStatus.inProgress:
        return 'IN PROGRESS';
      case TimesheetStatus.absent:
        return 'ABSENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(entry.date);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: border) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: entry.avatarColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.avatarInitials ?? entry.employeeName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: entry.avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.employeeName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        entry.role,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Divider ──
          Container(height: 1, color: border),
          // ── Stats Grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: dateStr,
                    ),
                    _StatItem(
                      icon: Icons.access_time_rounded,
                      label: 'Sign In',
                      value: formatTime(entry.signIn),
                    ),
                    _StatItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      value: formatTime(entry.signOut),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: formatDuration(entry.duration),
                      valueColor: const Color(0xFF0EA5E9),
                    ),
                    _StatItem(
                      icon: Icons.coffee_outlined,
                      label: 'Breaks',
                      value: entry.breakMinutes == 0
                          ? 'None'
                          : '${entry.breakMinutes}m',
                    ),
                    _StatItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Tasks Done',
                      value: '${entry.tasksDone} / ${entry.tasksTotal}',
                      valueColor: entry.tasksDone == entry.tasksTotal &&
                              entry.tasksTotal > 0
                          ? const Color(0xFF10B981)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Footer / Evaluate Button ──
          Container(
            height: 1,
            color: border,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 13,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.department,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onEvaluate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F2547) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Evaluate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: isDark ? Colors.white : const Color(0xFF1D4ED8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.textMutedOf(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimaryOf(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Department Picker ────────────────────────────────────────────────────────

class _DepartmentPicker extends StatelessWidget {
  final List<String> departments;
  final String selected;
  final ValueChanged<String> onSelect;
  const _DepartmentPicker({
    required this.departments,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Department',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...departments.map(
            (d) => ListTile(
              onTap: () => onSelect(d),
              title: Text(
                d,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: d == selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: d == selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Status Picker ────────────────────────────────────────────────────────────

class _StatusPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _StatusPicker({this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);
    const statuses = ['Completed', 'In Progress', 'Absent'];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            onTap: () => onSelect(null),
            title: Text(
              'All',
              style: TextStyle(fontSize: 14, color: textPrimary),
            ),
            trailing: selected == null
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 18,
                  )
                : null,
          ),
          ...statuses.map(
            (s) => ListTile(
              onTap: () => onSelect(s),
              title: Text(
                s,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: s == selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: s == selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Evaluate Menu ────────────────────────────────────────────────────────────

class _EvaluateMenu extends StatelessWidget {
  final TimesheetEntry entry;
  const _EvaluateMenu({required this.entry});

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.employeeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MenuOption(
            icon: Icons.list_alt_outlined,
            label: 'View Detailed Log',
            onTap: () {
              Navigator.pop(context);
              _showDetailedLog(context, entry);
            },
          ),
          _MenuOption(
            icon: Icons.edit_outlined,
            label: 'Adjust Time',
            onTap: () {
              Navigator.pop(context);
              _showAdjustTime(context, entry);
            },
          ),
          _MenuOption(
            icon: Icons.flag_outlined,
            label: 'Flag Shift',
            labelColor: const Color(0xFFEF4444),
            iconColor: const Color(0xFFEF4444),
            onTap: () {
              Navigator.pop(context);
              AppSnackBar.showCustom(context, 
                SnackBar(
                  content: Text('Shift flagged for ${entry.employeeName}'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDetailedLog(BuildContext context, TimesheetEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailedLogScreen(entry: entry),
      ),
    );
  }

  void _showAdjustTime(BuildContext context, TimesheetEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdjustTimeSheet(entry: entry),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.borderOf(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 20,
        color: iconColor ?? textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: labelColor ?? textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: border,
      ),
    );
  }
}

// ─── Detailed Log Screen ─────────────────────────────────────────────────────

class _DetailedLogScreen extends StatelessWidget {
  final TimesheetEntry entry;
  const _DetailedLogScreen({required this.entry});

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  Color _cardBg(BuildContext context) => Theme.of(context).colorScheme.surface;
  Color _border(BuildContext context) => AppTheme.borderOf(context);
  Color _textPrimary(BuildContext context) => AppTheme.textPrimaryOf(context);
  Color _textSecondary(BuildContext context) => AppTheme.textSecondaryOf(context);

  Color _statusColor(BuildContext context) {
    final isDark = _isDark(context);
    switch (entry.status) {
      case TimesheetStatus.completed:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case TimesheetStatus.inProgress:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case TimesheetStatus.absent:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    }
  }

  Color _statusBg(BuildContext context) {
    final isDark = _isDark(context);
    switch (entry.status) {
      case TimesheetStatus.completed:
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      case TimesheetStatus.inProgress:
        return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      case TimesheetStatus.absent:
        return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
    }
  }

  String get _statusLabel {
    switch (entry.status) {
      case TimesheetStatus.completed:
        return 'COMPLETED';
      case TimesheetStatus.inProgress:
        return 'IN PROGRESS';
      case TimesheetStatus.absent:
        return 'ABSENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(entry.date);
    final signIn = entry.signIn != null
        ? '${entry.signIn!.hour.toString().padLeft(2, '0')}:${entry.signIn!.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    final signOut = entry.signOut != null
        ? '${entry.signOut!.hour.toString().padLeft(2, '0')}:${entry.signOut!.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    final duration =
        '${entry.duration.inHours}h ${entry.duration.inMinutes.remainder(60)}m';

    final textPrimaryColor = _textPrimary(context);
    final textSecondaryColor = _textSecondary(context);
    final cardBgColor = _cardBg(context);
    final isDarkTheme = _isDark(context);
    final borderColor = _border(context);

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detailed Log',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimaryColor,
          ),
        ),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: isDarkTheme ? Border.all(color: borderColor) : null,
                boxShadow: isDarkTheme ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entry.avatarColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.avatarInitials ??
                          entry.employeeName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: entry.avatarColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.employeeName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${entry.role} • ${entry.department}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Shift Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            _DetailRow(label: 'Date', value: dateStr),
            _DetailRow(label: 'Sign In', value: signIn),
            _DetailRow(label: 'Sign Out', value: signOut),
            _DetailRow(label: 'Total Duration', value: duration),
            _DetailRow(
              label: 'Break Time',
              value: entry.breakMinutes == 0
                  ? 'None'
                  : '${entry.breakMinutes} minutes',
            ),
            _DetailRow(
              label: 'Tasks',
              value: '${entry.tasksDone} / ${entry.tasksTotal} completed',
            ),
            _DetailRow(
              label: 'Status',
              value: _statusLabel,
              isStatus: true,
              statusBg: _statusBg(context),
              statusColor: _statusColor(context),
            ),
            const SizedBox(height: 20),
            Text(
              'Activity Timeline',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _TimelineItem(
              time: signIn,
              label: 'Signed In',
              color: const Color(0xFF10B981),
            ),
            if (entry.breakMinutes > 0) ...[
              _TimelineItem(
                time: '—',
                label: 'Break taken (${entry.breakMinutes}m)',
                color: const Color(0xFFF59E0B),
              ),
            ],
            if (entry.tasksDone > 0)
              _TimelineItem(
                time: '—',
                label: '${entry.tasksDone} task(s) completed',
                color: const Color(0xFF8B5CF6),
              ),
            _TimelineItem(
              time: signOut,
              label: 'Signed Out',
              color: const Color(0xFFEF4444),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;
  final Color? statusBg;
  final Color? statusColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isStatus = false,
    this.statusBg,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = AppTheme.borderOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: isDark ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg ?? const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor ?? const Color(0xFF059669),
                    ),
                  ),
                )
              : Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String label;
  final Color color;
  final bool isLast;
  const _TimelineItem({
    required this.time,
    required this.label,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.borderOf(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Adjust Time Sheet ────────────────────────────────────────────────────────

class _AdjustTimeSheet extends StatefulWidget {
  final TimesheetEntry entry;
  const _AdjustTimeSheet({required this.entry});

  @override
  State<_AdjustTimeSheet> createState() => _AdjustTimeSheetState();
}

class _AdjustTimeSheetState extends State<_AdjustTimeSheet> {
  late TextEditingController _signInCtrl;
  late TextEditingController _signOutCtrl;
  late TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _signInCtrl = TextEditingController(
      text: e.signIn != null
          ? '${e.signIn!.hour.toString().padLeft(2, '0')}:${e.signIn!.minute.toString().padLeft(2, '0')}'
          : '',
    );
    _signOutCtrl = TextEditingController(
      text: e.signOut != null
          ? '${e.signOut!.hour.toString().padLeft(2, '0')}:${e.signOut!.minute.toString().padLeft(2, '0')}'
          : '',
    );
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _signInCtrl.dispose();
    _signOutCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adjust Time',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.entry.employeeName,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 20),
              _FormLabel('Sign In Time'),
              const SizedBox(height: 6),
              _TimeField(controller: _signInCtrl),
              const SizedBox(height: 14),
              _FormLabel('Sign Out Time'),
              const SizedBox(height: 6),
              _TimeField(controller: _signOutCtrl),
              const SizedBox(height: 14),
              _FormLabel('Reason for Adjustment'),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF132238) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppSnackBar.showCustom(context, 
                      const SnackBar(
                        content: Text('Time adjusted successfully'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondaryOf(context),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  const _TimeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      style: TextStyle(color: textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'HH:MM',
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        prefixIcon: Icon(
          Icons.access_time_rounded,
          size: 18,
          color: textMuted,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF132238) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}

// ─── Quick Create Sheet ───────────────────────────────────────────────────────

class _QuickCreateSheet extends StatelessWidget {
  final Function(int) onItemSelected;
  const _QuickCreateSheet({required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.borderOf(context);
    final cardBg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    const options = [
      (Icons.person_add_outlined, 'New Lead', Color(0xFF0EA5E9)),
      (Icons.folder_open_outlined, 'New Project', Color(0xFF8B5CF6)),
      (Icons.receipt_long_outlined, 'New Invoice', Color(0xFF10B981)),
      (Icons.task_outlined, 'New Task', Color(0xFFF59E0B)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Create',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...options.map(
            (o) => ListTile(
              onTap: () {
                Navigator.pop(context);
                if (o.$2 == 'New Lead') {
                  onItemSelected(1);
                } else if (o.$2 == 'New Project') {
                  onItemSelected(4);
                } else if (o.$2 == 'New Invoice') {
                  onItemSelected(7);
                } else if (o.$2 == 'New Task') {
                  onItemSelected(5);
                }
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: o.$3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(o.$1, size: 18, color: o.$3),
              ),
              title: Text(
                o.$2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
