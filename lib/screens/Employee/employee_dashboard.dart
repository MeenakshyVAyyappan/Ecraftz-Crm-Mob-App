import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../models/task_model.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'emply_project_screen.dart';
import 'emply_tasks_screen.dart';
import 'emply_my_timesheet.dart';
import 'emply_leave_request.dart';

enum DashboardViewPeriod { day, week, month }

class WorkSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int breakMinutes;

  WorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.breakMinutes = 0,
  });

  bool get isActive {
    final lower = status.toLowerCase().trim();
    return endTime == null && !['completed', 'done', 'finished', 'checked_out'].contains(lower);
  }

  Duration get duration => endTime?.difference(startTime) ?? DateTime.now().difference(startTime);
  String get signIn => DateFormat('hh:mm a').format(startTime);
  String get signOut => endTime != null ? DateFormat('hh:mm a').format(endTime!) : '--:--';
  String get displayStatus {
    final lower = status.toLowerCase();
    if (isActive) return 'WORKING';
    if (lower == 'completed') return 'COMPLETED';
    if (lower == 'absent') return 'ABSENT';
    return status.toUpperCase();
  }

  factory WorkSession.fromMap(Map<String, dynamic> json, {int breakMinutes = 0}) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return WorkSession(
      id: json['id']?.toString() ?? '',
      startTime: parseDate(json['start_time']?.toString())?.toLocal() ?? DateTime.now().toLocal(),
      endTime: parseDate(json['end_time']?.toString())?.toLocal(),
      status: json['status']?.toString() ?? 'working',
      breakMinutes: breakMinutes,
    );
  }
}

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const EmployeeDashboardContent(),
      const ProjectsScreen(),
      const EmployeeTasksScreen(),
      const MyTimesheetScreen(),
      const LeaveRequestsScreen(),
    ];
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Projects';
      case 2:
        return 'Tasks';
      case 3:
        return 'My Timesheet';
      case 4:
        return 'Leave Requests';
      default:
        return '';
    }
  }

  String _getPageSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Operational command center';
      case 1:
        return 'Manage active and archived projects';
      case 2:
        return 'Track and update your assigned tasks';
      case 3:
        return 'Evaluate your daily sign-ins and tasks';
      case 4:
        return 'Manage your time off and track approvals';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;

    Widget mainContent = IndexedStack(
      index: _selectedIndex,
      children: _pages,
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            Container(
              width: 270,
              color: AppTheme.bgSidebar,
              child: SafeArea(
                child: _buildSidebarContents(context),
              ),
            ),
            Expanded(
              child: Scaffold(
                key: _scaffoldKey,
                appBar: _buildSharedAppBar(context, isDesktop),
                body: mainContent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 270,
        backgroundColor: AppTheme.bgSidebar,
        child: SafeArea(
          child: _buildSidebarContents(context),
        ),
      ),
      appBar: _buildSharedAppBar(context, isDesktop),
      body: mainContent,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildSharedAppBar(BuildContext context, bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: isDesktop
          ? null
          : IconButton(
              icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF2C3E50), size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getPageTitle(_selectedIndex),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            _getPageSubtitle(_selectedIndex),
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final isDarkTheme = state.themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(
                isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDarkTheme ? Colors.white : const Color(0xFF2C3E50),
              ),
              onPressed: () {
                context.read<ThemeBloc>().add(ToggleThemeEvent());
              },
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : const Color(0xFF2C3E50)),
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.sidebarAccent,
                radius: 15,
                child: const Text(
                  'JD',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'EMPLOYEE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.borderOf(context), height: 1),
      ),
    );
  }

  Widget _buildSidebarContents(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/ecraftzlogolight.png',
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _buildNavItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavItem(context, 1, Icons.folder_outlined, 'Projects'),
              _buildNavItem(context, 2, Icons.check_circle_outline_rounded, 'Tasks'),
              _buildNavItem(context, 3, Icons.access_time_rounded, 'My Timesheet'),
              _buildNavItem(context, 4, Icons.event_busy_outlined, 'Leave Requests'),
            ],
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sidebarAccent.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: AppTheme.sidebarAccent.withOpacity(0.3), width: 1) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppTheme.sidebarAccent : const Color(0xFF8892B0),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8892B0),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.sidebarAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.sidebarAccent.withOpacity(0.2),
            child: const Text(
              'JD',
              style: TextStyle(color: AppTheme.sidebarAccent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Employee',
                  style: TextStyle(color: Color(0xFF8892B0), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF8892B0), size: 18),
            onPressed: () {
              // Dispatch logout event; AuthWrapper handles navigation back to login.
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: AppTheme.sidebarAccent,
      unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8892B0) : const Color(0xFF6B7A99),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_outlined, size: 20), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_rounded, size: 20), label: 'Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.access_time_rounded, size: 20), label: 'Timesheet'),
        BottomNavigationBarItem(icon: Icon(Icons.event_busy_outlined, size: 20), label: 'Leaves'),
      ],
    );
  }
}

class EmployeeDashboardContent extends StatefulWidget {
  const EmployeeDashboardContent({super.key});

  @override
  State<EmployeeDashboardContent> createState() =>
      _EmployeeDashboardContentState();
}

class _EmployeeDashboardContentState extends State<EmployeeDashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  String _selectedPeriod = 'DAY';
  DateTime _selectedDate = DateTime.now();
  String _taskFilter = 'ALL';
  bool _isWorking = false;
  bool _isClockPaused = false;
  Timer? _focusTimer;
  Timer? _inactivityTimer;
  DateTime? _lastInteraction;
  int _focusSeconds = 0;
  double _shiftGoal = 0.30;

  User? _currentUser;
  Map<String, dynamic>? _profile;
  List<WorkSession> _sessions = [];
  bool _isLoadingSessions = false;
  String? _sessionError;
  final TextEditingController _taskController = TextEditingController();

  // Break info
  int _breakLimitMinutes = 60;
  int _breakUsedMinutes = 0;

  int get _breakLeftMinutes => (_breakLimitMinutes - _breakUsedMinutes).clamp(0, _breakLimitMinutes);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
        () => setState(() => _selectedTab = _tabController.index));
    _loadEmployeeData();
    _startTimer();
    _resetInactivityTimer();
  }

  int get _displayFocusSeconds {
    if (_selectedPeriod == 'DAY' && _isSameDay(_selectedDate, DateTime.now())) {
      return _focusSeconds;
    }
    return _visibleSessions.fold<int>(0, (sum, session) => sum + session.duration.inSeconds);
  }

  String get _focusTime {
    final secs = _displayFocusSeconds;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String get _focusShort {
    final secs = _displayFocusSeconds;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _inactivityTimer?.cancel();
    _taskController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    setState(() {
      _isLoadingSessions = true;
      _sessionError = null;
    });

    try {
      final user = SupabaseService.currentUser;
      _currentUser = user;
      if (user == null) {
        setState(() {
          _sessionError = 'Not signed in';
          _isLoadingSessions = false;
        });
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
            minutes = (row['duration_minutes'] is num)
                ? (row['duration_minutes'] as num).toInt()
                : int.tryParse(row['duration_minutes'].toString()) ?? 0;
          } else if (row.containsKey('minutes')) {
            minutes = (row['minutes'] is num)
                ? (row['minutes'] as num).toInt()
                : int.tryParse(row['minutes'].toString()) ?? 0;
          } else if (row.containsKey('duration')) {
            minutes = (row['duration'] is num)
                ? (row['duration'] as num).toInt()
                : int.tryParse(row['duration'].toString()) ?? 0;
          }
          breakMap[sid] = (breakMap[sid] ?? 0) + minutes;
        }
      }

      final sessions = rows.map((row) {
        final id = row['id']?.toString() ?? '';
        return WorkSession.fromMap(row, breakMinutes: breakMap[id] ?? 0);
      }).toList();
      setState(() {
        _sessions = sessions;
        final active = _currentActiveSession;
        _isWorking = active != null;
        _focusSeconds = active?.duration.inSeconds ?? 0;
        _breakUsedMinutes = active?.breakMinutes ?? 0;
        _isLoadingSessions = false;
      });
    } catch (e) {
      setState(() {
        _sessionError = e.toString();
        _isLoadingSessions = false;
      });
    }
  }

  void _resetInactivityTimer() {
    _lastInteraction = DateTime.now();
    _isClockPaused = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 15), () {
      if (!mounted) return;
      setState(() {
        _isClockPaused = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Clock paused due to 15 minutes of inactivity'),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  void _startTimer() {
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isWorking && !_isClockPaused) {
        setState(() {
          _focusSeconds++;
        });
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime get _weekStart {
    final date = _selectedDate;
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
  }

  DateTime get _weekEnd {
    final start = _weekStart;
    return DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6));
  }

  DateTime get _monthStart => DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0);

  DateTime get _monthEnd {
    final nextMonthFirst = DateTime(_selectedDate.year, _selectedDate.month + 1, 1, 0, 0, 0);
    final lastDay = nextMonthFirst.subtract(const Duration(days: 1));
    return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
  }

  List<WorkSession> get _visibleSessions {
    return _sessions.where((session) {
      final start = session.startTime;
      if (_selectedPeriod == 'WEEK') {
        return !start.isBefore(_weekStart) && !start.isAfter(_weekEnd);
      }
      if (_selectedPeriod == 'MONTH') {
        return start.year == _selectedDate.year && start.month == _selectedDate.month;
      }
      return _isSameDay(start, _selectedDate);
    }).toList();
  }

  WorkSession? get _currentActiveSession {
    try {
      return _sessions.firstWhere((session) => session.isActive);
    } catch (_) {
      return null;
    }
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

  List<TaskItem> _filteredMyTasks(TaskState state) {
    final tasks = _tasksForCurrentUser(state);
    if (_taskFilter == 'TODAY') {
      return tasks.where((t) => t.dueDate == null || _isSameDay(t.dueDate!, DateTime.now())).toList();
    }
    if (_taskFilter == 'THIS WEEK') {
      final now = DateTime.now();
      final startMonday = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startMonday.year, startMonday.month, startMonday.day, 0, 0, 0);
      final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day, 23, 59, 59).add(const Duration(days: 6));
      return tasks.where((t) {
        if (t.dueDate == null) return true;
        return !t.dueDate!.isBefore(weekStart) && !t.dueDate!.isAfter(weekEnd);
      }).toList();
    }
    return tasks;
  }

  String _taskStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.inProgress:
      case TaskStatus.review:
        return 'Ongoing';
      default:
        return 'Pending';
    }
  }

  String _selectedPeriodLabel() {
    return _selectedPeriod == 'WEEK'
        ? 'Week'
        : _selectedPeriod == 'MONTH'
            ? 'Month'
            : 'Day';
  }

  double _currentGoalProgress() {
    final totalSeconds = _visibleSessions.fold<int>(0, (sum, session) => sum + session.duration.inSeconds);
    final targetSeconds = _selectedPeriod == 'WEEK' ? 40 * 3600 : _selectedPeriod == 'MONTH' ? 160 * 3600 : 8 * 3600;
    return (totalSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  int _totalWorkedMinutes() {
    return _visibleSessions.fold<int>(0, (sum, session) => sum + session.duration.inMinutes);
  }

  int _totalBreakMinutes() {
    return _visibleSessions.fold<int>(0, (sum, session) => sum + session.breakMinutes);
  }

  bool get _canLogout {
    final state = context.read<TaskBloc>().state;
    final tasks = _tasksForCurrentUser(state);
    return tasks.isEmpty || tasks.every((t) => t.status == TaskStatus.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOperationalTimeDesk(),
                _buildPerformanceDashboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF2C3E50), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          Text('Operational command center',
              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        ],
      ),
      actions: [
        IconButton(
            icon: Icon(Icons.wb_sunny_outlined,
                color: isDark ? Colors.white : const Color(0xFF2C3E50)),
            onPressed: () {}),
        IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: isDark ? Colors.white : const Color(0xFF2C3E50)),
            onPressed: () {}),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3),
                  radius: 15,
                  child: const Text('T',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(width: 6),
              Text('SALES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderOf(context), height: 1)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _tabBtn('Operational Time Desk', 0),
          const SizedBox(width: 8),
          _tabBtn('Performance Dashboard', 1),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final sel = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: sel
                  ? const Color(0xFF2196F3)
                  : AppTheme.borderOf(context)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]))),
      ),
    );
  }

  // ===== OPERATIONAL TIME DESK =====
  Widget _buildOperationalTimeDesk() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 12),
            _buildTimeCard(),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 16),
            _buildTasksAndFocusRow(),
            const SizedBox(height: 16),
            _buildAssignedModules(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final tabs = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['DAY', 'WEEK', 'MONTH'].map((p) => GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _selectedPeriod == p
                    ? (isDark ? AppTheme.sidebarAccent : const Color(0xFF1A1A2E))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _selectedPeriod == p
                        ? (isDark ? AppTheme.sidebarAccent : const Color(0xFF1A1A2E))
                        : AppTheme.borderOf(context)),
              ),
              child: Text(p,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _selectedPeriod == p
                          ? Colors.white
                          : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]))),
            ),
          )).toList(),
    );

    final timeCol = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time,
                size: 12, color: Color(0xFF2196F3)),
            const SizedBox(width: 4),
            Text(
              _getCurrentTime(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textTitle),
            ),
          ],
        ),
        Text('INDIA',
            style: TextStyle(
                fontSize: 9, color: textBody)),
      ],
    );

    String dateLabel = '';
    if (_selectedPeriod == 'DAY') {
      if (_isSameDay(_selectedDate, DateTime.now())) {
        dateLabel = 'TODAY, ${DateFormat('MMM d, yyyy').format(_selectedDate).toUpperCase()}';
      } else {
        dateLabel = DateFormat('MMM d, yyyy').format(_selectedDate).toUpperCase();
      }
    } else if (_selectedPeriod == 'WEEK') {
      dateLabel = '${DateFormat('MMM d').format(_weekStart).toUpperCase()} - ${DateFormat('MMM d, yyyy').format(_weekEnd).toUpperCase()}';
    } else {
      dateLabel = DateFormat('MMMM yyyy').format(_monthStart).toUpperCase();
    }

    final dateChip = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 12, color: Color(0xFF2196F3)),
          const SizedBox(width: 4),
          Text(dateLabel,
              style: TextStyle(
                  fontSize: 10,
                  color: textTitle,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedPeriod == 'DAY') {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  } else if (_selectedPeriod == 'WEEK') {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                  } else {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                  }
                });
              },
              child: Icon(Icons.chevron_left,
                  size: 16, color: textBody)),
          GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedPeriod == 'DAY') {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  } else if (_selectedPeriod == 'WEEK') {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  } else {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                  }
                });
              },
              child: Icon(Icons.chevron_right,
                  size: 16, color: textBody)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: LayoutBuilder(builder: (ctx, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  tabs,
                  timeCol,
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: dateChip,
              ),
            ],
          );
        }
        return Row(
          children: [
            tabs,
            const Spacer(),
            timeCol,
            const SizedBox(width: 10),
            dateChip,
          ],
        );
      }),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $ampm';
  }

  Widget _buildTimeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMinutes = _totalWorkedMinutes();
    final activeSession = _currentActiveSession;
    final clockLabel = _isClockPaused ? 'PAUSED' : (activeSession != null ? 'WORKING' : 'CHECKED OUT');
    final breakText = '${_totalBreakMinutes()}m';
    final progress = _currentGoalProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Min hours progress
          Row(
            children: [
              Text('MINIMUM HOURS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (ctx, c) {
            final isNarrow = c.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShiftGoalCircle(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildFocusMode(),
                            const SizedBox(height: 12),
                            _buildBreakButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildClockInfo()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildEfficiencyCard()),
                    ],
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShiftGoalCircle(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildFocusMode(),
                      const SizedBox(height: 12),
                      _buildBreakButtons(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClockInfo(),
                    const SizedBox(height: 12),
                    _buildEfficiencyCard(),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildBreakInfo(),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _canLogout ? const Color(0xFFEF4444) : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: _canLogout
          ? () {
              context.read<AuthBloc>().add(AuthLogoutEvent());
            }
          : null,
      child: Text(
        _canLogout ? 'LOG OUT' : 'Complete tasks to logout',
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildShiftGoalCircle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: _shiftGoal,
              strokeWidth: 7,
              backgroundColor: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4CAF50)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(_shiftGoal * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              ),
              Text('SHIFT GOAL',
                  style: TextStyle(
                      fontSize: 8, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusMode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Stop Work button
        GestureDetector(
          onTap: () {
            setState(() => _isWorking = !_isWorking);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  _isWorking ? 'Work resumed' : 'Work stopped'),
              backgroundColor:
                  _isWorking ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _isWorking
                  ? (isDark ? const Color(0x22EF5350) : const Color(0xFFFFEBEE))
                  : (isDark ? const Color(0x2266BB6A) : const Color(0xFFE8F5E9)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _isWorking ? Colors.red : Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    _isWorking
                        ? Icons.stop_circle
                        : Icons.play_circle,
                    color: _isWorking ? Colors.red : Colors.green,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                    _isWorking ? 'STOP WORK' : 'START WORK',
                    style: TextStyle(
                        color: _isWorking
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Focus timer circle
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _displayFocusSeconds > 0 ? (_displayFocusSeconds % 3600) / 3600 : 0.0,
                  strokeWidth: 6,
                  backgroundColor: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FOCUS MODE',
                      style: TextStyle(
                          fontSize: 8,
                          color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _focusTime,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakButtons() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _breakChip('LUNCH', const Color(0xFFE3F2FD),
            const Color(0xFF1565C0)),
        _breakChip('TEA', const Color(0xFFFFF8E1),
            const Color(0xFFE65100)),
        _breakChip('MEET', const Color(0xFFF3E5F5),
            const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _breakChip(String label, Color bg, Color fg) {
    return GestureDetector(
      onTap: () => _startBreak(label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _startBreak(String type) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$type break started'),
      backgroundColor: const Color(0xFFFF9800),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Widget _buildClockInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSession = _currentActiveSession;
    final clockLabel = _isClockPaused ? 'PAUSED' : (activeSession != null ? 'WORKING' : 'CHECKED OUT');
    final clockColor = _isClockPaused ? const Color(0xFFFFA000) : const Color(0xFF4CAF50);
    String signInText = '--:--';
    String signOutText = '--:--';
    if (_visibleSessions.isNotEmpty) {
      if (_selectedPeriod == 'DAY') {
        signInText = _visibleSessions.last.signIn;
        signOutText = activeSession?.signOut ?? _visibleSessions.first.signOut;
      } else {
        signInText = '${_visibleSessions.length} days';
        signOutText = '${(_totalWorkedMinutes() / 60).toStringAsFixed(1)} hrs';
      }
    } else if (activeSession != null && _selectedPeriod == 'DAY') {
      signInText = activeSession.signIn;
      signOutText = activeSession.signOut;
    }

    final breakText = '${_totalBreakMinutes()}m';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLOCK IN',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          Text(signInText,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50))),
          const SizedBox(height: 8),
          Text('CLOCK OUT',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          Text(clockLabel,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: clockColor)),
          const SizedBox(height: 8),
          Text('BREAK',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          Text(breakText,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[600] : Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final tasks = _tasksForCurrentUser(state);
        final doneCount = tasks.where((t) => t.status == TaskStatus.done).length;
        final totalTasks = tasks.length;
        final percent = totalTasks == 0 ? 100 : ((doneCount / totalTasks) * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('EFFICIENCY',
                      style: TextStyle(
                          fontSize: 9,
                          color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline,
                      size: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 4),
              Text('$percent%',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              Text('TASK COMPLETION',
                  style: TextStyle(
                      fontSize: 8, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
              const SizedBox(height: 8),
              Text('$doneCount of $totalTasks tasks done',
                  style: TextStyle(
                      fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBreakStat('FOCUS', _focusShort,
              const Color(0xFF2196F3)),
          _divider(),
          _buildBreakStat(
              'BREAK LIMIT', '$_breakLimitMinutes', isDark ? Colors.white : Colors.grey[700]! ),
          _divider(),
          _buildBreakStat(
              'BREAK USED', '$_breakUsedMinutes', const Color(0xFFE53935)),
          _divider(),
          _buildBreakStat(
              'BREAK LEFT', '$_breakLeftMinutes', const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _divider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1, height: 30, color: isDark ? AppTheme.borderDark : Colors.grey[200]);
  }

  Widget _buildBreakStat(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 8,
                color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildTimeline() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_selectedPeriod != 'DAY') {
      return Container(); // Hide timeline for week/month view
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4))),
                    ..._visibleSessions.map((s) {
                      final dayStart = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
                      final startMins = s.startTime.difference(dayStart).inMinutes;
                      final endMins = (s.endTime ?? DateTime.now()).difference(dayStart).inMinutes;
                      final left = (startMins / 1440) * w;
                      final width = ((endMins - startMins) / 1440) * w;
                      return Positioned(
                        left: left.clamp(0.0, w),
                        width: width.clamp(0.0, w - left),
                        child: Container(
                            decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[400],
                                borderRadius: BorderRadius.circular(4))),
                      );
                    }).toList(),
                  ],
                ),
              );
            }
          ),
          const SizedBox(height: 8),
          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              '12 AM',
              '4 AM',
              '8 AM',
              '12 PM',
              '4 PM',
              '8 PM',
              '11 PM'
            ]
                .map((t) => Text(t,
                    style: TextStyle(
                        fontSize: 8, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendItem(isDark ? Colors.grey[800]! : Colors.grey[400]!, 'WORK SESSION'),
              _legendItem(const Color(0xFF4CAF50), 'FOCUS (TBD)'),
              _legendItem(const Color(0xFF2196F3), 'MEETING'),
              _legendItem(const Color(0xFFFF9800), 'BREAK'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
      ],
    );
  }

  Widget _buildTasksAndFocusRow() {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 600) {
        return Column(
          children: [
            _buildAssignedTasksCard(),
            const SizedBox(height: 12),
            _buildDailyWorkFocusCard(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildAssignedTasksCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildDailyWorkFocusCard()),
        ],
      );
    });
  }

  Widget _buildAssignedTasksCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final myTasks = _filteredMyTasks(state);
        final activeCount = myTasks.where((t) => t.status != TaskStatus.done).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined,
                      color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MY ASSIGNED TASKS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                        Text('$activeCount ACTIVE •',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF2196F3))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final parentState = context.findAncestorStateOfType<_EmployeeDashboardScreenState>();
                      if (parentState != null) {
                        parentState.setState(() {
                          parentState._selectedIndex = 2;
                        });
                      }
                    },
                    child: const Row(
                      children: [
                        Text('ALL TASKS',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward,
                            size: 12, color: Color(0xFF2196F3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter tabs
              Row(
                children: [
                  {'label': 'ALL (${myTasks.length})', 'value': 'ALL'},
                  {'label': 'TODAY', 'value': 'TODAY'},
                  {'label': 'THIS WEEK', 'value': 'THIS WEEK'},
                ].map((option) {
                  final label = option['label'] as String;
                  final value = option['value'] as String;
                  final selected = _taskFilter == value;
                  return GestureDetector(
                    onTap: () => setState(() => _taskFilter = value),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: selected
                                    ? const Color(0xFF2196F3)
                                    : Colors.transparent,
                                width: 2)),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? const Color(0xFF2196F3)
                                  : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              if (myTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No assigned tasks',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF596780) : Colors.grey[400])),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myTasks.length > 3 ? 3 : myTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final t = myTasks[idx];
                    return _buildTaskItem(
                      t,
                      '${t.parentProject ?? "N/A"} • ${t.description.isNotEmpty ? t.description : t.summary}',
                      t.dueDate != null ? DateFormat('MMM d').format(t.dueDate!) : 'TODAY',
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(TaskItem task, String subtitle, String date) {
    final title = task.summary;
    final priority = task.priority.label;
    final status = task.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = const Color(0xFFFF9800);
        break;
      default:
        priorityColor = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: status == TaskStatus.done ? const Color(0xFF4CAF50) : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: status == TaskStatus.done ? TextDecoration.lineThrough : null,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(priority,
                          style: TextStyle(
                              fontSize: 9,
                              color: priorityColor,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                          color: status.bgColor,
                          borderRadius: BorderRadius.circular(4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TaskStatus>(
                          value: status,
                          isDense: true,
                          iconSize: 14,
                          style: TextStyle(
                              fontSize: 9,
                              color: status.color,
                              fontWeight: FontWeight.w600),
                          items: TaskStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.label, style: TextStyle(color: s.color, fontSize: 10, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus != null && newStatus != status) {
                              context.read<TaskBloc>().add(UpdateTaskStatusEvent(task.id, newStatus));
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
              const SizedBox(width: 3),
              Text(date,
                  style: TextStyle(
                      fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyWorkFocusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final tasks = _tasksForCurrentUser(state);
        final pending = tasks.where((t) => _taskStatusLabel(t.status) == 'Pending').toList();
        final ongoing = tasks.where((t) => _taskStatusLabel(t.status) == 'Ongoing').toList();
        final done = tasks.where((t) => _taskStatusLabel(t.status) == 'Done').toList();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? [] : [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note,
                      color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY TASKS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                        Text('Add tasks and finish them before logout',
                            style: TextStyle(
                                fontSize: 9,
                                color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: 'What is your top task today?',
                        hintStyle: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF2196F3))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final summary = _taskController.text.trim();
                      if (summary.isEmpty) return;
                      final ownerName = _profile?['full_name']?.toString() ?? _currentUser?.email ?? '';
                      final task = TaskItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        summary: summary,
                        description: summary,
                        owner: ownerName.isNotEmpty ? ownerName : null,
                        dueDate: DateTime.now(),
                        status: TaskStatus.toDo,
                        priority: TaskPriority.medium,
                      );
                      context.read<TaskBloc>().add(AddTaskEvent(task));
                      _taskController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Task added for today'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_note,
                          size: 36, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      const SizedBox(height: 6),
                      Text('NO TASKS SET FOR TODAY',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF596780) : Colors.grey[400])),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    _buildTaskSummaryRow(done.length, ongoing.length, pending.length),
                    const SizedBox(height: 12),
                    ...tasks.map((task) => _buildTaskItem(
                          task,
                          task.description,
                          task.dueDate != null ? DateFormat('MMM d').format(task.dueDate!) : 'TODAY',
                        )),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskSummaryRow(int done, int ongoing, int pending) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryChip('Done', done, const Color(0xFF10B981), isDark),
        _buildSummaryChip('Ongoing', ongoing, const Color(0xFF0EA5E9), isDark),
        _buildSummaryChip('Pending', pending, const Color(0xFFF59E0B), isDark),
      ],
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: $count',
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAssignedModules() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined,
                  color: Color(0xFF2196F3), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MY ASSIGNED MODULES',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    Text('1 module across projects',
                        style: TextStyle(
                            fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModuleItem('message', 'arsenal', Colors.red),
        ],
      ),
    );
  }

  Widget _buildModuleItem(
      String name, String project, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color,
              radius: 14,
              child: const Text('M',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark ? AppTheme.borderDark : Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Sub',
                          style: TextStyle(
                              fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
                    const SizedBox(width: 3),
                    Text(project,
                        style: TextStyle(
                            fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== PERFORMANCE DASHBOARD =====
  Widget _buildPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Development Analytics',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Text('REAL-TIME WORKFORCE INTELLIGENCE',
                          style:
                              TextStyle(fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 14),
                  label: const Text('Dynamic Filters',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(
                          color: Color(0xFF2196F3))),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Icon(Icons.tune, size: 56, color: isDark ? Colors.grey[800] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No dashboard template assigned for your role.',
                style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white : Colors.grey[500])),
            const SizedBox(height: 8),
            Text(
                'Please contact your administrator to provision your dashboard.',
                style: TextStyle(
                    fontSize: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}