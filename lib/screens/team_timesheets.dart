import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';


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
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

final List<TimesheetEntry> sampleTimesheets = [
  TimesheetEntry(
    employeeName: 'Roronoa',
    role: 'EMPLOYEE',
    avatarInitials: 'RO',
    avatarColor: Colors.indigo,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 17, minute: 34),
    signOut: const TimeOfDay(hour: 9, minute: 33),
    duration: const Duration(hours: 15, minutes: 58),
    breakMinutes: 0,
    tasksDone: 0,
    tasksTotal: 0,
    status: TimesheetStatus.completed,
    department: 'Web Developing',
  ),
  TimesheetEntry(
    employeeName: 'Hina',
    role: 'MANAGER',
    avatarInitials: 'HI',
    avatarColor: Colors.teal,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 16, minute: 39),
    signOut: const TimeOfDay(hour: 16, minute: 39),
    duration: const Duration(hours: 0, minutes: 0),
    breakMinutes: 0,
    tasksDone: 0,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'CRM',
  ),
  TimesheetEntry(
    employeeName: 'Tony Stark',
    role: 'EMPLOYEE',
    avatarInitials: 'TS',
    avatarColor: Colors.red,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 16, minute: 28),
    signOut: const TimeOfDay(hour: 9, minute: 33),
    duration: const Duration(hours: 17, minutes: 5),
    breakMinutes: 6,
    tasksDone: 1,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'BDE',
  ),
  TimesheetEntry(
    employeeName: 'Fathima Safa',
    role: 'EMPLOYEE',
    avatarInitials: 'FS',
    avatarColor: Colors.purple,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 16, minute: 4),
    signOut: const TimeOfDay(hour: 16, minute: 21),
    duration: const Duration(hours: 0, minutes: 16),
    breakMinutes: 12,
    tasksDone: 1,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'Content Writer',
  ),
  TimesheetEntry(
    employeeName: 'Chimbu',
    role: 'EMPLOYEE',
    avatarInitials: 'CH',
    avatarColor: Colors.orange,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 9, minute: 54),
    signOut: const TimeOfDay(hour: 9, minute: 58),
    duration: const Duration(hours: 24, minutes: 4),
    breakMinutes: 173,
    tasksDone: 0,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'Graphic Designing',
  ),
  TimesheetEntry(
    employeeName: 'Tony Stark',
    role: 'EMPLOYEE',
    avatarInitials: 'TS',
    avatarColor: Colors.red,
    date: DateTime(2026, 5, 26),
    signIn: const TimeOfDay(hour: 9, minute: 54),
    signOut: const TimeOfDay(hour: 16, minute: 28),
    duration: const Duration(hours: 6, minutes: 33),
    breakMinutes: 66,
    tasksDone: 1,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'BDE',
  ),
  TimesheetEntry(
    employeeName: 'Tony Stark',
    role: 'EMPLOYEE',
    avatarInitials: 'TS',
    avatarColor: Colors.red,
    date: DateTime(2026, 5, 23),
    signIn: const TimeOfDay(hour: 17, minute: 44),
    signOut: const TimeOfDay(hour: 9, minute: 54),
    duration: const Duration(hours: 64, minutes: 9),
    breakMinutes: 0,
    tasksDone: 0,
    tasksTotal: 0,
    status: TimesheetStatus.completed,
    department: 'BDE',
  ),
  TimesheetEntry(
    employeeName: 'Chimbu',
    role: 'EMPLOYEE',
    avatarInitials: 'CH',
    avatarColor: Colors.orange,
    date: DateTime(2026, 5, 21),
    signIn: const TimeOfDay(hour: 12, minute: 3),
    signOut: const TimeOfDay(hour: 9, minute: 54),
    duration: const Duration(hours: 117, minutes: 50),
    breakMinutes: 44,
    tasksDone: 1,
    tasksTotal: 1,
    status: TimesheetStatus.completed,
    department: 'Graphic Designing',
  ),
];

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
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TimesheetEntry> get _filteredEntries {
    return sampleTimesheets.where((e) {
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
      final matchesDate =
          _selectedDateRange == null ||
          (!e.date.isBefore(_selectedDateRange!.start) &&
              !e.date.isAfter(_selectedDateRange!.end));
      return matchesSearch && matchesDept && matchesStatus && matchesDate;
    }).toList();
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      initialDateRange: _selectedDateRange,
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
      setState(() => _selectedDateRange = picked);
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
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text(
          'Team Timesheets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24),
            color: const Color(0xFF64748B),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header description ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evaluate and audit organization-wide daily sign-ins, breaks, and tasks.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
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
                        icon: Icons.date_range_outlined,
                        label: _selectedDateRange == null
                            ? 'Date Range'
                            : '${DateFormat('MMM d').format(_selectedDateRange!.start)} – ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                        onTap: _pickDateRange,
                        active: _selectedDateRange != null,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        icon: Icons.filter_list_rounded,
                        label: _selectedStatus ?? 'Status',
                        onTap: _showStatusPicker,
                        active: _selectedStatus != null,
                      ),
                      if (_selectedDepartment != 'All Departments' ||
                          _selectedDateRange != null ||
                          _selectedStatus != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedDepartment = 'All Departments';
                            _selectedDateRange = null;
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
                              'Clear',
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
          _SummaryBar(entries: filtered),
          // ── List ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No timesheets found',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : isTablet
                    ? GridView.builder(
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
                      )
                    : ListView.separated(
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
      builder: (_) => const _QuickCreateSheet(),
    );
  }
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<TimesheetEntry> entries;
  const _SummaryBar({required this.entries});

  @override
  Widget build(BuildContext context) {
    final completed = entries.where((e) => e.status == TimesheetStatus.completed).length;
    final totalHours = entries.fold<int>(0, (s, e) => s + e.duration.inHours);
    final withTasks = entries.where((e) => e.tasksDone > 0).length;
    final w = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          _SummaryStat(
            label: 'Total',
            value: '${entries.length}',
            color: const Color(0xFF0EA5E9),
          ),
          _divider(w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'Completed',
            value: '$completed',
            color: const Color(0xFF10B981),
          ),
          _divider(w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'Total Hours',
            value: '${totalHours}h',
            color: const Color(0xFF8B5CF6),
          ),
          _divider(w < 360 ? 4 : 8),
          _SummaryStat(
            label: 'With Tasks',
            value: '$withTasks',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _divider(double horizontalMargin) => Container(
    width: 1,
    height: 28,
    color: const Color(0xFFE2E8F0),
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
            style: TextStyle(fontSize: isCompact ? 9 : 11, color: const Color(0xFF94A3B8)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
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
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active
                    ? const Color(0xFF0369A1)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: active
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF94A3B8),
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

  Color get _statusColor {
    switch (entry.status) {
      case TimesheetStatus.completed:
        return const Color(0xFF10B981);
      case TimesheetStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TimesheetStatus.absent:
        return const Color(0xFFEF4444);
    }
  }

  Color get _statusBg {
    switch (entry.status) {
      case TimesheetStatus.completed:
        return const Color(0xFFD1FAE5);
      case TimesheetStatus.inProgress:
        return const Color(0xFFFEF3C7);
      case TimesheetStatus.absent:
        return const Color(0xFFFEE2E2);
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        entry.role,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
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
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Divider ──
          Container(height: 1, color: const Color(0xFFF1F5F9)),
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
            color: const Color(0xFFF1F5F9),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.business_center_outlined,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.department,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Evaluate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: Color(0xFF1D4ED8),
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
              Icon(icon, size: 12, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
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
              color: valueColor ?? const Color(0xFF334155),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Department',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
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
                  color: const Color(0xFF1E293B),
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
    const statuses = ['Completed', 'In Progress', 'Absent'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            onTap: () => onSelect(null),
            title: const Text(
              'All',
              style: TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
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
                  color: const Color(0xFF1E293B),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
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
              ScaffoldMessenger.of(context).showSnackBar(
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
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 20,
        color: iconColor ?? const Color(0xFF475569),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: labelColor ?? const Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Color(0xFFCBD5E1),
      ),
    );
  }
}

// ─── Detailed Log Screen ─────────────────────────────────────────────────────

class _DetailedLogScreen extends StatelessWidget {
  final TimesheetEntry entry;
  const _DetailedLogScreen({required this.entry});

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detailed Log',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${entry.role} • ${entry.department}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Shift Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
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
            _DetailRow(label: 'Status', value: 'Completed', isStatus: true),
            const SizedBox(height: 20),
            const Text(
              'Activity Timeline',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
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
  const _DetailRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                )
              : Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
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
                    color: const Color(0xFFE2E8F0),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adjust Time',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.entry.employeeName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  const _TimeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        hintText: 'HH:MM',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: const Icon(
          Icons.access_time_rounded,
          size: 18,
          color: Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

// ─── Quick Create Sheet ───────────────────────────────────────────────────────

class _QuickCreateSheet extends StatelessWidget {
  const _QuickCreateSheet();

  @override
  Widget build(BuildContext context) {
    const options = [
      (Icons.person_add_outlined, 'New Lead', Color(0xFF0EA5E9)),
      (Icons.folder_open_outlined, 'New Project', Color(0xFF8B5CF6)),
      (Icons.receipt_long_outlined, 'New Invoice', Color(0xFF10B981)),
      (Icons.task_outlined, 'New Task', Color(0xFFF59E0B)),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Create',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...options.map(
            (o) => ListTile(
              onTap: () => Navigator.pop(context),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}