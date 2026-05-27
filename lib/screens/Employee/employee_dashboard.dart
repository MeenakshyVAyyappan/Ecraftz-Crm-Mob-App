import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../signin.dart';
import 'emply_project_screen.dart';
import 'emply_tasks_screen.dart';
import 'emply_my_timesheet.dart';
import 'emply_leave_request.dart';

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
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, child) {
            final isDarkTheme = mode == ThemeMode.dark;
            return IconButton(
              icon: Icon(
                isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDarkTheme ? Colors.white : const Color(0xFF2C3E50),
              ),
              onPressed: () {
                themeNotifier.value = isDarkTheme ? ThemeMode.light : ThemeMode.dark;
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
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
  bool _isWorking = true;
  Timer? _focusTimer;
  int _focusSeconds = 8731; // 2h 25m 31s
  double _shiftGoal = 0.30;

  // Break info
  final String _breakLimit = '1h 0m';
  final String _breakUsed = '00h 00m';
  final String _breakLeft = '01h 00m';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
        () => setState(() => _selectedTab = _tabController.index));
    _startTimer();
  }

  void _startTimer() {
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isWorking) setState(() => _focusSeconds++);
    });
  }

  String get _focusTime {
    final h = _focusSeconds ~/ 3600;
    final m = (_focusSeconds % 3600) ~/ 60;
    final s = _focusSeconds % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String get _focusShort {
    final h = _focusSeconds ~/ 3600;
    final m = (_focusSeconds % 3600) ~/ 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _tabController.dispose();
    super.dispose();
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
    return SingleChildScrollView(
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
          Text('TODAY, MAY 27, 2026',
              style: TextStyle(
                  fontSize: 10,
                  color: textTitle,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
              onTap: () {},
              child: Icon(Icons.chevron_left,
                  size: 16, color: textBody)),
          GestureDetector(
              onTap: () {},
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
                    value: _shiftGoal,
                    backgroundColor: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(_shiftGoal * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          // Main content
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
        ],
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
                  value: (_focusSeconds % 3600) / 3600,
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
          const Text('11:14 AM',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50))),
          const SizedBox(height: 8),
          Text('CLOCK OUT',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          Text('WORKING',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('BREAK',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
          Text('--',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[600] : Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text('100%',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          Text('FOCUS VS BREAK RATIO',
              style: TextStyle(
                  fontSize: 8, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        ],
      ),
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
              'BREAK LIMIT', _breakLimit, isDark ? Colors.white : Colors.grey[700]!),
          _divider(),
          _buildBreakStat(
              'BREAK USED', _breakUsed, const Color(0xFFE53935)),
          _divider(),
          _buildBreakStat(
              'BREAK LEFT', _breakLeft, const Color(0xFFFF9800)),
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
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                Container(
                    decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: Container(
                      decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4))),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.35,
                  child: FractionallySizedBox(
                    widthFactor: 0.15,
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(4))),
                  ),
                ),
              ],
            ),
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
              _legendItem(const Color(0xFF4CAF50), 'FOCUS'),
              _legendItem(const Color(0xFF2196F3), 'MEETING'),
              _legendItem(const Color(0xFFFF9800), 'BREAK'),
              _legendItem(Colors.grey, 'AWAY / CHECKED OUT'),
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
                    const Text('1 ACTIVE •',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF2196F3))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
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
            children: ['ALL (1)', 'TODAY', 'THIS WEEK'].map((f) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: f == 'ALL (1)'
                                ? const Color(0xFF2196F3)
                                : Colors.transparent,
                            width: 2)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 11,
                          color: f == 'ALL (1)'
                              ? const Color(0xFF2196F3)
                              : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
                          fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildTaskItem(
            'hello brooo',
            'arsenal - Digital Marketing Premium Intake v1 • hello',
            'Medium',
            'Done',
            'May 28',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String subtitle, String priority,
      String status, String date) {
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
          const Icon(Icons.check_circle,
              color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(status,
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
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
    final controller = TextEditingController();
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
                    Text('DAILY WORK FOCUS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    Text('MANDATORY FOR SHIFT CHECKOUT',
                        style: TextStyle(
                            fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
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
                  controller: controller,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'What are you tackling today?',
                    hintStyle: TextStyle(
                        fontSize: 12, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF2196F3))),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Focus set!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating));
                    controller.clear();
                  }
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
          Center(
            child: Column(
              children: [
                Icon(Icons.edit_note,
                    size: 36, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                const SizedBox(height: 6),
                Text('NO TASKS SET FOR TODAY',
                    style: TextStyle(
                        fontSize: 11, color: isDark ? const Color(0xFF596780) : Colors.grey[400])),
              ],
            ),
          ),
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