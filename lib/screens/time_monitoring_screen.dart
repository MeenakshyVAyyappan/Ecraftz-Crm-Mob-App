import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ==================== MODELS ====================

class Employee {
  final String id;
  final String name;
  final String checkedInAt;
  final String status;
  final String sessionDuration;
  final String activeTask;

  Employee({
    required this.id,
    required this.name,
    required this.checkedInAt,
    required this.status,
    required this.sessionDuration,
    required this.activeTask,
  });
}

class TrackingConfig {
  int minimumDailyHours;
  int lateThresholdMinutes;
  bool flexibleMode;
  bool productivityTracking;
  int maxBreakTimeMinutes;
  String defaultStartTime;
  String defaultEndTime;

  TrackingConfig({
    required this.minimumDailyHours,
    required this.lateThresholdMinutes,
    required this.flexibleMode,
    required this.productivityTracking,
    required this.maxBreakTimeMinutes,
    required this.defaultStartTime,
    required this.defaultEndTime,
  });
}

// ==================== MAIN SCREEN ====================

class TimeMonitorScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const TimeMonitorScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<TimeMonitorScreen> createState() => _TimeMonitorScreenState();
}

class _TimeMonitorScreenState extends State<TimeMonitorScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _selectedTab = 0;

  // Governance sidebar selection
  int _selectedGovernanceItem = 0;

  bool _isEditing = false;

  // Sample Data
  final List<Employee> _employees = [
    Employee(
      id: 'T',
      name: 'TONY STARK',
      checkedInAt: '11:14 AM',
      status: 'WORKING',
      sessionDuration: '0h 55m',
      activeTask: 'No Task Started',
    ),
    Employee(
      id: 'C',
      name: 'CHIMBU',
      checkedInAt: '11:14 AM',
      status: 'WORKING',
      sessionDuration: '0h 55m',
      activeTask: 'No Task Started',
    ),
    Employee(
      id: 'R',
      name: 'RORONOA',
      checkedInAt: '12:01 PM',
      status: 'WORKING',
      sessionDuration: '0h 9m',
      activeTask: 'No Task Started',
    ),
  ];

  late TrackingConfig _config;
  late TrackingConfig _editingConfig;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _config = TrackingConfig(
      minimumDailyHours: 8,
      lateThresholdMinutes: 15,
      flexibleMode: false,
      productivityTracking: false,
      maxBreakTimeMinutes: 60,
      defaultStartTime: '09:00 AM',
      defaultEndTime: '06:00 PM',
    );
    _editingConfig = TrackingConfig(
      minimumDailyHours: _config.minimumDailyHours,
      lateThresholdMinutes: _config.lateThresholdMinutes,
      flexibleMode: _config.flexibleMode,
      productivityTracking: _config.productivityTracking,
      maxBreakTimeMinutes: _config.maxBreakTimeMinutes,
      defaultStartTime: _config.defaultStartTime,
      defaultEndTime: _config.defaultEndTime,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees
        .where((e) =>
            e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get _onlineCount => _employees.length;
  int get _workingCount =>
      _employees.where((e) => e.status == 'WORKING').length;
  int get _onBreakCount =>
      _employees.where((e) => e.status == 'ON BREAK').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: widget.onItemSelected,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveActivityTab(),
                _buildRulesGovernanceTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployeeDialog(),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: isTablet
          ? null
          : IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF2C3E50)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
              Text(
                'Time Monitor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF2C3E50)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Color(0xFF2C3E50)),
          onPressed: () => _showNotificationsPanel(),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF2196F3),
            radius: 16,
            child: const Text(
              'SA',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildTabButton('LIVE ACTIVITY', 0),
          const SizedBox(width: 8),
          _buildTabButton('RULES & GOVERNANCE', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1A1A2E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // ==================== LIVE ACTIVITY TAB ====================

  Widget _buildLiveActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Time Monitor Hub',
            'Centralized operational hub for tracking live employee activity, managing personal timesheets, and governing shift policies.',
          ),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildEmployeeList(),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        if (isNarrow) {
          return Column(
            children: [
              _buildStatCard(
                  'ONLINE NOW',
                  _onlineCount.toString(),
                  'Live Monitoring Active',
                  Icons.desktop_windows_outlined,
                  const Color(0xFF2196F3),
                  true),
              const SizedBox(height: 10),
              _buildStatCard(
                  'CURRENTLY WORKING',
                  _workingCount.toString(),
                  'Active sessions without breaks',
                  Icons.access_time,
                  const Color(0xFF2196F3),
                  false),
              const SizedBox(height: 10),
              _buildStatCard(
                  'ON BREAK',
                  _onBreakCount.toString(),
                  'Employees in pause state',
                  Icons.free_breakfast_outlined,
                  const Color(0xFFFF9800),
                  false),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                  'ONLINE NOW',
                  _onlineCount.toString(),
                  'Live Monitoring Active',
                  Icons.desktop_windows_outlined,
                  const Color(0xFF2196F3),
                  true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                  'CURRENTLY WORKING',
                  _workingCount.toString(),
                  'Active sessions without breaks',
                  Icons.access_time,
                  const Color(0xFF2196F3),
                  false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                  'ON BREAK',
                  _onBreakCount.toString(),
                  'Employees in pause state',
                  Icons.free_breakfast_outlined,
                  const Color(0xFFFF9800),
                  false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color iconColor, bool showLive) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: iconColor == const Color(0xFFFF9800)
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          if (showLive)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final w = MediaQuery.of(context).size.width;
    final showLabel = w >= 600;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search employees...',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildIconButton(Icons.filter_list, 'Filters', showLabel, () => _showFiltersPanel()),
        const SizedBox(width: 8),
        _buildIconButton(Icons.download_outlined, 'Export', showLabel, () => _exportData()),
      ],
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, bool showLabel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2196F3)),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No employees found',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredEmployees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildEmployeeCard(_filteredEmployees[index]),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    Color statusColor;
    Color statusBg;
    switch (employee.status) {
      case 'WORKING':
        statusColor = const Color(0xFF2196F3);
        statusBg = const Color(0xFFE3F2FD);
        break;
      case 'ON BREAK':
        statusColor = const Color(0xFFFF9800);
        statusBg = const Color(0xFFFFF3E0);
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey[100]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: statusColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      statusColor.withOpacity(0.15),
                  radius: 18,
                  child: Text(
                    employee.id,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            'Checked in at ${employee.checkedInAt}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    employee.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.timer_outlined,
                    'SESSION DURATION',
                    employee.sessionDuration,
                    const Color(0xFF1A1A2E),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.task_outlined,
                    'ACTIVE TASK',
                    employee.activeTask,
                    employee.activeTask == 'No Task Started'
                        ? Colors.grey
                        : const Color(0xFF2196F3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showActivityLog(employee),
                    icon: const Icon(Icons.history, size: 14),
                    label: const Text(
                      'VIEW ACTIVITY LOG',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(
                          color: Color(0xFF2196F3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      _showEmployeeOptions(employee),
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF2196F3)),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFE3F2FD),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== RULES & GOVERNANCE TAB ====================

  Widget _buildRulesGovernanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Time Desk Governance',
            'Configure organization-wide work policies, shift schedules, and security protocols.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildGovernanceSidebar(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGovernanceContent()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildGovernanceSidebar(),
                  const SizedBox(height: 16),
                  _buildGovernanceContent(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGovernanceSidebar() {
    return Column(
      children: [
        // Tracking Rules (expandable)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.access_time,
                    color: Colors.white, size: 18),
                title: const Text(
                  'Tracking Rules',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                trailing: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white, size: 18),
                onTap: () {},
              ),
              ...[
                'Working Days',
                'Leave Policies',
                'Team Provisioning',
              ].asMap().entries.map(
                    (entry) => GestureDetector(
                      onTap: () => setState(
                          () => _selectedGovernanceItem = entry.key + 1),
                      child: Container(
                        margin: const EdgeInsets.only(
                            left: 8, right: 8, bottom: 4),
                        decoration: BoxDecoration(
                          color: _selectedGovernanceItem == entry.key + 1
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getGovernanceIcon(entry.value),
                            color: Colors.white70,
                            size: 16,
                          ),
                          title: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white54, size: 16),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Admin Control Warning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFB74D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFE65100), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'ADMIN CONTROL',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'THESE SETTINGS ENFORCE STRICT ORGANIZATIONAL COMPLIANCE. CHANGES ARE AUDITED IN REAL-TIME.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getGovernanceIcon(String item) {
    switch (item) {
      case 'Working Days':
        return Icons.calendar_today_outlined;
      case 'Leave Policies':
        return Icons.shield_outlined;
      case 'Team Provisioning':
        return Icons.people_outline;
      default:
        return Icons.settings_outlined;
    }
  }

  Widget _buildGovernanceContent() {
    return Column(
      children: [
        // Edit / Save buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isEditing) ...[
              ElevatedButton.icon(
                onPressed: _saveConfiguration,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('SAVE CONFIGURATION',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('CANCEL EDITING',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _startEditing,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('EDIT CONFIGURATION',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTrackingCoreLogic(),
        const SizedBox(height: 16),
        _buildStandardShiftSchedule(),
        const SizedBox(height: 16),
        _buildWorkingDaysSection(),
      ],
    );
  }

  Widget _buildTrackingCoreLogic() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF2196F3), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'TRACKING CORE LOGIC',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'CONFIGURE HOW EMPLOYEE TIME IS CALCULATED AND ENFORCED.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Min hours + Late threshold
                LayoutBuilder(
                  builder: (ctx, c) => c.maxWidth < 480
                      ? Column(children: [
                          _buildConfigField(
                              'MINIMUM DAILY HOURS',
                              _isEditing
                                  ? _editingConfig
                                      .minimumDailyHours
                                      .toString()
                                  : _config.minimumDailyHours
                                      .toString(),
                              _isEditing,
                              (v) => _editingConfig
                                  .minimumDailyHours = int.tryParse(v) ?? 8),
                          const SizedBox(height: 12),
                          _buildConfigField(
                              'LATE THRESHOLD (MINUTES)',
                              _isEditing
                                  ? _editingConfig
                                      .lateThresholdMinutes
                                      .toString()
                                  : _config.lateThresholdMinutes
                                      .toString(),
                              _isEditing,
                              (v) => _editingConfig
                                  .lateThresholdMinutes =
                                  int.tryParse(v) ?? 15),
                        ])
                      : Row(
                          children: [
                            Expanded(
                              child: _buildConfigField(
                                  'MINIMUM DAILY HOURS',
                                  _isEditing
                                      ? _editingConfig.minimumDailyHours
                                          .toString()
                                      : _config.minimumDailyHours
                                          .toString(),
                                  _isEditing,
                                  (v) => _editingConfig
                                      .minimumDailyHours =
                                      int.tryParse(v) ?? 8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildConfigField(
                                  'LATE THRESHOLD (MINUTES)',
                                  _isEditing
                                      ? _editingConfig
                                          .lateThresholdMinutes
                                          .toString()
                                      : _config.lateThresholdMinutes
                                          .toString(),
                                  _isEditing,
                                  (v) => _editingConfig
                                      .lateThresholdMinutes =
                                      int.tryParse(v) ?? 15),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                // Toggles
                LayoutBuilder(
                  builder: (ctx, c) => c.maxWidth < 480
                      ? Column(children: [
                          _buildToggleRow(
                            'FLEXIBLE MODE',
                            'Disable strict start/end times.',
                            _isEditing
                                ? _editingConfig.flexibleMode
                                : _config.flexibleMode,
                            _isEditing,
                            (v) => setState(
                                () => _editingConfig.flexibleMode = v),
                          ),
                          const SizedBox(height: 12),
                          _buildToggleRow(
                            'PRODUCTIVITY TRACKING',
                            'Enable task-time correlation.',
                            _isEditing
                                ? _editingConfig.productivityTracking
                                : _config.productivityTracking,
                            _isEditing,
                            (v) => setState(() =>
                                _editingConfig.productivityTracking = v),
                          ),
                        ])
                      : Row(
                          children: [
                            Expanded(
                              child: _buildToggleRow(
                                'FLEXIBLE MODE',
                                'Disable strict start/end times.',
                                _isEditing
                                    ? _editingConfig.flexibleMode
                                    : _config.flexibleMode,
                                _isEditing,
                                (v) => setState(
                                    () => _editingConfig.flexibleMode = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildToggleRow(
                                'PRODUCTIVITY TRACKING',
                                'Enable task-time correlation.',
                                _isEditing
                                    ? _editingConfig.productivityTracking
                                    : _config.productivityTracking,
                                _isEditing,
                                (v) => setState(() =>
                                    _editingConfig
                                        .productivityTracking = v),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                // Max break
                _buildMaxBreakCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField(
      String label, String value, bool editable, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        if (editable)
          TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF2196F3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF2196F3)),
              ),
              filled: true,
              fillColor: const Color(0xFFF0F8FF),
            ),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleRow(String label, String subtitle, bool value,
      bool editable, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: editable ? onChanged : null,
            activeColor: const Color(0xFF2196F3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildMaxBreakCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFFF9800), size: 16),
              const SizedBox(width: 6),
              const Text(
                'MAX BREAK TIME PER SHIFT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total cumulative break minutes allowed per work session. Employees cannot start new breaks once this limit is reached.',
            style: TextStyle(fontSize: 10, color: Colors.orange[700]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_isEditing)
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: _editingConfig.maxBreakTimeMinutes
                        .toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _editingConfig
                        .maxBreakTimeMinutes = int.tryParse(v) ?? 60,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF9800))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF9800))),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
              else
                Text(
                  _config.maxBreakTimeMinutes.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MINUTES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '= ${(_isEditing ? _editingConfig.maxBreakTimeMinutes : _config.maxBreakTimeMinutes) ~/ 60}h ${(_isEditing ? _editingConfig.maxBreakTimeMinutes : _config.maxBreakTimeMinutes) % 60}m per shift',
                style: TextStyle(
                    fontSize: 11, color: Colors.orange[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardShiftSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STANDARD SHIFT SCHEDULE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, c) => c.maxWidth < 480
                ? Column(
                    children: [
                      _buildTimeField(
                          'DEFAULT START TIME',
                          _isEditing
                              ? _editingConfig.defaultStartTime
                              : _config.defaultStartTime,
                          _isEditing,
                          (v) => _editingConfig.defaultStartTime = v,
                          true),
                      const SizedBox(height: 12),
                      _buildTimeField(
                          'DEFAULT END TIME',
                          _isEditing
                              ? _editingConfig.defaultEndTime
                              : _config.defaultEndTime,
                          _isEditing,
                          (v) => _editingConfig.defaultEndTime = v,
                          false),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                            'DEFAULT START TIME',
                            _isEditing
                                ? _editingConfig.defaultStartTime
                                : _config.defaultStartTime,
                            _isEditing,
                            (v) => _editingConfig.defaultStartTime = v,
                            true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(
                            'DEFAULT END TIME',
                            _isEditing
                                ? _editingConfig.defaultEndTime
                                : _config.defaultEndTime,
                            _isEditing,
                            (v) => _editingConfig.defaultEndTime = v,
                            false),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(String label, String value, bool editable,
      Function(String) onChanged, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: editable
              ? () async {
                  final now = TimeOfDay.now();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: now,
                  );
                  if (picked != null) {
                    onChanged(picked.format(context));
                    setState(() {});
                  }
                }
              : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: editable
                  ? const Color(0xFFF0F8FF)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: editable
                  ? Border.all(color: const Color(0xFF2196F3))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  isStart
                      ? Icons.play_circle_outline
                      : Icons.stop_circle_outlined,
                  color: isStart
                      ? const Color(0xFF4CAF50)
                      : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (editable) ...[
                  const Spacer(),
                  const Icon(Icons.access_time,
                      color: Color(0xFF2196F3), size: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = [true, true, true, true, true, false, false];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORKING DAYS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              return _buildDayChip(days[i], activeDays[i]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String day, bool isActive) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2196F3)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editingConfig = TrackingConfig(
        minimumDailyHours: _config.minimumDailyHours,
        lateThresholdMinutes: _config.lateThresholdMinutes,
        flexibleMode: _config.flexibleMode,
        productivityTracking: _config.productivityTracking,
        maxBreakTimeMinutes: _config.maxBreakTimeMinutes,
        defaultStartTime: _config.defaultStartTime,
        defaultEndTime: _config.defaultEndTime,
      );
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  void _saveConfiguration() {
    setState(() {
      _config = TrackingConfig(
        minimumDailyHours: _editingConfig.minimumDailyHours,
        lateThresholdMinutes: _editingConfig.lateThresholdMinutes,
        flexibleMode: _editingConfig.flexibleMode,
        productivityTracking: _editingConfig.productivityTracking,
        maxBreakTimeMinutes: _editingConfig.maxBreakTimeMinutes,
        defaultStartTime: _editingConfig.defaultStartTime,
        defaultEndTime: _editingConfig.defaultEndTime,
      );
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Configuration saved successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActivityLog(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.15),
                    child: Text(
                      employee.id,
                      style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'Activity Log',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildActivityLogItem(
                      '11:14 AM', 'Checked In', Icons.login, Colors.green),
                  _buildActivityLogItem(
                      '11:14 AM', 'Session Started', Icons.play_arrow,
                      Colors.blue),
                  _buildActivityLogItem(
                      'Now',
                      'Active - ${employee.sessionDuration}',
                      Icons.access_time,
                      Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogItem(
      String time, String action, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Text(
            time,
            style:
                TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEmployeeOptions(Employee employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              employee.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.assignment_turned_in_outlined,
                'Assign Task', Colors.blue, () {
              Navigator.pop(ctx);
              _showAssignTaskDialog(employee);
            }),
            _buildOptionTile(Icons.free_breakfast_outlined,
                'Start Break', Colors.orange, () {
              Navigator.pop(ctx);
              _toggleBreak(employee);
            }),
            _buildOptionTile(
                Icons.logout, 'Force Check Out', Colors.red, () {
              Navigator.pop(ctx);
              _confirmCheckOut(employee);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading:
          Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    );
  }

  void _toggleBreak(Employee employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Break started for ${employee.name}'),
        backgroundColor: const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _confirmCheckOut(Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Force Check Out'),
        content: Text(
            'Are you sure you want to force check out ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${employee.name} checked out'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Check Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignTaskDialog(Employee employee) {
    final taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign Task to ${employee.name}'),
        content: TextField(
          controller: taskController,
          decoration: InputDecoration(
            hintText: 'Enter task name...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Task assigned to ${employee.name}'),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Assign',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Add Employee Session',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Employee Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF2196F3),
                ),
                child: const Text('Add',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Employees',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Status',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'Working', 'On Break', 'Offline']
                  .map((s) => FilterChip(
                        label: Text(s),
                        selected: s == 'All',
                        onSelected: (_) {},
                        selectedColor:
                            const Color(0xFF2196F3).withOpacity(0.2),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting data...'),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNotificationItem(
                    'Tony Stark checked in',
                    '11:14 AM today',
                    Icons.login,
                    Colors.green,
                  ),
                  _buildNotificationItem(
                    'Chimbu checked in',
                    '11:14 AM today',
                    Icons.login,
                    Colors.green,
                  ),
                  _buildNotificationItem(
                    'Roronoa checked in late',
                    '12:01 PM today',
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      String title, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(time,
          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    );
  }
}