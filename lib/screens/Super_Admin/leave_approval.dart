import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/app_drawer.dart';


// ─── Data Models ─────────────────────────────────────────────────────────────

enum LeaveStatus { pending, approved, rejected, needsInfo, emergency }

enum LeaveType { sick, casual, annual, emergency, maternity, paternity }

class LeaveRequest {
  final String id;
  final String employeeName;
  final String? avatarInitials;
  final Color avatarColor;
  final LeaveType leaveType;
  final DateTime requestedOn;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final LeaveStatus status;
  final String? reason;
  final String department;

  const LeaveRequest({
    required this.id,
    required this.employeeName,
    this.avatarInitials,
    required this.avatarColor,
    required this.leaveType,
    required this.requestedOn,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.status,
    this.reason,
    required this.department,
  });

  String get leaveTypeLabel {
    switch (leaveType) {
      case LeaveType.sick:
        return 'SICK LEAVE';
      case LeaveType.casual:
        return 'CASUAL LEAVE';
      case LeaveType.annual:
        return 'ANNUAL LEAVE';
      case LeaveType.emergency:
        return 'EMERGENCY LEAVE';
      case LeaveType.maternity:
        return 'MATERNITY LEAVE';
      case LeaveType.paternity:
        return 'PATERNITY LEAVE';
    }
  }
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

final List<LeaveRequest> sampleLeaveRequests = [
  LeaveRequest(
    id: '1',
    employeeName: 'Chimbu',
    avatarInitials: 'CH',
    avatarColor: Colors.orange,
    leaveType: LeaveType.sick,
    requestedOn: DateTime(2026, 5, 18, 12, 20),
    fromDate: DateTime(2026, 5, 20),
    toDate: DateTime(2026, 5, 21),
    totalDays: 2,
    status: LeaveStatus.approved,
    reason: 'Feeling unwell, need rest.',
    department: 'Graphic Designing',
  ),
  LeaveRequest(
    id: '2',
    employeeName: 'Tony Stark',
    avatarInitials: 'TS',
    avatarColor: Colors.red,
    leaveType: LeaveType.casual,
    requestedOn: DateTime(2026, 5, 18, 10, 45),
    fromDate: DateTime(2026, 5, 19),
    toDate: DateTime(2026, 5, 19),
    totalDays: 1,
    status: LeaveStatus.needsInfo,
    reason: 'Personal work.',
    department: 'BDE',
  ),
  LeaveRequest(
    id: '3',
    employeeName: 'Fathima Safa',
    avatarInitials: 'FS',
    avatarColor: Colors.purple,
    leaveType: LeaveType.annual,
    requestedOn: DateTime(2026, 5, 27, 9, 0),
    fromDate: DateTime(2026, 5, 30),
    toDate: DateTime(2026, 6, 3),
    totalDays: 5,
    status: LeaveStatus.pending,
    reason: 'Family vacation planned.',
    department: 'Content Writer',
  ),
  LeaveRequest(
    id: '4',
    employeeName: 'Roronoa',
    avatarInitials: 'RO',
    avatarColor: Colors.indigo,
    leaveType: LeaveType.emergency,
    requestedOn: DateTime(2026, 5, 27, 8, 30),
    fromDate: DateTime(2026, 5, 27),
    toDate: DateTime(2026, 5, 28),
    totalDays: 2,
    status: LeaveStatus.emergency,
    reason: 'Family emergency.',
    department: 'Web Developing',
  ),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────

class LeaveApprovalsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const LeaveApprovalsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<LeaveRequest> get _pendingRequests => sampleLeaveRequests
      .where(
        (r) =>
            (r.status == LeaveStatus.pending ||
                r.status == LeaveStatus.emergency) &&
            _matchesSearch(r),
      )
      .toList();

  List<LeaveRequest> get _processedRequests => sampleLeaveRequests
      .where(
        (r) =>
            (r.status == LeaveStatus.approved ||
                r.status == LeaveStatus.rejected ||
                r.status == LeaveStatus.needsInfo) &&
            _matchesSearch(r),
      )
      .toList();

  bool _matchesSearch(LeaveRequest r) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return r.employeeName.toLowerCase().contains(q) ||
        r.leaveTypeLabel.toLowerCase().contains(q);
  }

  int get _pendingCount => sampleLeaveRequests
      .where((r) => r.status == LeaveStatus.pending)
      .length;

  int get _approvedTodayCount {
    final today = DateTime.now();
    return sampleLeaveRequests
        .where(
          (r) =>
              r.status == LeaveStatus.approved &&
              r.requestedOn.day == today.day &&
              r.requestedOn.month == today.month,
        )
        .length;
  }

  int get _emergencyCount => sampleLeaveRequests
      .where((r) => r.status == LeaveStatus.emergency)
      .length;

  int get _teamOnLeaveCount {
    final today = DateTime.now();
    return sampleLeaveRequests
        .where(
          (r) =>
              r.status == LeaveStatus.approved &&
              !today.isBefore(r.fromDate) &&
              !today.isAfter(r.toDate),
        )
        .length;
  }

  void _approveLeave(LeaveRequest req) {
    setState(() {
      final idx = sampleLeaveRequests.indexWhere((r) => r.id == req.id);
      if (idx != -1) {
        sampleLeaveRequests[idx] = LeaveRequest(
          id: req.id,
          employeeName: req.employeeName,
          avatarInitials: req.avatarInitials,
          avatarColor: req.avatarColor,
          leaveType: req.leaveType,
          requestedOn: req.requestedOn,
          fromDate: req.fromDate,
          toDate: req.toDate,
          totalDays: req.totalDays,
          status: LeaveStatus.approved,
          reason: req.reason,
          department: req.department,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave approved for ${req.employeeName}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _rejectLeave(LeaveRequest req) {
    setState(() {
      final idx = sampleLeaveRequests.indexWhere((r) => r.id == req.id);
      if (idx != -1) {
        sampleLeaveRequests[idx] = LeaveRequest(
          id: req.id,
          employeeName: req.employeeName,
          avatarInitials: req.avatarInitials,
          avatarColor: req.avatarColor,
          leaveType: req.leaveType,
          requestedOn: req.requestedOn,
          fromDate: req.fromDate,
          toDate: req.toDate,
          totalDays: req.totalDays,
          status: LeaveStatus.rejected,
          reason: req.reason,
          department: req.department,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave rejected for ${req.employeeName}'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _requestMoreInfo(LeaveRequest req) {
    setState(() {
      final idx = sampleLeaveRequests.indexWhere((r) => r.id == req.id);
      if (idx != -1) {
        sampleLeaveRequests[idx] = LeaveRequest(
          id: req.id,
          employeeName: req.employeeName,
          avatarInitials: req.avatarInitials,
          avatarColor: req.avatarColor,
          leaveType: req.leaveType,
          requestedOn: req.requestedOn,
          fromDate: req.fromDate,
          toDate: req.toDate,
          totalDays: req.totalDays,
          status: LeaveStatus.needsInfo,
          reason: req.reason,
          department: req.department,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('More info requested from ${req.employeeName}'),
        backgroundColor: const Color(0xFF0EA5E9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _bg = Theme.of(context).scaffoldBackgroundColor;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

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
                icon: Icon(Icons.menu_rounded, color: _textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(
          'Leave Approvals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
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
          // ── Header ──
          Container(
            color: _cardBg,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review and process team leave requests with full audit trail.',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 14),
                // Summary stat cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = MediaQuery.of(context).size.width >= 600;
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 24) / 4
                        : (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            iconBg: const Color(0xFFFEF3C7),
                            label: 'PENDING',
                            value: '$_pendingCount',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF10B981),
                            iconBg: const Color(0xFFD1FAE5),
                            label: 'APPROVED TODAY',
                            value: '$_approvedTodayCount',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.error_outline_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEE2E2),
                            label: 'EMERGENCY',
                            value: '$_emergencyCount',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.calendar_month_outlined,
                            iconColor: const Color(0xFF0EA5E9),
                            iconBg: const Color(0xFFE0F2FE),
                            label: 'TEAM ON LEAVE',
                            value: '$_teamOnLeaveCount',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by employee or leave type...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: _textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: _textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: _textSecondary,
                          ),
                    filled: true,
                    fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF1F5F9),
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
              ],
            ),
          ),
          // ── Tabs ──
          Container(
            color: _cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: _textSecondary,
              indicatorColor: const Color(0xFF0EA5E9),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Action Required'),
                      const SizedBox(width: 6),
                      if (_pendingRequests.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFCA8A04).withOpacity(0.2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_pendingRequests.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('History'),
                      const SizedBox(width: 6),
                      if (_processedRequests.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_processedRequests.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border),
          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Action Required Tab
                _pendingRequests.isEmpty
                    ? _EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'INBOX ZERO! NO PENDING LEAVES.',
                        subtitle: 'All leave requests have been processed.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _pendingRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _LeaveCard(
                          request: _pendingRequests[i],
                          onApprove: () => _approveLeave(_pendingRequests[i]),
                          onReject: () => _rejectLeave(_pendingRequests[i]),
                          onRequestInfo: () =>
                              _requestMoreInfo(_pendingRequests[i]),
                          onViewDetail: () => _showLeaveDetail(
                            context,
                            _pendingRequests[i],
                          ),
                          isPending: true,
                        ),
                      ),
                // History Tab
                _processedRequests.isEmpty
                    ? _EmptyState(
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFF94A3B8),
                        title: 'NO HISTORY YET.',
                        subtitle: 'Processed leave requests will appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _processedRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _LeaveHistoryTile(
                          request: _processedRequests[i],
                          onViewDetail: () => _showLeaveDetail(
                            context,
                            _processedRequests[i],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: () => _showNewLeaveSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showLeaveDetail(BuildContext context, LeaveRequest req) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LeaveDetailScreen(request: req)),
    );
  }

  void _showNewLeaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewLeaveSheet(),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.15) : iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.1,
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

// ─── Leave Card (Pending) ─────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestInfo;
  final VoidCallback onViewDetail;
  final bool isPending;

  const _LeaveCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onRequestInfo,
    required this.onViewDetail,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

    final isEmergency = request.status == LeaveStatus.emergency;
    final dateRange =
        '${DateFormat('MMM d').format(request.fromDate)} – ${DateFormat('MMM d, yyyy').format(request.toDate)}';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isEmergency
            ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
            : (isDark ? Border.all(color: _border, width: 1) : null),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: request.avatarColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    request.avatarInitials ??
                        request.employeeName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: request.avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.employeeName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isEmergency)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'EMERGENCY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFFCA8A04).withOpacity(0.2) : const Color(0xFFFEF9C3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PENDING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFDE047) : const Color(0xFFCA8A04),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.leaveTypeLabel} • ${request.department}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border),
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.date_range_outlined,
                      label: dateRange,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.wb_sunny_outlined,
                      label: '${request.totalDays} day${request.totalDays > 1 ? 's' : ''}',
                    ),
                  ],
                ),
                if (request.reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 14,
                          color: _textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.reason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Requested: ${DateFormat('MMM d, yyyy • hh:mm a').format(request.requestedOn)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: BorderSide(color: isDark ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFFFECACA)),
                      backgroundColor: isDark ? const Color(0xFFEF4444).withOpacity(0.08) : const Color(0xFFFFF5F5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequestInfo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0EA5E9),
                      side: BorderSide(color: isDark ? const Color(0xFF0EA5E9).withOpacity(0.4) : const Color(0xFFBAE6FD)),
                      backgroundColor: isDark ? const Color(0xFF0EA5E9).withOpacity(0.08) : const Color(0xFFF0F9FF),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Need Info',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // View detail link
          GestureDetector(
            onTap: onViewDetail,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Color(0xFF0EA5E9),
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

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leave History Tile ───────────────────────────────────────────────────────

class _LeaveHistoryTile extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onViewDetail;
  const _LeaveHistoryTile({required this.request, required this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

    Color getStatusColor() {
      switch (request.status) {
        case LeaveStatus.approved:
          return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
        case LeaveStatus.rejected:
          return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
        case LeaveStatus.needsInfo:
          return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);
        default:
          return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      }
    }

    Color getStatusBg() {
      switch (request.status) {
        case LeaveStatus.approved:
          return isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFD1FAE5);
        case LeaveStatus.rejected:
          return isDark ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFFEE2E2);
        case LeaveStatus.needsInfo:
          return isDark ? const Color(0xFF0EA5E9).withOpacity(0.15) : const Color(0xFFE0F2FE);
        default:
          return isDark ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFFFEF3C7);
      }
    }

    String getStatusLabel() {
      switch (request.status) {
        case LeaveStatus.approved:
          return 'APPROVED';
        case LeaveStatus.rejected:
          return 'REJECTED';
        case LeaveStatus.needsInfo:
          return 'NEEDS INFO';
        default:
          return 'PENDING';
      }
    }

    final requestedStr =
        DateFormat('MMM d, hh:mm a').format(request.requestedOn);

    return GestureDetector(
      onTap: onViewDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? Border.all(color: _border, width: 1) : null,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: request.avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                request.avatarInitials ??
                    request.employeeName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: request.avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${request.leaveTypeLabel} • ${DateFormat('MMM d').format(request.fromDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  requestedStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusBg(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    getStatusLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: getStatusColor(),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: _textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Detail Screen ──────────────────────────────────────────────────────

class _LeaveDetailScreen extends StatelessWidget {
  final LeaveRequest request;
  const _LeaveDetailScreen({required this.request});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _bg = Theme.of(context).scaffoldBackgroundColor;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

    Color getStatusColor() {
      switch (request.status) {
        case LeaveStatus.approved:
          return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
        case LeaveStatus.rejected:
          return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
        case LeaveStatus.needsInfo:
          return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);
        case LeaveStatus.emergency:
          return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
        default:
          return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      }
    }

    Color getStatusBg() {
      switch (request.status) {
        case LeaveStatus.approved:
          return isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFD1FAE5);
        case LeaveStatus.rejected:
          return isDark ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFFEE2E2);
        case LeaveStatus.needsInfo:
          return isDark ? const Color(0xFF0EA5E9).withOpacity(0.15) : const Color(0xFFE0F2FE);
        case LeaveStatus.emergency:
          return isDark ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFFEE2E2);
        default:
          return isDark ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFFFEF3C7);
      }
    }

    String getStatusLabel() {
      switch (request.status) {
        case LeaveStatus.approved:
          return 'APPROVED';
        case LeaveStatus.rejected:
          return 'REJECTED';
        case LeaveStatus.needsInfo:
          return 'NEEDS INFO';
        case LeaveStatus.emergency:
          return 'EMERGENCY';
        default:
          return 'PENDING';
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
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
          child: Container(color: _border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Employee card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: isDark ? Border.all(color: _border, width: 1) : null,
                boxShadow: isDark
                    ? []
                    : [
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: request.avatarColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      request.avatarInitials ??
                          request.employeeName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: request.avatarColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.employeeName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          request.department,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusBg(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getStatusLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: getStatusColor(),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Details
            const _SectionHeader('Leave Information'),
            const SizedBox(height: 10),
            _DetailRow(label: 'Leave Type', value: request.leaveTypeLabel),
            _DetailRow(
              label: 'From',
              value: DateFormat('EEEE, MMMM d, yyyy').format(request.fromDate),
            ),
            _DetailRow(
              label: 'To',
              value: DateFormat('EEEE, MMMM d, yyyy').format(request.toDate),
            ),
            _DetailRow(
              label: 'Total Days',
              value:
                  '${request.totalDays} day${request.totalDays > 1 ? 's' : ''}',
            ),
            _DetailRow(
              label: 'Requested On',
              value: DateFormat(
                'MMM d, yyyy • hh:mm a',
              ).format(request.requestedOn),
            ),
            if (request.reason != null) ...[
              const SizedBox(height: 16),
              const _SectionHeader('Reason'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  request.reason!,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _SectionHeader('Audit Trail'),
            const SizedBox(height: 10),
            _AuditTrailItem(
              time: DateFormat('MMM d, hh:mm a').format(request.requestedOn),
              label: 'Leave requested by ${request.employeeName}',
              color: const Color(0xFF0EA5E9),
            ),
            if (request.status == LeaveStatus.approved)
              _AuditTrailItem(
                time: DateFormat('MMM d').format(
                  request.requestedOn.add(const Duration(hours: 2)),
                ),
                label: 'Approved by Super Admin',
                color: const Color(0xFF10B981),
                isLast: true,
              )
            else if (request.status == LeaveStatus.rejected)
              _AuditTrailItem(
                time: DateFormat('MMM d').format(
                  request.requestedOn.add(const Duration(hours: 1)),
                ),
                label: 'Rejected by Super Admin',
                color: const Color(0xFFEF4444),
                isLast: true,
              )
            else if (request.status == LeaveStatus.needsInfo)
              _AuditTrailItem(
                time: DateFormat('MMM d').format(
                  request.requestedOn.add(const Duration(hours: 1)),
                ),
                label: 'More info requested by Super Admin',
                color: const Color(0xFFF59E0B),
                isLast: true,
              )
            else
              const _AuditTrailItem(
                time: 'Awaiting',
                label: 'Pending review',
                color: Color(0xFFCBD5E1),
                isLast: true,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryOf(context),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTrailItem extends StatelessWidget {
  final String time;
  final String label;
  final Color color;
  final bool isLast;
  const _AuditTrailItem({
    required this.time,
    required this.label,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _border,
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
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
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

// ─── New Leave Sheet ──────────────────────────────────────────────────────────

class _NewLeaveSheet extends StatefulWidget {
  const _NewLeaveSheet();

  @override
  State<_NewLeaveSheet> createState() => _NewLeaveSheetState();
}

class _NewLeaveSheetState extends State<_NewLeaveSheet> {
  String _selectedType = 'Sick Leave';
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _employeeCtrl = TextEditingController();

  final List<String> _leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Annual Leave',
    'Emergency Leave',
    'Maternity Leave',
    'Paternity Leave',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _employeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0EA5E9),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: isDark ? Border.all(color: _border, width: 1) : null,
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
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Leave Request',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _FieldLabel(context, 'Employee Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _employeeCtrl,
                style: TextStyle(color: _textPrimary, fontSize: 13),
                decoration: _inputDecoration(context, 'Enter employee name'),
              ),
              const SizedBox(height: 14),
              _FieldLabel(context, 'Leave Type'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: _cardBg,
                style: TextStyle(color: _textPrimary, fontSize: 13),
                decoration: _inputDecoration(context, ''),
                items: _leaveTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(fontSize: 13, color: _textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(context, 'From Date'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickDate(isFrom: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fromDate == null
                                      ? 'Select'
                                      : DateFormat('MMM d').format(_fromDate!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _fromDate == null
                                        ? _textMuted
                                        : _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(context, 'To Date'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickDate(isFrom: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _toDate == null
                                      ? 'Select'
                                      : DateFormat('MMM d').format(_toDate!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _toDate == null
                                        ? _textMuted
                                        : _textPrimary,
                                  ),
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
              const SizedBox(height: 14),
              _FieldLabel(context, 'Reason'),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                style: TextStyle(color: _textPrimary, fontSize: 13),
                decoration: _inputDecoration(context, 'Enter reason for leave...'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Leave request submitted successfully'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit Leave Request',
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _border = AppTheme.borderOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textMuted, fontSize: 13),
      filled: true,
      fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
      ),
    );
  }
}

Widget _FieldLabel(BuildContext context, String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondaryOf(context),
    ),
  );
}
