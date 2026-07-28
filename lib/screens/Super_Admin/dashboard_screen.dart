import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../theme/app_theme.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/branch_switcher.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/revenue_chart.dart';
import '../../widgets/donut_chart.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/branch/branch_cubit.dart';
import '../../blocs/department/department_bloc.dart';
import '../../models/department_model.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/project/project_bloc.dart';
import '../../models/task_model.dart' show TaskStatus;
import '../../services/bde_report_service.dart';
import '../../models/bde_report_model.dart';
import '../../services/meeting_service.dart';
import '../../models/meeting_model.dart';
import 'teams_screen.dart' show teamMembers, TeamMember;

class DashboardScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DashboardScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<bool> _notifReadState = List.filled(3, false);
  int get _unreadCount => _notifReadState.where((r) => !r).length;

  DateTimeRange? _dateRange;
  Department? _selectedDept;
  String _bdeCallsPeriod = 'Last 7 Days';

  static const String _notifPrefKey = 'sa_notif_read_state';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Load persisted notification read state
    _loadNotifReadState();

    // Trigger initial data loading from Supabase (with branch filter)
    final branchState = context.read<BranchCubit>().state;
    context.read<DashboardBloc>().add(LoadDashboardEvent(dateRange: _dateRange, branchState: branchState));
    context.read<DepartmentBloc>().add(LoadDepartmentsEvent());
    context.read<TaskBloc>().add(LoadTasksEvent());
    context.read<ProjectBloc>().add(LoadProjectsEvent());
  }

  Future<void> _loadNotifReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_notifPrefKey);
    if (saved != null && saved.length == _notifReadState.length) {
      setState(() {
        for (int i = 0; i < _notifReadState.length; i++) {
          _notifReadState[i] = saved[i] == 'true';
        }
      });
    }
  }

  Future<void> _saveNotifReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notifPrefKey,
      _notifReadState.map((v) => v.toString()).toList(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<BranchCubit, BranchState>(
              listener: (context, branchState) {
                // Reload dashboard data whenever branch changes
                context.read<DashboardBloc>().add(
                  LoadDashboardEvent(
                    dateRange: _dateRange,
                    branchState: branchState,
                  ),
                );
              },
            ),
            BlocListener<DepartmentBloc, DepartmentState>(
              listener: (context, deptState) {
                if (_selectedDept == null && deptState.departments.isNotEmpty) {
                  setState(() {
                    _selectedDept = deptState.departments.first;
                  });
                }
              },
            ),
          ],
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardInitial) {
                context.read<DashboardBloc>().add(LoadDashboardEvent(dateRange: _dateRange));
              }

              final isLoading = state is DashboardLoading;

              List<DashboardStats> stats = DashboardData.stats;
              List<ActivityItem> activities = DashboardData.activities;
              List<ProjectItem> projectsList = DashboardData.projects;
              List<RecentTask> tasksList = DashboardData.tasks;
              List<RevenuePoint> revenuePoints = DashboardData.revenueData;
              double totalRevenueVal = 2500;
              double receivablesVal = 2720;

              if (state is DashboardLoaded) {
                stats = state.stats;
                activities = state.activities;
                projectsList = state.projects;
                tasksList = state.tasks;
                revenuePoints = state.revenueData;
                totalRevenueVal = state.totalRevenue;
                receivablesVal = state.receivables;
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildTopBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildPageHeader(),
                                const SizedBox(height: 20),
                                _buildTabBar(),
                                if (_selectedTab == 0) ...[
                                  const SizedBox(height: 20),
                                  _buildDataVisibilityHeader(),
                                  const SizedBox(height: 14),
                                  _buildStatsGrid(stats),
                                  const SizedBox(height: 24),
                                  _buildActivitySection(activities),
                                  const SizedBox(height: 20),
                                  _buildClientSatisfactionCard(),
                                  const SizedBox(height: 24),
                                  _buildBdeCallsConnectedAnalytics(),
                                  const SizedBox(height: 24),
                                  _buildBdeDailyReportsSection(),
                                  const SizedBox(height: 24),
                                  _buildDynamicWorkspaceHeader(),
                                  const SizedBox(height: 16),
                                  _buildMeetingSchedulesSection(),
                                  const SizedBox(height: 16),
                                  _buildRevenueCard(totalRevenueVal, revenuePoints),
                                  const SizedBox(height: 16),
                                  _buildActiveProjectsCard(projectsList),
                                  const SizedBox(height: 16),
                                  _buildRecentTasksCard(tasksList),
                                  const SizedBox(height: 16),
                                  _buildBottomRow(totalRevenueVal, receivablesVal),
                                ] else ...[
                                  _buildDepartmentIntelligence(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Icon(Icons.menu_rounded,
                  color: AppTheme.textSecondaryOf(context), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      color: AppTheme.textMutedOf(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Search...',
                      style: TextStyle(
                          color: AppTheme.textMutedOf(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Branch icon button — fixed 38×38 like other top bar actions
          _buildBranchIconButton(),
          const SizedBox(width: 8),
          _buildThemeToggleButton(),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _showNotificationsPanel,
                child: _buildTopBarAction(Icons.notifications_none_rounded),
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$_unreadCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.read<ThemeBloc>().add(ToggleThemeEvent());
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: AppTheme.textSecondaryOf(context),
          size: 18,
        ),
      ),
    );
  }

  /// Fixed 38×38 branch icon button — same footprint as other top bar actions.
  /// Color-coded icon indicates the active branch; tap opens the full picker.
  Widget _buildBranchIconButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, branchState) {
        final filter = branchState.selectedBranch;
        Color accent;
        IconData icon;
        switch (filter) {
          case BranchFilter.allBranches:
            accent = const Color(0xFF6B7280);
            icon = Icons.public_rounded;
            break;
          case BranchFilter.calicut:
            accent = const Color(0xFF0A84FF);
            icon = Icons.location_on_rounded;
            break;
          case BranchFilter.dubai:
            accent = const Color(0xFFF59E0B);
            icon = Icons.business_rounded;
            break;
        }
        return Tooltip(
          message: filter.displayName,
          child: GestureDetector(
            onTap: () {
              final cubit = context.read<BranchCubit>();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: BranchSwitcher.buildPickerSheet(
                    context: context,
                    current: filter,
                    isDark: isDark,
                  ),
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBarAction(IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Icon(icon, color: AppTheme.textSecondaryOf(context), size: 18),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showProfilePanel,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF34AAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text('SA',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }

  void _showProfilePanel() {
    final authState = context.read<AuthBloc>().state;
    String fullName = 'Super Admin';
    String email = '';
    String role = 'super_admin';
    String initials = 'SA';

    if (authState is Authenticated) {
      email = authState.user.email ?? '';
      role = authState.user.userMetadata?['role']?.toString() ?? authState.role;
      final meta = authState.user.userMetadata;
      final name = meta?['full_name']?.toString() ?? meta?['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        fullName = name;
        final parts = name.trim().split(' ');
        initials = parts.length >= 2
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        fullName: fullName,
        email: email,
        role: role,
        initials: initials,
        onLogout: () {
          Navigator.pop(ctx);
          context.read<AuthBloc>().add(AuthLogoutEvent());
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Operational command center',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF34AAFF)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('New',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.business_center_outlined, 'Enterprise Overview'),
          _buildTab(1, Icons.people_alt_outlined, 'Department Intelligence'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: isActive
                      ? Colors.white
                      : AppTheme.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataVisibilityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text(
                  'DATA VISIBILITY',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Analyze your metrics by timeframe',
              style: TextStyle(
                  color: AppTheme.textMutedOf(context),
                  fontSize: 10.5),
            ),
          ],
        ),
        Row(
          children: [
            _buildTimeButton('All Time', _dateRange == null, onTap: () {
              setState(() {
                _dateRange = null;
              });
              context.read<DashboardBloc>().add(LoadDashboardEvent(dateRange: null));
            }),
            const SizedBox(width: 6),
            _buildTimeButton(
              _dateRange == null
                  ? 'Custom Range'
                  : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
              _dateRange != null,
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() {
                    _dateRange = range;
                  });
                  context.read<DashboardBloc>().add(LoadDashboardEvent(dateRange: range));
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, bool isActive, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? AppTheme.primary : AppTheme.borderOf(context)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondaryOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<DashboardStats> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            int targetIndex = 0;
            switch (i) {
              case 0:
                targetIndex = 7; // Billing
                break;
              case 1:
                targetIndex = 4; // Projects
                break;
              case 2:
                targetIndex = 5; // Tasks
                break;
              case 3:
                targetIndex = 16; // HR & Payroll
                break;
              default:
                targetIndex = 0;
            }
            widget.onItemSelected(targetIndex);
          },
          child: StatCard(stat: stats[i], index: i),
        );
      },
    );
  }

  Widget _buildActivitySection(List<ActivityItem> activities) {
    return _SectionCard(
      title: 'RECENT OPERATIONAL ACTIVITY',
      subtitle: 'Real-time log of administrative and system events',
      trailing: _liveBadge(),
      child: Column(
        children: activities
            .map((a) => _buildActivityItem(a))
            .toList(),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.success.withOpacity(0.15)
            : AppTheme.successLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppTheme.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: [
                AppTheme.primary,
                AppTheme.success,
                AppTheme.warning
              ][a.colorIndex % 3],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${a.user} ',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '${a.action} ',
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 12.5,
                    ),
                  ),
                  TextSpan(
                    text: a.target,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            a.timeAgo,
            style: TextStyle(
                color: AppTheme.textMutedOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicWorkspaceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text('DYNAMIC WORKSPACE',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    )),
              ],
            ),
            const SizedBox(height: 2),
            Text('Personalize your command center layout',
                style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10.5)),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: const Text('Reset Layout',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(double totalRevenue, List<RevenuePoint> revenuePoints) {
    return _SectionCard(
      title: 'REVENUE VELOCITY',
      subtitle: '',
      headerIcon: Icons.trending_up_rounded,
      trailing: _operationalBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${totalRevenue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryOf(context),
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.success.withOpacity(0.15)
                      : AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 12, color: AppTheme.success),
                    Text('+12.5%',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RevenueChart(points: revenuePoints),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Pipeline', AppTheme.primary.withOpacity(0.5), isDashed: true),
              const SizedBox(width: 16),
              _buildLegendItem('Actual Revenue', AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _operationalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Text('OPERATIONAL',
          style: TextStyle(
              color: AppTheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildActiveProjectsCard(List<ProjectItem> projects) {
    return _SectionCard(
      title: 'Active Projects',
      subtitle: '',
      headerIcon: Icons.folder_outlined,
      child: Column(
        children: projects
            .map((p) => _buildProjectItem(p))
            .toList(),
      ),
    );
  }

  Widget _buildProjectItem(ProjectItem p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.client} - ${p.name}',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(p.progress * 100).toInt()}%',
                style: TextStyle(
                  color: p.progress == 1.0
                      ? AppTheme.success
                      : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.progress,
              backgroundColor: AppTheme.borderOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                p.progress == 1.0 ? AppTheme.primary : AppTheme.textMutedOf(context),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.taskCount} / ${p.totalTasks} TASKS',
            style: TextStyle(
                color: AppTheme.textMutedOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasksCard(List<RecentTask> tasks) {
    return _SectionCard(
      title: 'Recent Tasks',
      subtitle: '',
      headerIcon: Icons.check_circle_outline_rounded,
      child: Column(
        children: tasks
            .map((t) => _buildTaskItem(t))
            .toList(),
      ),
    );
  }

  Widget _buildTaskItem(RecentTask t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.project,
                  style: TextStyle(
                      color: AppTheme.textMutedOf(context),
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success.withOpacity(0.2)),
            ),
            child: Text(
              t.status,
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(double totalRevenue, double receivables) {
    return Column(
      children: [
        _SectionCard(
          title: 'CRITICAL DEADLINES',
          subtitle: '',
          headerIcon: Icons.warning_amber_rounded,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 40),
                  const SizedBox(height: 8),
                  Text('ALL RESOURCES ARE STABLE',
                      style: TextStyle(
                          color: AppTheme.textMutedOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFinancialLiquidity(totalRevenue, receivables),
      ],
    );
  }

  Widget _buildFinancialLiquidity(double totalRevenue, double receivables) {
    final total = totalRevenue + receivables;
    final double percentage = total > 0 ? (totalRevenue / total * 100) : 0.0;
    final double fractionPaid = total > 0 ? (totalRevenue / total) : 0.0;
    final double fractionUnpaid = total > 0 ? (receivables / total) : 0.0;

    return _SectionCard(
      title: 'FINANCIAL LIQUIDITY',
      subtitle: '',
      headerIcon: Icons.account_balance_wallet_outlined,
      headerIconColor: AppTheme.success,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DonutChart(
            percentage: percentage,
            label: 'HEALTH',
            color: AppTheme.primary,
            size: 100,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildLiquidityItem('LIQUID ASSETS', '₹${totalRevenue.toStringAsFixed(0)}', AppTheme.primary, fractionPaid),
                const SizedBox(height: 16),
                _buildLiquidityItem('RECEIVABLES', '₹${receivables.toStringAsFixed(0)}', AppTheme.info, fractionUnpaid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityItem(
      String label, String value, Color color, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            Text(value,
                style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppTheme.borderOf(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentIntelligence() {
    return BlocBuilder<DepartmentBloc, DepartmentState>(
      builder: (context, deptState) {
        final departments = deptState.departments;
        
        if (_selectedDept == null && departments.isNotEmpty) {
          _selectedDept = departments.first;
        } else if (_selectedDept != null && departments.isNotEmpty) {
          final index = departments.indexWhere((d) => d.id == _selectedDept!.id);
          if (index != -1) {
            _selectedDept = departments[index];
          } else {
            _selectedDept = departments.first;
          }
        }

        int staffCount = 0;
        int activeTasksCount = 0;
        int totalTasksCount = 0;
        double capacityAllocation = 0.0;
        List<TeamMember> deptMembers = [];

        if (_selectedDept != null) {
          deptMembers = teamMembers.where((m) => m.department.toLowerCase() == _selectedDept!.name.toLowerCase()).toList();
          staffCount = deptMembers.length;

          final taskState = context.read<TaskBloc>().state;
          final deptMemberNames = deptMembers.map((m) => m.name.toLowerCase()).toList();
          
          final deptTasks = taskState.tasks.where((t) {
            if (t.owner == null) return false;
            return deptMemberNames.contains(t.owner!.toLowerCase());
          }).toList();

          totalTasksCount = deptTasks.length;
          final activeTasks = deptTasks.where((t) => t.status != TaskStatus.done).toList();
          activeTasksCount = activeTasks.length;

          final double weeklyCapacity = staffCount * 40.0;
          final double activeWorkloadHours = activeTasksCount * 10.0; 
          capacityAllocation = weeklyCapacity > 0 ? (activeWorkloadHours / weeklyCapacity) : 0.0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildDeptWorkspaceHeader(departments),
            const SizedBox(height: 16),
            _buildDeptStatsGrid(staffCount, activeTasksCount, capacityAllocation),
            const SizedBox(height: 20),
            _buildProductivityChart(),
            const SizedBox(height: 20),
            _buildKpiAndAlerts(activeTasksCount, totalTasksCount, capacityAllocation),
            const SizedBox(height: 20),
            _buildWorkforceAlignment(deptMembers),
          ],
        );
      },
    );
  }

  Widget _buildDeptWorkspaceHeader(List<Department> departments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEPARTMENT OPERATIONS WORKSPACE',
          style: TextStyle(
            color: AppTheme.textPrimaryOf(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ADMIN CONTROL COCKPIT: DYNAMICALLY SWITCH AND AGGREGATE CORPORATE DEPARTMENTS.',
          style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildCockpitDropdown(departments),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAddDepartmentDialog(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
            if (_selectedDept != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditDepartmentDialog(_selectedDept!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.info,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeleteDepartmentConfirm(_selectedDept!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 16),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCockpitDropdown(List<Department> departments) {
    return PopupMenuButton<Department>(
      onSelected: (dept) {
        setState(() {
          _selectedDept = dept;
        });
      },
      itemBuilder: (context) {
        return departments.map((d) {
          return PopupMenuItem<Department>(
            value: d,
            child: Text(d.name),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedDept == null ? 'SELECT COCKPIT' : 'COCKPIT: ${_selectedDept!.name.toUpperCase()}',
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }

  void _showAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (name.isNotEmpty) {
                  context.read<DepartmentBloc>().add(AddDepartmentEvent(name: name, description: desc));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDepartmentDialog(Department dept) {
    final nameCtrl = TextEditingController(text: dept.name);
    final descCtrl = TextEditingController(text: dept.description);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Department Name'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (name.isNotEmpty) {
                  final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                  final updated = Department(
                    id: dept.id,
                    name: name,
                    description: desc,
                    slug: slug,
                  );
                  context.read<DepartmentBloc>().add(UpdateDepartmentEvent(updated));
                  setState(() {
                    _selectedDept = updated;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDepartmentConfirm(Department dept) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text('Are you sure you want to delete the department "${dept.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () {
                context.read<DepartmentBloc>().add(DeleteDepartmentEvent(dept.id));
                setState(() {
                  _selectedDept = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeptStatsGrid(int staffCount, int activeTasksCount, double capacityAllocation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyCapacityHours = staffCount * 40;
    final activeWorkloadHours = activeTasksCount * 10;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildDeptStatCard(
          'Dept Capacity',
          '$staffCount Staff',
          '${weeklyCapacityHours}H CAPACITY WEEKLY',
          Icons.people_alt_outlined,
          AppTheme.primary,
          isDark ? AppTheme.primary.withOpacity(0.15) : AppTheme.primaryLight,
        ),
        _buildDeptStatCard(
          'Active Workload',
          '$activeWorkloadHours hrs',
          '$activeTasksCount TOTAL ACTIVE TASKS',
          Icons.access_time_rounded,
          AppTheme.info,
          isDark ? AppTheme.info.withOpacity(0.15) : AppTheme.infoLight,
        ),
        _buildDeptStatCard(
          'Capacity Allocation',
          '${(capacityAllocation * 100).toStringAsFixed(0)}%',
          'OPTIMAL WORK BALANCE',
          Icons.trending_up_rounded,
          AppTheme.textSecondaryOf(context),
          isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        ),
        _buildDeptStatCard(
          'Time Desk Status',
          '${(staffCount * 0.6).round()} Clocked',
          '${(staffCount * 0.4).round()} OFF SHIFT',
          Icons.insights_rounded,
          AppTheme.success,
          isDark ? AppTheme.success.withOpacity(0.15) : AppTheme.successLight,
        ),
      ],
    );
  }

  Widget _buildDeptStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.cardShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.textSecondaryOf(context),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textMutedOf(context),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityChart() {
    return _SectionCard(
      title: 'DEPARTMENT PRODUCTIVITY METRICS',
      subtitle: 'VISUAL REPORTING ENGINE AGGREGATED IN REAL TIME.',
      trailing: Row(
        children: [
          _buildExportButton(Icons.download_rounded, 'CSV'),
          const SizedBox(width: 6),
          _buildExportButton(Icons.picture_as_pdf_rounded, 'PDF'),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _DeptChartPainter(
                borderColor: AppTheme.borderOf(context),
                textColor: AppTheme.textMutedOf(context),
              ),
              child: const SizedBox(height: 160, width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryOf(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiAndAlerts(int activeTasks, int totalTasks, double capacityAllocation) {
    final completedTasks = totalTasks - activeTasks;
    final double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final String compValueStr = '$completedTasks / $totalTasks tasks';

    return Column(
      children: [
        _SectionCard(
          title: 'DEPARTMENT KPI ENGINES',
          subtitle: 'ENTERPRISE METRIC SCOPES AGGREGATED DYNAMICALLY.',
          child: Column(
            children: [
              _buildKpiItem('Task Completion Rate', compValueStr, completionRate),
              const SizedBox(height: 16),
              _buildKpiItem('Staff Utilization', '${(capacityAllocation * 100).toStringAsFixed(0)} %', capacityAllocation.clamp(0.0, 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'OPERATIONAL ALERTS & ESCALATE',
          subtitle: 'URGENT DEPARTMENT INCIDENTS REQUIRING LEAD ACTION.',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    capacityAllocation > 1.0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: capacityAllocation > 1.0 ? AppTheme.error : AppTheme.success,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    capacityAllocation > 1.0 ? 'OVER CAPACITY ALERT' : 'SLA HEALTH: OPTIMUM',
                    style: TextStyle(
                      color: capacityAllocation > 1.0 ? AppTheme.error : AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiItem(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderOf(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkforceAlignment(List<TeamMember> deptMembers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return _SectionCard(
      title: 'WORKFORCE ALIGNMENT & OPERATIONS',
      subtitle: 'OVERVIEW OF PERSONNEL MAPPED TO THE ACTIVE DEPARTMENT STRUCTURE.',
      child: deptMembers.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderOf(context),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded,
                      color: AppTheme.textMutedOf(context), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'NO STAFF MAPPED TO THIS DEPARTMENT',
                    style: TextStyle(
                      color: AppTheme.textMutedOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deptMembers.length,
              itemBuilder: (context, i) {
                final m = deptMembers[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            m.initials,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(
                                color: AppTheme.textPrimaryOf(context),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.role,
                              style: TextStyle(
                                color: AppTheme.textMutedOf(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsSheet(
        notifReadState: _notifReadState,
        onMarkRead: (i) {
          setState(() {
            _notifReadState[i] = true;
          });
          _saveNotifReadState();
        },
        onMarkAllRead: () {
          setState(() {
            for (int j = 0; j < _notifReadState.length; j++) {
              _notifReadState[j] = true;
            }
          });
          _saveNotifReadState();
        },
        onNavigate: (index) {
          Navigator.pop(ctx);
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }

  // ── 1. CLIENT SATISFACTION WIDGET ─────────────────────────────────────────────
  Widget _buildClientSatisfactionCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionCard(
      title: 'CLIENT SATISFACTION',
      subtitle: 'REAL-TIME CUSTOMER FEEDBACK INSIGHTS.',
      headerIcon: Icons.star_outline_rounded,
      headerIconColor: Colors.amber,
      trailing: TextButton(
        onPressed: () => widget.onItemSelected(3),
        child: const Text('View All', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Text('4.4', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.amber)),
                    SizedBox(width: 6),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on 5 client responses. Customer loyalty is stable.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('CRITICAL ALERTS (1)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('SPROUT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text('"We appreciate the improved efforts and communication demonstrated by the team during sprint reviews."',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondaryOf(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. BDE CALLS CONNECTED ANALYTICS SECTION ─────────────────────────────────
  Widget _buildBdeCallsConnectedAnalytics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionCard(
      title: 'BDE CALLS CONNECTED ANALYTICS',
      subtitle: 'Admin Overview: Outbound & Inbound Connected Calls by BDE Executives',
      headerIcon: Icons.phone_callback_rounded,
      headerIconColor: AppTheme.primary,
      trailing: OutlinedButton.icon(
        onPressed: () {
          AppSnackBar.showCustom(context, 
            const SnackBar(content: Text('Exporting BDE Calls Analytics CSV...'), backgroundColor: AppTheme.primary),
          );
        },
        icon: const Icon(Icons.download_outlined, size: 12),
        label: const Text('EXPORT CSV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'Last 7 Days', 'Last 30 Days', 'Custom'].map((period) {
                final selected = _bdeCallsPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(period, style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppTheme.textSecondaryOf(context))),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                    onSelected: (val) {
                      if (val) setState(() => _bdeCallsPeriod = period);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Summary KPI Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _bdeKpiCard('TOTAL CALLS CONNECTED', '2', 'Sum of all connected calls', Icons.phone_in_talk_rounded, const Color(0xFF3B82F6)),
              _bdeKpiCard('OUTBOUND CALLS', '2', 'Calls initiated by BDEs', Icons.call_made_rounded, const Color(0xFF10B981)),
              _bdeKpiCard('INBOUND CALLS', '0', 'Received from leads & clients', Icons.call_received_rounded, const Color(0xFF8B5CF6)),
              _bdeKpiCard('ACTIVE BDE CALLERS', '2', 'BDEs with active call logs', Icons.people_outline_rounded, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),

          // BDE Executive Breakdown Cards
          Text('BDE EXECUTIVE BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryOf(context), letterSpacing: 0.8)),
          const SizedBox(height: 8),
          _bdeExecutiveRow('KEERTHI', 'keerthi.ecraftz@gmail.com', 1, 1, 0, 100, 0),
          const SizedBox(height: 8),
          _bdeExecutiveRow('ALHAJ', 'alhajecraftz@gmail.com', 1, 1, 0, 100, 0),
        ],
      ),
    );
  }

  Widget _bdeKpiCard(String label, String value, String sub, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
              Text(sub, style: TextStyle(fontSize: 8.5, color: AppTheme.textSecondaryOf(context)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bdeExecutiveRow(String name, String email, int total, int outbound, int inbound, int ratioOut, int meetings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
                  Text(email, style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$total Calls', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Outbound: $outbound', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
              Text('Inbound: $inbound', style: const TextStyle(fontSize: 10, color: Color(0xFF8B5CF6))),
              Text('Call Ratio: Out $ratioOut%', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
              Text('Meetings: $meetings', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. BDE DAILY REPORTS (ADMIN VIEW) SECTION ─────────────────────────────────
  Widget _buildBdeDailyReportsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionCard(
      title: 'BDE DAILY REPORTS (ADMIN VIEW)',
      subtitle: 'MONITOR ALL BUSINESS DEVELOPMENT EXECUTIVES',
      headerIcon: Icons.assignment_outlined,
      headerIconColor: const Color(0xFFF59E0B),
      child: FutureBuilder<List<BdeReportEntry>>(
        future: BdeReportService.instance.allReports(forAdmin: true),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.feed_outlined, size: 32, color: AppTheme.textMutedOf(context)),
                    const SizedBox(height: 8),
                    Text('NO BDE REPORTS FOUND FOR THIS PERIOD.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMutedOf(context), letterSpacing: 0.5)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: reports.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.staffName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
                        Text(DateFormat('dd MMM yyyy').format(r.reportDate), style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Database Count: ${r.login.databaseCount} | Planned: ${r.login.databasePlanned}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                    if (r.logout != null) ...[
                      const SizedBox(height: 4),
                      Text('Calls Connected: ${r.logout!.callsConnected} | Meetings: ${r.logout!.meetingsAttended}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ── 4. MEETING SCHEDULES SECTION ──────────────────────────────────────────────
  Widget _buildMeetingSchedulesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionCard(
      title: 'MEETING SCHEDULES',
      subtitle: 'Client discovery calls, product demos & follow-ups',
      headerIcon: Icons.calendar_today_rounded,
      headerIconColor: AppTheme.primary,
      trailing: ElevatedButton.icon(
        onPressed: () {
          widget.onItemSelected(10);
        },
        icon: const Icon(Icons.add, size: 12, color: Colors.white),
        label: const Text('+ SCHEDULE MEETING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
      ),
      child: FutureBuilder<List<Meeting>>(
        future: MeetingService.instance.fetchAllMeetings(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
          }

          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 32, color: AppTheme.textMutedOf(context)),
                    const SizedBox(height: 8),
                    Text('NO UPCOMING MEETINGS SCHEDULED.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMutedOf(context), letterSpacing: 0.5)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: meetings.take(5).map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videocam_outlined, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
                          Text('${m.meetingType} • ${DateFormat('dd MMM, hh:mm a').format(m.scheduledAt)}',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(m.status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.success)),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _DeptChartPainter extends CustomPainter {
  final Color borderColor;
  final Color textColor;
  _DeptChartPainter({required this.borderColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 16;
    const double paddingRight = 16;
    const double paddingTop = 10;
    const double paddingBottom = 20;

    final double chartW = size.width - paddingLeft - paddingRight;
    final double chartH = size.height - paddingTop - paddingBottom;
    final double stepX = chartW / 4; // 5 days: Mon, Tue, Wed, Thu, Fri

    // Draw grid lines
    final gridPaint = Paint()
      ..color = borderColor.withOpacity(0.6)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (chartH / 4) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 0; i < 5; i++) {
      final x = paddingLeft + i * stepX;
      canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartH), gridPaint);
    }

    // Draw labels
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < 5; i++) {
      final x = paddingLeft + i * stepX;
      final tp = TextPainter(
        text: TextSpan(text: days[i], style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - paddingBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;
  final IconData? headerIcon;
  final Color? headerIconColor;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.headerIcon,
    this.headerIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.cardShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (headerIcon != null) ...[
                      Icon(headerIcon!,
                          size: 15,
                          color:
                              headerIconColor ?? AppTheme.textSecondaryOf(context)),
                      const SizedBox(width: 7),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textPrimaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: AppTheme.textMutedOf(context), fontSize: 10.5)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String pageLabel;
  final int pageIndex;

  _NotifItem(this.title, this.subtitle, this.time, this.icon, this.iconColor, this.pageLabel, this.pageIndex);
}

class _NotificationsSheet extends StatelessWidget {
  final List<bool> notifReadState;
  final Function(int) onMarkRead;
  final VoidCallback onMarkAllRead;
  final Function(int) onNavigate;

  const _NotificationsSheet({
    required this.notifReadState,
    required this.onMarkRead,
    required this.onMarkAllRead,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.surface;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    final notifications = [
      _NotifItem('New Lead Received', 'From Website Form', '2m ago', Icons.person_add_rounded, const Color(0xFF10B981), 'Leads', 3),
      _NotifItem('Task Assigned', 'Review new designs', '1h ago', Icons.check_circle_outline_rounded, const Color(0xFF3B82F6), 'Tasks', 4),
      _NotifItem('Project Updated', 'Website Redesign', '3h ago', Icons.folder_open_rounded, const Color(0xFF8B5CF6), 'Projects', 2),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Notifications', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: onMarkAllRead,
                    child: const Text('Mark all read', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(color: border, height: 16),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  final isRead = notifReadState[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onMarkRead(i);
                        onNavigate(n.pageIndex);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRead ? (isDark ? const Color(0xFF132238) : const Color(0xFFF8FAFC)) : (isDark ? AppTheme.primary.withOpacity(0.05) : AppTheme.primary.withOpacity(0.02)),
                          borderRadius: BorderRadius.circular(12),
                          border: isRead ? null : Border.all(color: AppTheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: n.iconColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(n.icon, color: n.iconColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.subtitle,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: n.iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Go to ${n.pageLabel}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: n.iconColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(n.time, style: TextStyle(fontSize: 10, color: textMuted)),
                                const SizedBox(height: 12),
                                Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Sheet ──────────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final String initials;
  final VoidCallback onLogout;

  const _ProfileSheet({
    required this.fullName,
    required this.email,
    required this.role,
    required this.initials,
    required this.onLogout,
  });

  String _formatRole(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.75,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          child: Column(
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
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF34AAFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                fullName,
                style: TextStyle(
                  color: AppTheme.textPrimaryOf(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  _formatRole(role),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Info cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email.isNotEmpty ? email : '—',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.shield_outlined,
                      label: 'Access Level',
                      value: _formatRole(role),
                      isDark: isDark,
                      valueColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.error, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textMutedOf(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
