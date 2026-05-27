import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

// ─── MODELS ───────────────────────────────────────────────────────────────────

enum EventType { project, deadline, milestone, leave }

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final EventType type;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
  });
}

class UpcomingTask {
  final String title;
  final DateTime date;
  final EventType type;

  const UpcomingTask({
    required this.title,
    required this.date,
    required this.type,
  });
}

// ─── THEME CONSTANTS ──────────────────────────────────────────────────────────

class SchedulerTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color todayBg = Color(0xFF2563EB);

  static const Color projectColor = Color(0xFF3B82F6);
  static const Color deadlineColor = Color(0xFFF59E0B);
  static const Color milestoneColor = Color(0xFF8B5CF6);
  static const Color leaveColor = Color(0xFF10B981);

  static Color eventColor(EventType type) {
    switch (type) {
      case EventType.project:
        return projectColor;
      case EventType.deadline:
        return deadlineColor;
      case EventType.milestone:
        return milestoneColor;
      case EventType.leave:
        return leaveColor;
    }
  }

  static Color eventBgColor(EventType type) {
    return eventColor(type).withOpacity(0.12);
  }
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

final List<CalendarEvent> sampleEvents = [
  CalendarEvent(id: '1', title: 'Proj: civiceye', date: DateTime(2026, 5, 4), type: EventType.project),
  CalendarEvent(id: '2', title: 'Proj: ecocraft', date: DateTime(2026, 5, 4), type: EventType.project),
  CalendarEvent(id: '3', title: 'Proj: janani', date: DateTime(2026, 5, 4), type: EventType.project),
  CalendarEvent(id: '4', title: 'Proj: arsenal', date: DateTime(2026, 5, 4), type: EventType.project),
  CalendarEvent(id: '5', title: 'Proj: delta', date: DateTime(2026, 5, 4), type: EventType.project),
  CalendarEvent(id: '6', title: 'Proj: Janani - Web Dev', date: DateTime(2026, 5, 20), type: EventType.project),
  CalendarEvent(id: '7', title: 'Proj: janani', date: DateTime(2026, 5, 20), type: EventType.project),
  CalendarEvent(id: '8', title: 'Proj: Janani - Web Dev', date: DateTime(2026, 5, 20), type: EventType.project),
  CalendarEvent(id: '9', title: 'Proj: arsenal - Digital Marketing', date: DateTime(2026, 5, 21), type: EventType.project),
  CalendarEvent(id: '10', title: 'Task: develop this', date: DateTime(2026, 5, 22), type: EventType.deadline),
  CalendarEvent(id: '11', title: 'Task: design dashboard', date: DateTime(2026, 5, 23), type: EventType.deadline),
  CalendarEvent(id: '12', title: 'Task: landing page', date: DateTime(2026, 5, 27), type: EventType.deadline),
  CalendarEvent(id: '13', title: 'Task: design this', date: DateTime(2026, 5, 27), type: EventType.deadline),
  CalendarEvent(id: '14', title: 'Task: hello brooo', date: DateTime(2026, 5, 28), type: EventType.deadline),
  CalendarEvent(id: '15', title: 'Task: develop ecraftz', date: DateTime(2026, 5, 28), type: EventType.deadline),
  CalendarEvent(id: '16', title: 'Milestone: v1.0', date: DateTime(2026, 5, 15), type: EventType.milestone),
];

final List<UpcomingTask> upcomingTasks = [
  UpcomingTask(title: 'Task: hello brooo', date: DateTime(2026, 5, 28), type: EventType.deadline),
  UpcomingTask(title: 'Task: develop ecraftz', date: DateTime(2026, 5, 28), type: EventType.deadline),
];

// ─── MAIN SCHEDULER SCREEN ────────────────────────────────────────────────────

class SchedulerScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;  
  const SchedulerScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _currentMonth = DateTime(2026, 5, 1);
  DateTime? _selectedDate;
  CalendarEvent? _selectedEvent;

  List<CalendarEvent> get _filteredEvents => sampleEvents.where((e) =>
    e.date.year == _currentMonth.year && e.date.month == _currentMonth.month
  ).toList();

  int _countByType(EventType type) =>
      sampleEvents.where((e) => e.type == type).length;

  List<CalendarEvent> _eventsForDay(DateTime day) =>
      _filteredEvents.where((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day
      ).toList();

  void _prevMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
  });

  void _goToday() => setState(() {
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedDate = DateTime.now();
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;
    final isDesktop = size.width >= 1100;
    final isWide = size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SchedulerTheme.background,
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
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Scheduler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Visual timeline of projects, deadlines, and team availability.',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout()
            : isTablet
                ? _buildTabletLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  // ── DESKTOP LAYOUT ──────────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLegendCard(),
                const SizedBox(height: 16),
                _buildUpcomingCard(),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCalendarCard(),
          ),
        ),
      ],
    );
  }

  // ── TABLET LAYOUT ───────────────────────────────────────────────────────────

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLegendCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingCard()),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarCard(),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT ───────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildLegendCard(),
          const SizedBox(height: 12),
          _buildUpcomingCard(),
          const SizedBox(height: 12),
          _buildCalendarCard(),
        ],
      ),
    );
  }

  // ── LEGEND CARD ─────────────────────────────────────────────────────────────

  Widget _buildLegendCard() {
    return Container(
      decoration: BoxDecoration(
        color: SchedulerTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchedulerTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENT LEGEND',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: SchedulerTheme.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          _legendItem(Icons.folder_rounded, 'Projects', _countByType(EventType.project), SchedulerTheme.projectColor),
          _legendItem(Icons.flag_rounded, 'Deadlines', _countByType(EventType.deadline), SchedulerTheme.deadlineColor),
          _legendItem(Icons.stars_rounded, 'Milestones', _countByType(EventType.milestone), SchedulerTheme.milestoneColor),
          _legendItem(Icons.person_off_rounded, 'Leave / Absence', _countByType(EventType.leave), SchedulerTheme.leaveColor),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: SchedulerTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Events are automatically synced from the CRM, Projects, and HR modules. Click an event to view details.',
                    style: TextStyle(fontSize: 11, color: SchedulerTheme.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: SchedulerTheme.textPrimary, fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  // ── UPCOMING CARD ───────────────────────────────────────────────────────────

  Widget _buildUpcomingCard() {
    return Container(
      decoration: BoxDecoration(
        color: SchedulerTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchedulerTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UPCOMING THIS WEEK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: SchedulerTheme.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...upcomingTasks.map((task) => _upcomingItem(task)),
          if (upcomingTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No upcoming events', style: TextStyle(color: SchedulerTheme.textSecondary, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _upcomingItem(UpcomingTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: SchedulerTheme.eventColor(task.type),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SchedulerTheme.textPrimary)),
                const SizedBox(height: 1),
                Text(DateFormat('EEE, MMM d').format(task.date),
                  style: TextStyle(fontSize: 11, color: SchedulerTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CALENDAR CARD ───────────────────────────────────────────────────────────

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: SchedulerTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchedulerTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const Divider(height: 1, color: SchedulerTheme.border),
          _buildWeekdayRow(),
          const Divider(height: 1, color: SchedulerTheme.border),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 480;
    final totalEvents = _filteredEvents.length;

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SchedulerTheme.textPrimary),
        ),
        Text(
          '$totalEvents EVENTS SCHEDULED',
          style: const TextStyle(fontSize: 10, color: SchedulerTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );

    final navRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navButton(Icons.chevron_left, _prevMonth),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _goToday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: SchedulerTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SchedulerTheme.textPrimary)),
          ),
        ),
        const SizedBox(width: 4),
        _navButton(Icons.chevron_right, _nextMonth),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isSmall
          ? Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SchedulerTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: SchedulerTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: titleColumn),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    navRow,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SchedulerTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: SchedulerTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: titleColumn),
                navRow,
              ],
            ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: SchedulerTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: SchedulerTheme.textSecondary),
      ),
    );
  }

  Widget _buildWeekdayRow() {
    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Row(
      children: days.map((d) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Center(
            child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SchedulerTheme.textSecondary, letterSpacing: 0.5)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // 0=Sun
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final isNarrow = cellWidth < 60;

        return Column(
          children: List.generate(rows, (row) {
            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (col) {
                      final index = row * 7 + col;
                      final dayNum = index - startOffset + 1;
                      if (dayNum < 1 || dayNum > lastDay.day) {
                        return Expanded(child: _emptyCell(row, col, rows, dayNum, lastDay.day));
                      }
                      final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                      return Expanded(child: _dayCell(date, isNarrow));
                    }),
                  ),
                ),
                if (row < rows - 1) const Divider(height: 1, color: SchedulerTheme.border),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _emptyCell(int row, int col, int totalRows, int dayNum, int lastDay) {
    // Show prev/next month dates in greyed out style
    Color borderRight = col < 6 ? SchedulerTheme.border : Colors.transparent;
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(right: BorderSide(color: col < 6 ? SchedulerTheme.border : Colors.transparent)),
      ),
    );
  }

  Widget _dayCell(DateTime date, bool isNarrow) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isSelected = _selectedDate != null &&
        date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day;
    final events = _eventsForDay(date);
    final maxVisible = isNarrow ? 1 : 2;
    final overflow = events.length - maxVisible;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        if (events.isNotEmpty) _showDayEventsModal(date, events);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border(
            right: const BorderSide(color: SchedulerTheme.border),
            left: isSelected ? const BorderSide(color: SchedulerTheme.primary, width: 2) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 24, height: 24,
                  decoration: isToday
                      ? const BoxDecoration(color: SchedulerTheme.todayBg, shape: BoxShape.circle)
                      : null,
                  child: Center(
                    child: Text('${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday ? Colors.white : SchedulerTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...events.take(maxVisible).map((e) => _eventChip(e, isNarrow)),
            if (overflow > 0) _overflowChip(overflow, date, events),
          ],
        ),
      ),
    );
  }

  Widget _eventChip(CalendarEvent event, bool isNarrow) {
    final color = SchedulerTheme.eventColor(event.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 3 : 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        child: isNarrow
            ? Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
            : Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }

  Widget _overflowChip(int count, DateTime date, List<CalendarEvent> events) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: GestureDetector(
        onTap: () => _showDayEventsModal(date, events),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('+$count MORE',
            style: const TextStyle(fontSize: 9, color: SchedulerTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ),
      ),
    );
  }

  // ── DAY EVENTS MODAL ────────────────────────────────────────────────────────

  void _showDayEventsModal(DateTime date, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: SchedulerTheme.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: SchedulerTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.calendar_today_rounded, color: SchedulerTheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE, MMMM d, yyyy').format(date),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SchedulerTheme.textPrimary)),
                        Text('${events.length} event${events.length != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: SchedulerTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: SchedulerTheme.border),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _eventDetailTile(events[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventDetailTile(CalendarEvent event) {
    final color = SchedulerTheme.eventColor(event.type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SchedulerTheme.textPrimary)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(_eventTypeLabel(event.type),
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: SchedulerTheme.textSecondary),
        ],
      ),
    );
  }

  String _eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.project: return 'PROJECT';
      case EventType.deadline: return 'DEADLINE';
      case EventType.milestone: return 'MILESTONE';
      case EventType.leave: return 'LEAVE';
    }
  }
}