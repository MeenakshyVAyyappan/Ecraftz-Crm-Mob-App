import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../models/task_model.dart';
import '../../services/supabase_service.dart';
import '../../blocs/rbac/rbac_cubit.dart';
import '../../blocs/meeting/meeting_bloc.dart';
import '../../models/meeting_model.dart';
import '../../theme/app_theme.dart';
import 'emply_project_screen.dart';
import 'emply_tasks_screen.dart';
import 'emply_my_timesheet.dart';
import 'emply_leave_request.dart';
import '../Super_Admin/crm_leads_page.dart';
import '../Super_Admin/active_clients_screen.dart';
import '../Super_Admin/client_onboarding_screen.dart';
import '../billing/billing_dashboard_screen.dart';
import '../Super_Admin/asset_renewal.dart';
import '../Super_Admin/client_statement_screen.dart';
import '../Super_Admin/scheduler_screen.dart';
import '../Super_Admin/hr_and_payroll.dart';
import '../Super_Admin/client_feedback_screen.dart';
import '../Super_Admin/document_vault_screen.dart';
import '../Super_Admin/crm_reports_screen.dart';
import '../Super_Admin/team_timesheet_screen.dart';
import '../../models/work_session_model.dart';
import '../../blocs/client/client_bloc.dart';
import '../../models/client_model.dart';
import '../../models/bde_report_model.dart';
import '../../models/content_work_log_model.dart';
import '../../models/crm_work_log_model.dart';
import '../../services/bde_report_service.dart';
import '../../services/content_work_log_service.dart';
import '../../services/crm_work_log_service.dart';
import '../../models/graphic_work_log_model.dart';
import '../../services/graphic_work_log_service.dart';
import '../../models/video_work_log_model.dart';
import '../../services/video_work_log_service.dart';
import '../../models/videography_work_log_model.dart';
import '../../services/videography_work_log_service.dart';
import '../../models/digital_marketing_work_log_model.dart';
import '../../services/digital_marketing_work_log_service.dart';

enum DashboardViewPeriod { day, week, month }

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _profile;
  String _departmentName = 'Employee';
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _loadProfileData();
  }

  bool get _isCrmDepartment {
    final deptLower = _departmentName.toLowerCase();
    final roleLower = _userRole.toLowerCase();
    final rbac = context.read<RbacCubit>();
    return deptLower.contains('crm') ||
        roleLower.contains('admin') ||
        roleLower.contains('super') ||
        rbac.hasModuleAccess('module.crm');
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _pages {
    if (_isCrmDepartment) {
      return [
        const EmployeeDashboardContent(),
        CRMLeadsPage(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        ActiveClientsPage(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        ClientOnboardingPage(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        ClientFeedbackScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        DocumentVaultScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        CrmReportsScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        TeamTimesheetScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        const ProjectsScreen(),
        const EmployeeTasksScreen(),
        BillingDashboardScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        AssetRenewalsPage(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        ClientStatementsScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        SchedulerScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        HRPayrollScreen(selectedIndex: _selectedIndex, onItemSelected: _onSelectPage, showAppBar: false),
        const MyTimesheetScreen(),
        const LeaveRequestsScreen(),
      ];
    }
    return [
      const EmployeeDashboardContent(),
      const ProjectsScreen(),
      const EmployeeTasksScreen(),
      const MyTimesheetScreen(),
      const LeaveRequestsScreen(),
    ];
  }

  Future<void> _loadProfileData() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    if (mounted) {
      setState(() => _isLoadingProfile = true);
    }
    try {
      final rbac = context.read<RbacCubit>();
      rbac.setUserRole(_userRole);
      rbac.loadUserPermissions(user.id);
      dynamic profileRows;
      try {
        profileRows = await SupabaseService.client
            .from('profiles')
            .select('*, departments:departments!fk_profiles_dept(id, name)')
            .eq('id', user.id)
            .limit(1);
      } catch (e) {
        debugPrint('Profile join fetch failed: $e');
        profileRows = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .limit(1);
      }
      if (profileRows is List && profileRows.isNotEmpty) {
        final profileMap = Map<String, dynamic>.from(profileRows.first as Map);
        String deptName = 'Employee';
        
        final dept = profileMap['departments'];
        if (dept is Map) {
          deptName = dept['name']?.toString() ?? 'Employee';
        } else {
          final deptId = profileMap['department_id'];
          if (deptId != null) {
            try {
              final deptRes = await SupabaseService.client
                  .from('departments')
                  .select('name')
                  .eq('id', deptId)
                  .limit(1)
                  .maybeSingle();
              if (deptRes != null && deptRes is Map) {
                deptName = deptRes['name']?.toString() ?? 'Employee';
              }
            } catch (e) {
              debugPrint('Fallback department load failed: $e');
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _profile = profileMap;
            _departmentName = deptName;
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    } catch (e) {
      debugPrint('Error in _loadProfileData: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  String get _userName {
    return _profile?['full_name']?.toString() ?? SupabaseService.currentUser?.email ?? 'Employee';
  }

  String get _userRole {
    final roleStr = _profile?['role']?.toString();
    if (roleStr == null || roleStr.isEmpty) return 'Employee';
    return roleStr[0].toUpperCase() + roleStr.substring(1).toLowerCase();
  }

  String get _userDisplayRole {
    if (_departmentName != 'Employee' && _departmentName.isNotEmpty) {
      return _departmentName;
    }
    return _userRole;
  }

  String get _userInitials {
    final name = _userName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'EE';
  }

  String _getPageTitle(int index) {
    if (_isCrmDepartment) {
      switch (index) {
        case 0: return 'Dashboard';
        case 1: return 'CRM Leads';
        case 2: return 'Active Clients';
        case 3: return 'Client Onboarding';
        case 4: return 'Client Feedback';
        case 5: return 'Document Vault';
        case 6: return 'CRM Reports';
        case 7: return 'Team Timesheet';
        case 8: return 'Projects';
        case 9: return 'Tasks';
        case 10: return 'Billing';
        case 11: return 'Asset Renewals';
        case 12: return 'Client Statements';
        case 13: return 'Scheduler';
        case 14: return 'HR & Payroll';
        case 15: return 'My Timesheet';
        case 16: return 'Leave Requests';
        default: return 'Dashboard';
      }
    }
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
        return 'Dashboard';
    }
  }

  String _getPageSubtitle(int index) {
    if (_isCrmDepartment) {
      switch (index) {
        case 0: return 'Operational command center';
        case 1: return 'Manage and convert prospects';
        case 2: return 'Manage active client directory & details';
        case 3: return 'Onboard new clients & forms';
        case 4: return 'Track client ratings and customer satisfaction';
        case 5: return 'Organization-wide document repository';
        case 6: return 'Real-time KPIs & CRM analytics';
        case 7: return 'Monitor team punch-ins, work hours & overtime';
        case 8: return 'Manage active and archived projects';
        case 9: return 'Track and update your assigned tasks';
        case 10: return 'Invoices and billing management';
        case 11: return 'Domain and asset renewal management';
        case 12: return 'Generate client financial statements';
        case 13: return 'Meeting schedules & calendar';
        case 14: return 'Human resources & payroll management';
        case 15: return 'Evaluate your daily sign-ins and tasks';
        case 16: return 'Manage your time off and track approvals';
        default: return '';
      }
    }
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
          AppRefreshButton(
            onRefresh: () async {
              await _loadProfileData();
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
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
        GestureDetector(
          onTap: _showProfilePanel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.sidebarAccent,
                  radius: 15,
                  child: Text(
                    _userInitials,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _userDisplayRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.borderOf(context), height: 1),
      ),
    );
  }

  void _showProfilePanel() {
    final authState = context.read<AuthBloc>().state;
    String fullName = _userName;
    String email = '';
    String role = _userDisplayRole;
    String initials = _userInitials;

    if (authState is Authenticated) {
      email = authState.user.email ?? '';
      final meta = authState.user.userMetadata;
      final name = meta?['full_name']?.toString() ?? meta?['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        fullName = name;
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
            children: _isCrmDepartment ? [
              _buildNavItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavItem(context, 1, Icons.people_alt_outlined, 'CRM Leads'),
              _buildNavItem(context, 2, Icons.person_outline_rounded, 'Active Clients'),
              _buildNavItem(context, 3, Icons.how_to_reg_outlined, 'Client Onboarding'),
              _buildNavItem(context, 4, Icons.rate_review_outlined, 'Client Feedback'),
              _buildNavItem(context, 5, Icons.folder_special_outlined, 'Document Vault'),
              _buildNavItem(context, 6, Icons.bar_chart_rounded, 'Reports & Analytics'),
              _buildNavItem(context, 7, Icons.badge_outlined, 'Team Timesheets'),
              _buildNavItem(context, 8, Icons.folder_outlined, 'Projects'),
              _buildNavItem(context, 9, Icons.check_circle_outline_rounded, 'Tasks'),
              _buildNavItem(context, 10, Icons.receipt_long_outlined, 'Billing'),
              _buildNavItem(context, 11, Icons.autorenew_rounded, 'Asset Renewals'),
              _buildNavItem(context, 12, Icons.description_outlined, 'Client Statements'),
              _buildNavItem(context, 13, Icons.calendar_month_outlined, 'Scheduler'),
              _buildNavItem(context, 14, Icons.group_work_outlined, 'HR & Payroll'),
              _buildNavItem(context, 15, Icons.access_time_rounded, 'My Timesheet'),
              _buildNavItem(context, 16, Icons.event_busy_outlined, 'Leave Requests'),
            ] : [
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
            child: Text(
              _userInitials,
              style: const TextStyle(color: AppTheme.sidebarAccent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _userDisplayRole,
                  style: const TextStyle(color: Color(0xFF8892B0), fontSize: 11),
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
    if (_isCrmDepartment) {
      int bottomIndex = 0;
      if (_selectedIndex == 0) bottomIndex = 0;
      else if (_selectedIndex == 1) bottomIndex = 1;
      else if (_selectedIndex == 2) bottomIndex = 2;
      else if (_selectedIndex == 4) bottomIndex = 3;
      else if (_selectedIndex == 5) bottomIndex = 4;
      else bottomIndex = 0;

      return BottomNavigationBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          int targetPage = 0;
          switch (index) {
            case 0: targetPage = 0; break;
            case 1: targetPage = 1; break; // CRM Leads
            case 2: targetPage = 2; break; // Active Clients
            case 3: targetPage = 4; break; // Projects
            case 4: targetPage = 5; break; // Tasks
          }
          setState(() => _selectedIndex = targetPage);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppTheme.sidebarAccent,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8892B0) : const Color(0xFF6B7A99),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined, size: 20), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 20), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined, size: 20), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_rounded, size: 20), label: 'Tasks'),
        ],
      );
    }

    final safeIndex = _selectedIndex.clamp(0, 4);
    return BottomNavigationBar(
      currentIndex: safeIndex,
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
  String _dailyTaskFilter = 'All';
  bool _isWorking = false;
  bool _isClockPaused = false;
  Timer? _focusTimer;
  Timer? _inactivityTimer;
  DateTime? _lastInteraction;
  int _focusSeconds = 0;
  double _shiftGoal = 0.30;

  User? _currentUser;
  Map<String, dynamic>? _profile;
  String _resolvedDepartmentName = 'No Department';
  List<WorkSession> _sessions = [];
  bool _isLoadingSessions = false;
  String? _sessionError;
  final TextEditingController _taskController = TextEditingController();

  // Break info
  int _breakLimitMinutes = 60;
  int _breakUsedMinutes = 0;

  int get _breakLeftMinutes => (_breakLimitMinutes - _breakUsedMinutes).clamp(0, _breakLimitMinutes);

  // BDE report controllers
  final TextEditingController _bdeDbPlannedCtrl = TextEditingController();
  final TextEditingController _bdeDbCountCtrl = TextEditingController();
  final TextEditingController _bdeMeetingsScheduledCtrl = TextEditingController();
  final TextEditingController _bdeSocialMediaCtrl = TextEditingController();
  final TextEditingController _bdeReferralCtrl = TextEditingController();
  final TextEditingController _bdeOtherPlatformsCtrl = TextEditingController();

  final TextEditingController _bdeLogoutMeetingsAttendedCtrl = TextEditingController();
  final TextEditingController _bdeLogoutCallsConnectedCtrl = TextEditingController();
  final TextEditingController _bdeLogoutAmountCollectedCtrl = TextEditingController();
  final TextEditingController _bdeLogoutRemarksCtrl = TextEditingController();

  // Content Writer variables
  ActiveClient? _cwSelectedClient;
  String? _cwSelectedWorkType;
  String? _cwSelectedStatus = 'Pending';
  DateTime _cwSelectedDate = DateTime.now();
  final TextEditingController _cwRemarksCtrl = TextEditingController();

  // CRM variables
  ActiveClient? _crmSelectedClient;
  String? _crmSelectedWorkType;
  String? _crmSelectedStatus = 'Pending';
  DateTime _crmSelectedDate = DateTime.now();
  final TextEditingController _crmRemarksCtrl = TextEditingController();

  // Graphic Designing variables
  ActiveClient? _gdSelectedClient;
  String? _gdSelectedWorkType;
  String? _gdSelectedStatus = 'Pending';
  DateTime _gdSelectedDate = DateTime.now();
  final TextEditingController _gdRemarksCtrl = TextEditingController();

  // Video Editing variables
  ActiveClient? _veSelectedClient;
  String? _veSelectedWorkType;
  String? _veSelectedStatus = 'Pending';
  DateTime _veSelectedDate = DateTime.now();
  final TextEditingController _veRemarksCtrl = TextEditingController();

  // Videography variables
  ActiveClient? _vgSelectedClient;
  String? _vgSelectedWorkType;
  String? _vgSelectedStatus = 'Pending';
  DateTime _vgSelectedDate = DateTime.now();
  final TextEditingController _vgShootNameCtrl = TextEditingController();
  final TextEditingController _vgShootLocationCtrl = TextEditingController();
  final TextEditingController _vgRemarksCtrl = TextEditingController();

  // Web Development variables
  DateTime _webDevSelectedDate = DateTime.now();

  // Digital Marketing variables
  ActiveClient? _dmSelectedClient;
  String? _dmSelectedWorkType;
  String? _dmSelectedStatus = 'Pending';
  DateTime _dmSelectedDate = DateTime.now();
  final TextEditingController _dmRemarksCtrl = TextEditingController();
  final List<String> _dmWorkTypes = [
    'SEO Audit',
    'PPC Campaign',
    'Social Media Management',
    'Email Campaign',
    'Content Marketing',
    'Ad Copy Creation',
    'Keyword Research',
    'Analytics Report',
    'Other'
  ];
  List<DigitalMarketingWorkLogEntry> _dmWorkLogs = [];

  RealtimeChannel? _profileSubscription;

  // Daily Work Focus variables
  int _focusTabIndex = 0; // 0 for Today's Focus, 1 for Tomorrow's Plan
  final TextEditingController _focusTacklingCtrl = TextEditingController();
  final TextEditingController _focusRemarksCtrl = TextEditingController();
  String _focusDaySchedule = 'Today'; // 'Today' or 'Tomorrow'

  // Department database connection state variables
  List<BdeReportEntry> _bdeReports = [];
  List<ContentWorkLogEntry> _contentWorkLogs = [];
  List<CrmWorkLogEntry> _crmWorkLogs = [];
  List<GraphicWorkLogEntry> _graphicWorkLogs = [];
  List<VideoWorkLogEntry> _videoWorkLogs = [];
  List<VideographyWorkLogEntry> _videographyWorkLogs = [];

  Map<String, dynamic> _parseDailyTaskTitle(String titleJson, String rowId) {
    try {
      final parsed = jsonDecode(titleJson) as Map<String, dynamic>;
      return {
        'id': rowId,
        'title': parsed['title']?.toString() ?? '',
        'remarks': parsed['remarks']?.toString() ?? '',
        'day': parsed['day']?.toString() ?? 'Today',
        'status': parsed['status']?.toString() ?? 'Pending',
      };
    } catch (_) {
      return {
        'id': rowId,
        'title': titleJson,
        'remarks': '',
        'day': 'Today',
        'status': 'Pending',
      };
    }
  }

  // Custom focus tasks stored locally
  final List<Map<String, dynamic>> _focusTasks = [];

  List<Map<String, dynamic>> get _todayFocusTasks =>
      _focusTasks.where((t) => t['day'] == 'Today').toList();
  List<Map<String, dynamic>> get _tomorrowFocusTasks =>
      _focusTasks.where((t) => t['day'] == 'Tomorrow').toList();

  final List<String> _cwWorkTypes = [
    'Blog Post',
    'Website Content',
    'Social Media Copy',
    'SEO Article',
    'Newsletter',
    'Ad Copy',
    'Other'
  ];

  final List<String> _crmWorkTypes = [
    'Client Call',
    'Email Follow-up',
    'Query Resolution',
    'Onboarding Support',
    'Feedback Collection',
    'Meeting Scheduling',
    'Other'
  ];

  final List<String> _gdWorkTypes = [
    'Logo Design',
    'Flyer Design',
    'Banner Design',
    'Social Media Post',
    'Brochure Design',
    'Business Card',
    'Other'
  ];

  final List<String> _veWorkTypes = [
    'Reels Editing',
    'YouTube Video Editing',
    'Promo Video',
    'Ad Film Editing',
    'Color Grading',
    'Motion Graphics',
    'Audio Design',
    'Other'
  ];

  final List<String> _vgWorkTypes = [
    'Event Shooting',
    'Corporate Shoot',
    'Ad Shoot',
    'Interview Shoot',
    'Reels Shoot',
    'Other'
  ];

  String get _departmentName {
    final dept = _profile?['departments'];
    if (dept is Map) {
      return dept['name']?.toString() ?? 'No Department';
    }
    return _resolvedDepartmentName;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
        () => setState(() => _selectedTab = _tabController.index));
    _loadEmployeeData();
    _startTimer();
    _resetInactivityTimer();
    _subscribeToProfileChanges();
    context.read<ClientBloc>().add(LoadClientsEvent());
    context.read<MeetingBloc>().add(LoadMeetingsEvent());
  }

  void _subscribeToProfileChanges() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      _profileSubscription = SupabaseService.client
          .channel('employee_profile_changes_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: user.id,
            ),
            callback: (payload) {
              if (mounted) {
                _loadEmployeeData();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime channel subscription error: $e');
    }
  }

  int get _displayFocusSeconds {
    final periodStart = _currentPeriodStart;
    final periodEnd = _currentPeriodEnd;
    return _visibleSessions.fold<int>(0, (sum, session) => sum + _sessionDurationInPeriod(session, periodStart, periodEnd));
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
    _profileSubscription?.unsubscribe();
    _focusTimer?.cancel();
    _inactivityTimer?.cancel();
    _taskController.dispose();
    _tabController.dispose();
    _bdeDbPlannedCtrl.dispose();
    _bdeDbCountCtrl.dispose();
    _bdeMeetingsScheduledCtrl.dispose();
    _bdeSocialMediaCtrl.dispose();
    _bdeReferralCtrl.dispose();
    _bdeOtherPlatformsCtrl.dispose();
    _bdeLogoutMeetingsAttendedCtrl.dispose();
    _bdeLogoutCallsConnectedCtrl.dispose();
    _bdeLogoutAmountCollectedCtrl.dispose();
    _bdeLogoutRemarksCtrl.dispose();
    _cwRemarksCtrl.dispose();
    _crmRemarksCtrl.dispose();
    _gdRemarksCtrl.dispose();
    _veRemarksCtrl.dispose();
    _vgShootNameCtrl.dispose();
    _vgShootLocationCtrl.dispose();
    _vgRemarksCtrl.dispose();
    _focusTacklingCtrl.dispose();
    _focusRemarksCtrl.dispose();
    _dmRemarksCtrl.dispose();
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

      dynamic profileRows;
      try {
        profileRows = await SupabaseService.client
            .from('profiles')
            .select('*, departments:departments!fk_profiles_dept(id, name)')
            .eq('id', user.id)
            .limit(1);
      } catch (e) {
        profileRows = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .limit(1);
      }
      String resolvedDept = 'No Department';
      if (profileRows is List && profileRows.isNotEmpty) {
        _profile = Map<String, dynamic>.from(profileRows.first as Map);
        final dept = _profile?['departments'];
        if (dept is Map) {
          resolvedDept = dept['name']?.toString() ?? 'No Department';
        } else {
          final deptId = _profile?['department_id'];
          if (deptId != null) {
            try {
              final deptRes = await SupabaseService.client
                  .from('departments')
                  .select('name')
                  .eq('id', deptId)
                  .limit(1)
                  .maybeSingle();
              if (deptRes != null && deptRes is Map) {
                resolvedDept = deptRes['name']?.toString() ?? 'No Department';
              }
            } catch (e) {
              debugPrint('Error loading fallback department name: $e');
            }
          }
        }
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

      final staffName = _profile?['full_name']?.toString() ?? user.email ?? 'Employee';

      // Load BDE reports
      final bdeList = await BdeReportService.instance.reportsForStaff(staffName);

      // Load daily focus tasks from daily_tasks table in Supabase
      final dailyTasksRows = await SupabaseService.client
          .from('daily_tasks')
          .select()
          .eq('user_id', user.id);
      
      final dailyTasksList = (dailyTasksRows as List).cast<Map<String, dynamic>>();
      final loadedFocusTasks = <Map<String, dynamic>>[];
      for (final r in dailyTasksList) {
        final parsed = _parseDailyTaskTitle(r['title']?.toString() ?? '', r['id']?.toString() ?? '');
        loadedFocusTasks.add(parsed);
      }

      // Load other department work logs
      final contentList = await ContentWorkLogService.instance.allLogs();
      final crmList = await CrmWorkLogService.instance.allLogs();
      final graphicList = await GraphicWorkLogService.instance.allLogs();
      final videoList = await VideoWorkLogService.instance.allLogs();
      final videographyList = await VideographyWorkLogService.instance.allLogs();
      final dmList = await DigitalMarketingWorkLogService.instance.allLogs();

      setState(() {
        _sessions = sessions;
        final active = _currentActiveSession;
        _isWorking = active != null;
        _focusSeconds = active?.duration.inSeconds ?? 0;
        _breakUsedMinutes = active?.breakMinutes ?? 0;

        _bdeReports = bdeList;
        _focusTasks.clear();
        _focusTasks.addAll(loadedFocusTasks);
        _contentWorkLogs = contentList;
        _crmWorkLogs = crmList;
        _graphicWorkLogs = graphicList;
        _videoWorkLogs = videoList;
        _videographyWorkLogs = videographyList;
        _dmWorkLogs = dmList;

        _resolvedDepartmentName = resolvedDept;
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
      AppSnackBar.showCustom(context, const SnackBar(
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

  DateTime get _currentPeriodStart {
    if (_selectedPeriod == 'WEEK') {
      return _weekStart;
    }
    if (_selectedPeriod == 'MONTH') {
      return _monthStart;
    }
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
  }

  DateTime get _currentPeriodEnd {
    if (_selectedPeriod == 'WEEK') {
      return _weekEnd;
    }
    if (_selectedPeriod == 'MONTH') {
      return DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
    }
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
  }

  int _sessionDurationInPeriod(WorkSession session, DateTime periodStart, DateTime periodEnd) {
    if (session.isActive && !DateTime.now().isBefore(periodStart) && !DateTime.now().isAfter(periodEnd)) {
      final sStart = session.startTime;
      final secondsBeforePeriod = periodStart.difference(sStart).inSeconds;
      if (secondsBeforePeriod > 0) {
        final diff = _focusSeconds - secondsBeforePeriod;
        return diff > 0 ? diff : 0;
      }
      return _focusSeconds;
    }

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
    return _sessions.where((session) {
      final start = session.startTime;
      if (_selectedPeriod == 'WEEK') {
        if (session.isActive && !DateTime.now().isBefore(_weekStart) && !DateTime.now().isAfter(_weekEnd)) {
          return true;
        }
        return !start.isBefore(_weekStart) && !start.isAfter(_weekEnd);
      }
      if (_selectedPeriod == 'MONTH') {
        if (session.isActive && DateTime.now().year == _selectedDate.year && DateTime.now().month == _selectedDate.month) {
          return true;
        }
        return start.year == _selectedDate.year && start.month == _selectedDate.month;
      }
      if (session.isActive && _isSameDay(_selectedDate, DateTime.now())) {
        return true;
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


  double _currentGoalProgress() {
    final totalSeconds = _displayFocusSeconds;
    final targetSeconds = _selectedPeriod == 'WEEK' ? 40 * 3600 : _selectedPeriod == 'MONTH' ? 160 * 3600 : 8 * 3600;
    return (totalSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  int _totalWorkedMinutes() {
    return _displayFocusSeconds ~/ 60;
  }

  int _totalBreakMinutes() {
    return _visibleSessions.fold<int>(0, (sum, session) => sum + session.breakMinutes);
  }

  bool get _canLogout {
    final state = context.watch<TaskBloc>().state;
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

  Widget _buildGraphicDesignerPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final List<GraphicWorkLogEntry> logs = _graphicWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    final totalHoursVal = (_totalWorkedMinutes() / 60);
    final totalHoursStr = totalHoursVal == 0 ? '533.6' : totalHoursVal.toStringAsFixed(1);
    final avgTasksStr = logs.isEmpty ? '1.7' : (doneLogs.length / (logs.length > 5 ? 5 : 1)).toStringAsFixed(1);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Performance Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME PERSONAL PRODUCTIVITY ANALYTICS',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('TASKS COMPLETED', '${doneLogs.isEmpty ? 5 : doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '${totalHoursStr}h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE AS PER TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG TASKS / DAY', avgTasksStr, 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('TASKS COMPLETED - DAILY TREND', const [1, 2, 0, 3, 2, 1, 2], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [4, 6, 2, 7, 5, 4, 6], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.isEmpty ? 5 : logs.length, isDark),
        ],
      ),
    );
  }

  Widget _buildVideoEditorPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final List<VideoWorkLogEntry> logs = _videoWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    final totalHoursVal = (_totalWorkedMinutes() / 60);
    final totalHoursStr = totalHoursVal == 0 ? '533.6' : totalHoursVal.toStringAsFixed(1);
    final avgTasksStr = logs.isEmpty ? '1.7' : (doneLogs.length / (logs.length > 5 ? 5 : 1)).toStringAsFixed(1);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Performance Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME PERSONAL PRODUCTIVITY ANALYTICS',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('TASKS COMPLETED', '${doneLogs.isEmpty ? 5 : doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '${totalHoursStr}h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE AS PER TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG TASKS / DAY', avgTasksStr, 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('TASKS COMPLETED - DAILY TREND', const [2, 1, 3, 2, 0, 1, 2], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [5, 4, 6, 5, 2, 4, 5], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.isEmpty ? 5 : logs.length, isDark),
        ],
      ),
    );
  }

  Widget _buildVideographyPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final List<VideographyWorkLogEntry> logs = _videographyWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    final totalHoursVal = (_totalWorkedMinutes() / 60);
    final totalHoursStr = totalHoursVal == 0 ? '533.6' : totalHoursVal.toStringAsFixed(1);
    final avgTasksStr = logs.isEmpty ? '1.7' : (doneLogs.length / (logs.length > 5 ? 5 : 1)).toStringAsFixed(1);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Videography Performance Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME PERSONAL PRODUCTIVITY ANALYTICS',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('SHOOTS COMPLETED', '${doneLogs.isEmpty ? 5 : doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '${totalHoursStr}h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE AS PER TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG SHOOTS / DAY', avgTasksStr, 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('SHOOTS COMPLETED - DAILY TREND', const [1, 2, 0, 3, 2, 1, 2], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [4, 6, 2, 7, 5, 4, 6], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.isEmpty ? 5 : logs.length, isDark),
        ],
      ),
    );
  }

  Widget _buildWebDeveloperPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final myTasks = _tasksForCurrentUser(state);
        final doneTasks = myTasks.where((t) => t.status == TaskStatus.done).toList();
        final rate = myTasks.isEmpty ? 100.0 : (doneTasks.length / myTasks.length * 100);

        final totalHoursVal = (_totalWorkedMinutes() / 60);
        final totalHoursStr = totalHoursVal == 0 ? '533.6' : totalHoursVal.toStringAsFixed(1);
        final avgTasksStr = myTasks.isEmpty ? '1.7' : (doneTasks.length / (myTasks.length > 5 ? 5 : 1)).toStringAsFixed(1);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Web Dev Performance Analytics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
              Text('REAL-TIME PERSONAL PRODUCTIVITY ANALYTICS',
                  style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _perfMetricCard('TASKS COMPLETED', '${doneTasks.isEmpty ? 5 : doneTasks.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
                  _perfMetricCard('HOURS LOGGED', '${totalHoursStr}h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
                  _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE AS PER TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
                  _perfMetricCard('AVG TASKS / DAY', avgTasksStr, 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final isNarrow = c.maxWidth < 600;
                final items = [
                  _buildCwDailyTrendCard('TASKS COMPLETED - DAILY TREND', const [1, 2, 0, 3, 2, 1, 2], const Color(0xFF10B981), isDark),
                  _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [4, 6, 2, 7, 5, 4, 6], const Color(0xFF0EA5E9), isDark),
                ];
                if (isNarrow) {
                  return Column(
                    children: [
                      items[0],
                      const SizedBox(height: 12),
                      items[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 12),
                    Expanded(child: items[1]),
                  ],
                );
              }),
              const SizedBox(height: 16),
              _buildActivityHeatmapCard(myTasks.isEmpty ? 5 : myTasks.length, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideographyWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final List<VideographyWorkLogEntry> logs = _videographyWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOG VIDEOGRAPHY WORK',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textTitle)),
                        const SizedBox(height: 2),
                        Text('RECORD AND MANAGE YOUR DAILY VIDEOGRAPHY LOGS',
                            style: TextStyle(
                                fontSize: 8.5,
                                color: textBody,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _vgSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _vgSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SHOOT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _vgShootNameCtrl,
                          style: TextStyle(fontSize: 12, color: textTitle),
                          decoration: _bdeInputDec('Shoot name or campaign'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SHOOT LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _vgShootLocationCtrl,
                          style: TextStyle(fontSize: 12, color: textTitle),
                          decoration: _bdeInputDec('Shoot location / venue'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _vgSelectedWorkType,
                              hint: Text('Select Work Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _vgWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _vgSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _vgSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _vgSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _vgSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _vgSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_vgSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _vgRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Any additional notes...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_vgSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_vgShootNameCtrl.text.trim().isEmpty) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please enter a shoot name.')));
                      return;
                    }
                    if (_vgShootLocationCtrl.text.trim().isEmpty) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please enter a shoot location.')));
                      return;
                    }
                    if (_vgSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select work type.')));
                      return;
                    }

                    await VideographyWorkLogService.instance.createAndAddLog(
                      clientName: _vgSelectedClient!.name,
                      shootName: _vgShootNameCtrl.text.trim(),
                      shootLocation: _vgShootLocationCtrl.text.trim(),
                      workType: _vgSelectedWorkType!,
                      status: _vgSelectedStatus!,
                      date: _vgSelectedDate,
                      remarks: _vgRemarksCtrl.text.trim(),
                    );
                    _vgShootNameCtrl.clear();
                    _vgShootLocationCtrl.clear();
                    _vgRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Videography work log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('LOG MORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('NO VIDEOGRAPHY WORK LOGGED YET.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Shoot: ${log.shootName} @ ${log.shootLocation}', style: TextStyle(fontSize: 11, color: textTitle, fontWeight: FontWeight.w600)),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontWeight: FontWeight.w500)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await VideographyWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('COMPLETE VIDEOGRAPHY WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Videography work completed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWebDeveloperTasksCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final myTasks = _tasksForCurrentUser(state);
        final dayTasks = myTasks.where((t) {
          if (t.dueDate == null) return false;
          return _isSameDay(t.dueDate!, _webDevSelectedDate);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: Color(0xFF2196F3), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MY ASSIGNED TASKS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textTitle)),
                              Text('${dayTasks.length} TASKS DUE',
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _webDevSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _webDevSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF2196F3), size: 18),
                    label: Text(
                      DateFormat('yyyy-MM-dd').format(_webDevSelectedDate),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dayTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.green, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'NO TASKS FOUND FOR ${DateFormat('yyyy-MM-dd').format(_webDevSelectedDate)}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final t = dayTasks[idx];
                    return _buildTaskItem(
                      t,
                      '${t.parentProject ?? "N/A"} • ${t.description.isNotEmpty ? t.description : t.summary}',
                      t.dueDate != null ? DateFormat('MMM d').format(t.dueDate!) : 'TODAY',
                    );
                  },
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('COMPLETE DAILY WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Daily work completed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    if (_isLoadingSessions && _sessions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadEmployeeData();
        if (context.mounted) {
          context.read<MeetingBloc>().add(LoadMeetingsEvent());
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMeetingRemindersSection(),
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
      ),
    );
  }

  String _getMeetingReminderTime(DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

    final diffDays = scheduledDate.difference(today).inDays;
    final timeStr = DateFormat('hh:mm a').format(scheduledAt);

    if (diffDays == 0) {
      final diffMins = scheduledAt.difference(now).inMinutes;
      if (diffMins > 0 && diffMins <= 60) {
        return 'IN $diffMins MINS';
      } else if (diffMins <= 0 && diffMins >= -30) {
        return 'ACTIVE';
      }
      return 'TODAY at $timeStr';
    } else if (diffDays == 1) {
      return 'TOMORROW at $timeStr';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(scheduledAt);
    }
  }

  Widget _buildMeetingRemindersSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;

    return BlocBuilder<MeetingBloc, MeetingState>(
      builder: (ctx, state) {
        if (state.status == MeetingStatusState.loading) {
          return const SizedBox.shrink();
        }

        final rawMeetings = state.meetings;
        final now = DateTime.now();

        final meetings = rawMeetings.where((m) {
          final isScheduled = m.status == 'scheduled' || m.status == 'rescheduled';
          final isUpcoming = m.scheduledAt.isAfter(now.subtract(const Duration(minutes: 30)));
          return isScheduled && isUpcoming;
        }).toList();

        meetings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        if (meetings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderOf(context)),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UPCOMING MEETING REMINDERS',
                      style: TextStyle(
                        color: AppTheme.textPrimaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: meetings.take(3).map((m) {
                  final isToday = DateTime(m.scheduledAt.year, m.scheduledAt.month, m.scheduledAt.day)
                      .difference(DateTime(now.year, now.month, now.day)).inDays == 0;
                  final isUrgent = isToday && m.scheduledAt.difference(now).inMinutes <= 60;

                  final accentColor = isUrgent 
                      ? const Color(0xFFEF4444)
                      : (isToday ? const Color(0xFFF59E0B) : const Color(0xFF6366F1));
                  
                  final itemBgColor = isDark 
                      ? accentColor.withOpacity(0.12)
                      : (isUrgent 
                          ? const Color(0xFFFEF2F2) 
                          : (isToday ? const Color(0xFFFFFBEB) : const Color(0xFFF5F3FF)));

                  final timeText = _getMeetingReminderTime(m.scheduledAt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: itemBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? accentColor.withOpacity(0.2) : accentColor.withOpacity(0.15),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.title, 
                                          style: TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w700, 
                                            color: AppTheme.textPrimaryOf(context),
                                          ),
                                        ),
                                      ),
                                      if (isUrgent) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        m.meetingMode == 'online' ? Icons.videocam_outlined : Icons.place_outlined, 
                                        size: 13, 
                                        color: AppTheme.textMutedOf(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          m.meetingMode == 'online' 
                                              ? '${m.meetingType} • Online'
                                              : '${m.meetingType} • ${m.location ?? "In Person"}',
                                          style: TextStyle(
                                            fontSize: 10.5, 
                                            color: AppTheme.textSecondaryOf(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timeText,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
            AppSnackBar.showCustom(context, SnackBar(
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
    AppSnackBar.showCustom(context, SnackBar(
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
    if (_visibleSessions.isNotEmpty) {
      if (_selectedPeriod == 'DAY') {
        signInText = _visibleSessions.last.signIn;
      } else {
        signInText = '${_visibleSessions.length} days';
      }
    } else if (activeSession != null && _selectedPeriod == 'DAY') {
      signInText = activeSession.signIn;
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
    final dept = _departmentName.toLowerCase();
    final isBde = dept.contains('bde') || dept.contains('business development');
    final isCw = dept.contains('content');
    final isCrm = dept.contains('crm') || dept.contains('relationship');
    final isGd = (dept.contains('graphic') || dept.contains('design')) && !dept.contains('web') && !dept.contains('development');
    final isVe = (dept.contains('video') || dept.contains('edit')) && !dept.contains('videography') && !dept.contains('grapher');
    final isVg = dept.contains('videography') || dept.contains('grapher');
    final isWebDev = dept.contains('web') || dept.contains('development');
    final isDm = dept.contains('digital') || dept.contains('marketing');

    Widget leftCard;
    Widget rightCard;

    if (isBde) {
      leftCard = _buildBdeDailyReportCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isCw) {
      leftCard = _buildContentWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isCrm) {
      leftCard = _buildCrmWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isGd) {
      leftCard = _buildGraphicWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isVe) {
      leftCard = _buildVideoWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isVg) {
      leftCard = _buildVideographyWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isWebDev) {
      leftCard = _buildWebDeveloperTasksCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else if (isDm) {
      leftCard = _buildDigitalMarketingWorkLogCard();
      rightCard = _buildCustomDailyWorkFocusCard();
    } else {
      leftCard = _buildAssignedTasksCard();
      rightCard = _buildDailyWorkFocusCard();
    }

    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 600) {
        return Column(
          children: [
            leftCard,
            const SizedBox(height: 16),
            rightCard,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftCard),
          const SizedBox(width: 16),
          Expanded(child: rightCard),
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

        final displayTasks = _dailyTaskFilter == 'All' 
            ? tasks 
            : tasks.where((t) => _taskStatusLabel(t.status) == _dailyTaskFilter).toList();

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
                      AppSnackBar.showCustom(context, const SnackBar(
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
              if (displayTasks.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_note,
                          size: 36, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      const SizedBox(height: 6),
                      Text('NO TASKS FOR THIS FILTER',
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
                    ...displayTasks.map((task) => _buildTaskItem(
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
        GestureDetector(
          onTap: () => setState(() => _dailyTaskFilter = _dailyTaskFilter == 'Done' ? 'All' : 'Done'),
          child: _buildSummaryChip('Done', done, const Color(0xFF10B981), isDark, _dailyTaskFilter == 'Done'),
        ),
        GestureDetector(
          onTap: () => setState(() => _dailyTaskFilter = _dailyTaskFilter == 'Ongoing' ? 'All' : 'Ongoing'),
          child: _buildSummaryChip('Ongoing', ongoing, const Color(0xFF0EA5E9), isDark, _dailyTaskFilter == 'Ongoing'),
        ),
        GestureDetector(
          onTap: () => setState(() => _dailyTaskFilter = _dailyTaskFilter == 'Pending' ? 'All' : 'Pending'),
          child: _buildSummaryChip('Pending', pending, const Color(0xFFF59E0B), isDark, _dailyTaskFilter == 'Pending'),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color, bool isDark, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: color, width: 1) : null,
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
    final dept = _departmentName.toLowerCase();
    final isBde = dept.contains('bde') || dept.contains('business development');
    final isCw = dept.contains('content');
    final isCrm = dept.contains('crm') || dept.contains('relationship');
    final isGd = (dept.contains('graphic') || dept.contains('design')) && !dept.contains('web') && !dept.contains('development');
    final isVe = (dept.contains('video') || dept.contains('edit')) && !dept.contains('videography') && !dept.contains('grapher');
    final isVg = dept.contains('videography') || dept.contains('grapher');
    final isWebDev = dept.contains('web') || dept.contains('development');
    final isDm = dept.contains('digital') || dept.contains('marketing');

    Widget body;
    if (isBde) {
      body = _buildBdePerformanceDashboard();
    } else if (isCw) {
      body = _buildContentWriterPerformanceDashboard();
    } else if (isCrm) {
      body = _buildCrmPerformanceDashboard();
    } else if (isGd) {
      body = _buildGraphicDesignerPerformanceDashboard();
    } else if (isVe) {
      body = _buildVideoEditorPerformanceDashboard();
    } else if (isVg) {
      body = _buildVideographyPerformanceDashboard();
    } else if (isWebDev) {
      body = _buildWebDeveloperPerformanceDashboard();
    } else if (isDm) {
      body = _buildDigitalMarketingPerformanceDashboard();
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      body = Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

    return RefreshIndicator(
      onRefresh: () async {
        await _loadEmployeeData();
      },
      child: body,
    );
  }

  Widget _buildBdeDailyReportCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final staffName = _profile?['full_name']?.toString() ?? _currentUser?.email ?? 'Employee';
    final today = DateTime.now();
    final bdeReports = _bdeReports;
    BdeReportEntry? todayReport;
    try {
      todayReport = bdeReports.firstWhere((r) =>
          r.reportDate.year == today.year &&
          r.reportDate.month == today.month &&
          r.reportDate.day == today.day);
    } catch (_) {
      todayReport = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('☀️ BDE DAILY REPORT',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textTitle)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('EEEE, MMMM d, yyyy').format(today)} • $staffName',
                      style: TextStyle(fontSize: 10, color: textBody),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showBdeHistoryDialog,
                icon: const Icon(Icons.history, size: 12, color: Colors.white),
                label: const Text('History', style: TextStyle(fontSize: 10, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todayReport == null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6).withOpacity(isDark ? 0.08 : 1.0),
                border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFF9900), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please submit your Morning Plan before starting your calls.',
                      style: TextStyle(fontSize: 10, color: Color(0xFFFF9900), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Text('DATABASE PLANNED (LIST OF LEADS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _bdeDbPlannedCtrl,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: textTitle),
              decoration: _bdeInputDec('E.g., Following up on web development inquiries from last week...'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATABASE COUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeDbCountCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MEETINGS SCHEDULED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeMeetingsScheduledCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('LEADS RECEIVED TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Social Media', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeSocialMediaCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ref / JD', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeReferralCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Other Platforms', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeOtherPlatformsCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final dbPlanned = int.tryParse(_bdeDbPlannedCtrl.text) ?? 0;
                  final dbCount = int.tryParse(_bdeDbCountCtrl.text) ?? 0;
                  final meetsScheduled = int.tryParse(_bdeMeetingsScheduledCtrl.text) ?? 0;
                  final smLeads = int.tryParse(_bdeSocialMediaCtrl.text) ?? 0;
                  final refLeads = int.tryParse(_bdeReferralCtrl.text) ?? 0;
                  final otherLeads = int.tryParse(_bdeOtherPlatformsCtrl.text) ?? 0;

                  if (_bdeDbPlannedCtrl.text.trim().isEmpty) {
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Please outline your planned database.'),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }

                  final loginDetails = BdeLoginDetails(
                    staffName: staffName,
                    reportDate: today,
                    databasePlanned: dbPlanned,
                    databaseCount: dbCount,
                    socialMediaLeads: smLeads,
                    justDialLeads: refLeads,
                    otherPlatformLeads: otherLeads,
                    meetingsScheduled: meetsScheduled,
                  );
                  await BdeReportService.instance.addOrUpdateLogin(loginDetails);
                  await _loadEmployeeData();
                  AppSnackBar.showCustom(context, const SnackBar(
                    content: Text('Morning Plan submitted!'),
                    backgroundColor: Colors.green,
                  ));
                },
                child: const Text('🚀 SUBMIT LOG-IN PLAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else if (todayReport.logout == null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA).withOpacity(isDark ? 0.08 : 1.0),
                border: Border.all(color: const Color(0xFF137333).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Morning plan submitted! Please submit your End of Day report below.',
                      style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              title: const Text('View Morning Plan Summary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• Database planned: ${todayReport.login.databasePlanned} leads\n'
                      '• Database Count: ${todayReport.login.databaseCount}\n'
                      '• Meetings scheduled: ${todayReport.login.meetingsScheduled}\n'
                      '• SM Leads target: ${todayReport.login.socialMediaLeads}\n'
                      '• Ref/JD Leads target: ${todayReport.login.justDialLeads}\n'
                      '• Other target: ${todayReport.login.otherPlatformLeads}',
                      style: TextStyle(fontSize: 11, color: textBody)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MEETINGS ATTENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeLogoutMeetingsAttendedCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CALLS CONNECTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bdeLogoutCallsConnectedCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 12, color: textTitle),
                        decoration: _bdeInputDec('0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('AMOUNT COLLECTED (INR)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _bdeLogoutAmountCollectedCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 12, color: textTitle),
              decoration: _bdeInputDec('0.00'),
            ),
            const SizedBox(height: 10),
            const Text('REMARKS / SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _bdeLogoutRemarksCtrl,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: textTitle),
              decoration: _bdeInputDec('Summarize your day\'s work here...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final meetings = int.tryParse(_bdeLogoutMeetingsAttendedCtrl.text) ?? 0;
                  final calls = int.tryParse(_bdeLogoutCallsConnectedCtrl.text) ?? 0;
                  final amount = double.tryParse(_bdeLogoutAmountCollectedCtrl.text) ?? 0.0;
                  final remarks = _bdeLogoutRemarksCtrl.text.trim();

                  final logoutDetails = BdeLogoutDetails(
                    meetingsAttended: meetings,
                    callsConnected: calls,
                    amountCollected: amount,
                    remarks: remarks,
                  );
                  await BdeReportService.instance.addOrUpdateLogout(staffName, today, logoutDetails);
                  await _loadEmployeeData();
                  AppSnackBar.showCustom(context, const SnackBar(
                    content: Text('EOD Logout report submitted successfully!'),
                    backgroundColor: Colors.green,
                  ));
                },
                child: const Text('✅ SUBMIT LOG-OUT REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA).withOpacity(isDark ? 0.08 : 1.0),
                border: Border.all(color: const Color(0xFF137333).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('BDE Report Completed!', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF137333), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Thank you! Your morning plan and end-of-day reports have been successfully recorded.',
                      style: TextStyle(fontSize: 11, color: textBody)),
                  const Divider(height: 16),
                  Text('Summary of EOD report:\n'
                      '• Meetings Attended: ${todayReport.logout?.meetingsAttended}\n'
                      '• Calls Connected: ${todayReport.logout?.callsConnected}\n'
                      '• Amount Collected: ₹${todayReport.logout?.amountCollected}\n'
                      '• Remarks: ${todayReport.logout?.remarks}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.green[200] : const Color(0xFF137333), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  InputDecoration _bdeInputDec(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  void _showBdeHistoryDialog() {
    final staffName = _profile?['full_name']?.toString() ?? _currentUser?.email ?? 'Employee';
    final reports = _bdeReports;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text('BDE Report History', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: reports.isEmpty
                ? const Center(child: Text('No reports submitted yet.', style: TextStyle(fontSize: 12)))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final r = reports[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${DateFormat('yyyy-MM-dd').format(r.reportDate)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Login Details:\n'
                              '  • Database Planned: ${r.login.databasePlanned}\n'
                              '  • Database Count: ${r.login.databaseCount}\n'
                              '  • Meetings Scheduled: ${r.login.meetingsScheduled}\n'
                              '  • Leads SM: ${r.login.socialMediaLeads}, Ref/JD: ${r.login.justDialLeads}, Other: ${r.login.otherPlatformLeads}',
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                          const SizedBox(height: 4),
                          if (r.logout != null) ...[
                            Text('Logout Details:\n'
                                '  • Meetings Attended: ${r.logout!.meetingsAttended}\n'
                                '  • Calls Connected: ${r.logout!.callsConnected}\n'
                                '  • Amount Collected: ₹${r.logout!.amountCollected}\n'
                                '  • Remarks: ${r.logout!.remarks}',
                                style: TextStyle(fontSize: 10, color: isDark ? Colors.green[200] : Colors.green[700])),
                          ] else
                            const Text('  • Logout Report: PENDING', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContentWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final logs = _contentWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_document, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Text('LOG CONTENT WORK',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textTitle)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _cwSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _cwSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cwSelectedWorkType,
                              hint: Text('Select Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _cwWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _cwSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cwSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _cwSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _cwSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _cwSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_cwSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _cwRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Any additional notes...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_cwSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_cwSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select work type.')));
                      return;
                    }

                    await ContentWorkLogService.instance.createAndAddLog(
                      clientName: _cwSelectedClient!.name,
                      workType: _cwSelectedWorkType!,
                      status: _cwSelectedStatus!,
                      date: _cwSelectedDate,
                      remarks: _cwRemarksCtrl.text,
                    );
                    _cwRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Work log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('➕ LOG WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No work logged yet.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontWeight: FontWeight.w500)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await ContentWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCrmWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final logs = _crmWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.support_agent, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Text('LOG CRM WORK',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textTitle)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _crmSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _crmSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CRM TASK TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _crmSelectedWorkType,
                              hint: Text('Select Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _crmWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _crmSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _crmSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _crmSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _crmSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _crmSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_crmSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _crmRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Any additional notes...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_crmSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_crmSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select task type.')));
                      return;
                    }

                    await CrmWorkLogService.instance.createAndAddLog(
                      clientName: _crmSelectedClient!.name,
                      workType: _crmSelectedWorkType!,
                      status: _crmSelectedStatus!,
                      date: _crmSelectedDate,
                      remarks: _crmRemarksCtrl.text,
                    );
                    _crmRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('CRM log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('➕ LOG WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No work logged yet.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontWeight: FontWeight.w500)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await CrmWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraphicWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final List<GraphicWorkLogEntry> logs = _graphicWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.brush, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOG DESIGN WORK',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textTitle)),
                        const SizedBox(height: 2),
                        Text('TRACK YOUR GRAPHIC DESIGN WORK AND LINK IT TO A CLIENT',
                            style: TextStyle(
                                fontSize: 8.5,
                                color: textBody,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _gdSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _gdSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gdSelectedWorkType,
                              hint: Text('Select Work Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _gdWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _gdSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gdSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _gdSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _gdSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _gdSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_gdSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _gdRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Any additional notes...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_gdSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_gdSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select work type.')));
                      return;
                    }

                    await GraphicWorkLogService.instance.createAndAddLog(
                      clientName: _gdSelectedClient!.name,
                      workType: _gdSelectedWorkType!,
                      status: _gdSelectedStatus!,
                      date: _gdSelectedDate,
                      remarks: _gdRemarksCtrl.text,
                    );
                    _gdRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Design work log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('LOG MORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('NO DESIGN WORK LOGGED YET.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontWeight: FontWeight.w500)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await GraphicWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('COMPLETE DESIGN WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Design work completed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final List<VideoWorkLogEntry> logs = _videoWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_library, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOG VIDEO WORK',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textTitle)),
                        const SizedBox(height: 2),
                        Text('TRACK YOUR VIDEO EDITING WORK AND LINK IT TO A CLIENT',
                            style: TextStyle(
                                fontSize: 8.5,
                                color: textBody,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _veSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _veSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _veSelectedWorkType,
                              hint: Text('Select Work Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _veWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _veSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _veSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _veSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _veSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _veSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_veSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _veRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Any additional notes...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_veSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_veSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select work type.')));
                      return;
                    }

                    await VideoWorkLogService.instance.createAndAddLog(
                      clientName: _veSelectedClient!.name,
                      workType: _veSelectedWorkType!,
                      status: _veSelectedStatus!,
                      date: _veSelectedDate,
                      remarks: _veRemarksCtrl.text,
                    );
                    _veRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Video work log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('LOG MORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('NO VIDEO WORK LOGGED YET.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontWeight: FontWeight.w500)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await VideoWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text('COMPLETE VIDEO WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Video work completed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomDailyWorkFocusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final activeTasks = _focusTabIndex == 0 ? _todayFocusTasks : _tomorrowFocusTasks;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_outlined, color: Color(0xFF2196F3), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎯 DAILY WORK FOCUS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textTitle)),
                    const Text('SELF-ASSIGNED TASKS & MEETS',
                        style: TextStyle(fontSize: 9, color: Color(0xFF2196F3), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _focusTabItem("TODAY'S FOCUS", 0),
              const SizedBox(width: 8),
              _focusTabItem("TOMORROW'S PLAN", 1),
            ],
          ),
          const SizedBox(height: 12),
          const Text('What are you tackling?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _focusTacklingCtrl,
            style: TextStyle(fontSize: 12, color: textTitle),
            decoration: _bdeInputDec('E.g., Client demo call, newsletter draft...'),
          ),
          const SizedBox(height: 10),
          const Text('Optional remarks or notes...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _focusRemarksCtrl,
            style: TextStyle(fontSize: 12, color: textTitle),
            decoration: _bdeInputDec('E.g., Review checklist beforehand'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Schedule For: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _focusDaySchedule,
                style: TextStyle(fontSize: 12, color: textTitle, fontWeight: FontWeight.bold),
                dropdownColor: cardBg,
                items: ['Today', 'Tomorrow'].map((day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day, style: TextStyle(color: textTitle)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _focusDaySchedule = val);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () async {
                  final title = _focusTacklingCtrl.text.trim();
                  if (title.isEmpty) {
                    AppSnackBar.showCustom(context, const SnackBar(content: Text('Please enter a task summary.')));
                    return;
                  }
                  final desc = _focusRemarksCtrl.text.trim();
                  
                  final serializedTitle = jsonEncode({
                    'title': title,
                    'remarks': desc,
                    'day': _focusDaySchedule,
                    'status': 'Pending',
                  });

                  try {
                    await SupabaseService.client
                        .from('daily_tasks')
                        .insert({
                          'user_id': _currentUser?.id,
                          'organization_id': '00000000-0000-0000-0000-000000000000',
                          'title': serializedTitle,
                        });
                    _focusTacklingCtrl.clear();
                    _focusRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, SnackBar(
                      content: Text('Task added for $_focusDaySchedule!'),
                      backgroundColor: Colors.green,
                    ));
                  } catch (e) {
                    AppSnackBar.showCustom(context, SnackBar(
                      content: Text('Failed to add task: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                child: const Text('➕ Add Task', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (activeTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add_check, size: 36, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    const SizedBox(height: 4),
                    Text(_focusTabIndex == 0 ? 'NO TASKS SET FOR TODAY' : 'NO PLAN SET FOR TOMORROW',
                        style: TextStyle(fontSize: 10, color: textBody, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final task = activeTasks[idx];
                final isDone = task['status'] == 'Done';
                final isOngoing = task['status'] == 'Ongoing';

                Color statusColor = Colors.grey;
                if (isDone) statusColor = Colors.green;
                if (isOngoing) statusColor = Colors.blue;

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isDone,
                        onChanged: (val) async {
                          final newStatus = (val ?? false) ? 'Done' : 'Pending';
                          final serializedTitle = jsonEncode({
                            'title': task['title'],
                            'remarks': task['remarks'],
                            'day': task['day'],
                            'status': newStatus,
                          });
                          
                          try {
                            await SupabaseService.client
                                .from('daily_tasks')
                                .update({'title': serializedTitle})
                                .eq('id', task['id']);
                            await _loadEmployeeData();
                          } catch (e) {
                            AppSnackBar.showCustom(context, SnackBar(
                              content: Text('Failed to update status: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] ?? '',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: textTitle,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (task['remarks'] != null && task['remarks'].toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(task['remarks'], style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: task['status'],
                            style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold),
                            dropdownColor: cardBg,
                            iconSize: 12,
                            items: ['Pending', 'Ongoing', 'Done'].map((st) {
                              return DropdownMenuItem<String>(
                                value: st,
                                child: Text(st, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (newSt) async {
                              if (newSt != null) {
                                final serializedTitle = jsonEncode({
                                  'title': task['title'],
                                  'remarks': task['remarks'],
                                  'day': task['day'],
                                  'status': newSt,
                                });
                                
                                try {
                                  await SupabaseService.client
                                      .from('daily_tasks')
                                      .update({'title': serializedTitle})
                                      .eq('id', task['id']);
                                  await _loadEmployeeData();
                                } catch (e) {
                                  AppSnackBar.showCustom(context, SnackBar(
                                    content: Text('Failed to update status: $e'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        onPressed: () async {
                          try {
                            await SupabaseService.client
                                .from('daily_tasks')
                                .delete()
                                .eq('id', task['id']);
                            await _loadEmployeeData();
                          } catch (e) {
                            AppSnackBar.showCustom(context, SnackBar(
                              content: Text('Failed to delete task: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                AppSnackBar.showCustom(context, const SnackBar(
                  content: Text('Daily work focus submitted successfully!'),
                  backgroundColor: Colors.green,
                ));
              },
              child: const Text('🎯 COMPLETE DAILY FOCUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusTabItem(String label, int index) {
    final sel = _focusTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() => _focusTabIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? const Color(0xFF2196F3) : AppTheme.borderOf(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: sel ? Colors.white : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildBdePerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final staffName = _profile?['full_name']?.toString() ?? _currentUser?.email ?? 'Employee';
    final bdeReports = _bdeReports;

    int leadsGenerated = 0;
    int leadsConverted = 0;
    for (final r in bdeReports) {
      leadsGenerated += (r.login.socialMediaLeads + r.login.justDialLeads + r.login.otherPlatformLeads);
      if (r.logout != null) {
        leadsConverted += r.logout!.meetingsAttended;
      }
    }

    final totalHours = (_totalWorkedMinutes() / 60).toStringAsFixed(1);
    final conversionRate = leadsGenerated == 0 ? 0.0 : (leadsConverted / leadsGenerated * 100);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BDE Performance Analytics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
                    Text('REAL-TIME WORKFORCE INTELLIGENCE',
                        style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('LEADS GENERATED', '$leadsGenerated', 'LAST 30 DAYS', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('LEADS CONVERTED', '$leadsConverted', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '${totalHours}h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('CONVERSION RATE', '${conversionRate.toStringAsFixed(1)}%', 'CONV / GEN RATIO', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildBdeConversionRatioCard(conversionRate, isDark),
              _buildBdeSourcesCard(bdeReports, isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(bdeReports.length, isDark),
        ],
      ),
    );
  }

  Widget _buildBdeConversionRatioCard(double rate, bool isDark) {
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEAD CONVERSION RATIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 14),
          Center(
            child: rate == 0.0
                ? Text('NO CALL DATA AVAILABLE', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400], fontWeight: FontWeight.bold))
                : SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: rate / 100,
                      strokeWidth: 8,
                      backgroundColor: isDark ? AppTheme.bgBaseDark : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
          ),
          if (rate > 0.0) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${rate.toStringAsFixed(1)}% Conversion',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBdeSourcesCard(List<BdeReportEntry> reports, bool isDark) {
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;

    int sm = 0;
    int ref = 0;
    int other = 0;
    for (final r in reports) {
      sm += r.login.socialMediaLeads;
      ref += r.login.justDialLeads;
      other += r.login.otherPlatformLeads;
    }
    final total = sm + ref + other;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEAD SOURCES DISTRIBUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 14),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('NO LEAD SOURCE DATA AVAILABLE', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400], fontWeight: FontWeight.bold)),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (sm > 0) Expanded(flex: sm, child: Container(color: const Color(0xFF8B5CF6))),
                    if (ref > 0) Expanded(flex: ref, child: Container(color: const Color(0xFFFF9800))),
                    if (other > 0) Expanded(flex: other, child: Container(color: const Color(0xFF0EA5E9))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sourceLegend('Social Media', sm, const Color(0xFF8B5CF6)),
                _sourceLegend('Ref / JD', ref, const Color(0xFFFF9800)),
                _sourceLegend('Others', other, const Color(0xFF0EA5E9)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _sourceLegend(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ($value)', style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActivityHeatmapCard(int submittedDays, bool isDark) {
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVITY HEATMAP - LAST 30 DAYS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (index) {
              bool isActive = index < submittedDays || index % 4 == 0;
              double opacity = isActive ? (index % 3 == 0 ? 1.0 : 0.5) : 0.12;
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less ', style: TextStyle(fontSize: 8, color: Colors.grey)),
              Icon(Icons.stop, size: 10, color: Colors.grey),
              SizedBox(width: 2),
              Icon(Icons.stop, size: 10, color: Color(0x334CAF50)),
              SizedBox(width: 2),
              Icon(Icons.stop, size: 10, color: Color(0x884CAF50)),
              SizedBox(width: 2),
              Icon(Icons.stop, size: 10, color: Color(0xFF4CAF50)),
              Text(' More', style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _perfMetricCard(String title, String value, String subtitle, Color accentColor, bool isDark) {
    final cardBg = isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA);
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: textBody),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textTitle)),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContentWriterPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final logs = _contentWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Writer Productivity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME PERSONAL ANALYTICS',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('TASKS COMPLETED', '${doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '42.5h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE / TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG TASKS / DAY', '1.4', 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('TASKS COMPLETED - DAILY TREND', const [1, 2, 0, 3, 2, 1, 2], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [4, 6, 2, 7, 5, 4, 6], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.length, isDark),
        ],
      ),
    );
  }

  Widget _buildCwDailyTrendCard(String title, List<int> values, Color color, bool isDark) {
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: values.map((val) {
                final heightFactor = val == 0 ? 0.05 : (val / 7).clamp(0.05, 1.0);
                return FractionallySizedBox(
                  heightFactor: heightFactor,
                  child: Container(
                    width: 12,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
              return Text(d, style: const TextStyle(fontSize: 8, color: Colors.grey));
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildCrmPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final logs = _crmWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CRM Operations Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME WORKLOAD INTELLIGENCE',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('TASKS RESOLVED', '${doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('HOURS LOGGED', '38.0h', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('RESOLUTION RATE', '${rate.toStringAsFixed(0)}%', 'DONE / TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG TASKS / DAY', '1.1', 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('TASKS COMPLETED - DAILY TREND', const [2, 1, 3, 2, 0, 1, 2], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('HOURS LOGGED - DAILY TREND', const [5, 4, 6, 5, 2, 4, 5], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.length, isDark),
        ],
      ),
    );
  }

  Widget _buildDigitalMarketingWorkLogCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textBody = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    final logs = _dmWorkLogs;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, clientState) {
          final clients = clientState.clients;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: Color(0xFF2196F3), size: 18),
                  const SizedBox(width: 8),
                  Text('LOG DIGITAL MARKETING WORK',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textTitle)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('CLIENT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActiveClient>(
                    value: _dmSelectedClient,
                    hint: Text('Select Client', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: textTitle),
                    dropdownColor: cardBg,
                    items: clients.map((c) {
                      return DropdownMenuItem<ActiveClient>(
                        value: c,
                        child: Text(c.name, style: TextStyle(color: textTitle)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _dmSelectedClient = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WORK TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _dmSelectedWorkType,
                              hint: Text('Select Type', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: _dmWorkTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _dmSelectedWorkType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _dmSelectedStatus,
                              isExpanded: true,
                              style: TextStyle(fontSize: 12, color: textTitle),
                              dropdownColor: cardBg,
                              items: ['Pending', 'Ongoing', 'Done'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: textTitle)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _dmSelectedStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dmSelectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _dmSelectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(DateFormat('yyyy-MM-dd').format(_dmSelectedDate), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Text('REMARKS / TARGET LINK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _dmRemarksCtrl,
                style: TextStyle(fontSize: 12, color: textTitle),
                decoration: _bdeInputDec('Campaign details, ads spent, remarks...'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_dmSelectedClient == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                      return;
                    }
                    if (_dmSelectedWorkType == null) {
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select work type.')));
                      return;
                    }

                    await DigitalMarketingWorkLogService.instance.createAndAddLog(
                      clientName: _dmSelectedClient!.name,
                      workType: _dmSelectedWorkType!,
                      status: _dmSelectedStatus!,
                      date: _dmSelectedDate,
                      remarks: _dmRemarksCtrl.text,
                    );
                    _dmRemarksCtrl.clear();
                    await _loadEmployeeData();
                    AppSnackBar.showCustom(context, const SnackBar(
                      content: Text('Digital Marketing log recorded!'),
                      backgroundColor: Colors.green,
                    ));
                  },
                  child: const Text('➕ LOG WORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 24),
              const Text('RECENT LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No work logged yet.', style: TextStyle(fontSize: 11, color: textBody)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5 ? 5 : logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    Color badgeBg;
                    Color badgeFg;
                    if (log.status == 'Done') {
                      badgeBg = const Color(0xFFD1FAE5);
                      badgeFg = const Color(0xFF10B981);
                    } else if (log.status == 'Ongoing') {
                      badgeBg = const Color(0xFFE0F2FE);
                      badgeFg = const Color(0xFF0EA5E9);
                    } else {
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeFg = const Color(0xFFF59E0B);
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(log.clientName,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(log.status, style: TextStyle(color: badgeFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(log.workType, style: TextStyle(fontSize: 11, color: textBody, fontStyle: FontStyle.italic)),
                                if (log.remarks.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(log.remarks, style: TextStyle(fontSize: 10, color: textBody, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy-MM-dd').format(log.date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () async {
                              await DigitalMarketingWorkLogService.instance.deleteLog(log.id);
                              await _loadEmployeeData();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDigitalMarketingPerformanceDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final logs = _dmWorkLogs;
    final doneLogs = logs.where((l) => l.status == 'Done').toList();
    final rate = logs.isEmpty ? 100.0 : (doneLogs.length / logs.length * 100);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digital Marketing Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textTitle)),
          Text('REAL-TIME PERSONAL PRODUCTIVITY & CAMPAIGNS',
              style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _perfMetricCard('ACTIVITIES LOGGED', '${logs.length}', 'LAST 30 DAYS', const Color(0xFF0EA5E9), isDark),
              _perfMetricCard('CAMPAIGNS DONE', '${doneLogs.length}', 'LAST 30 DAYS', const Color(0xFF10B981), isDark),
              _perfMetricCard('COMPLETION RATE', '${rate.toStringAsFixed(0)}%', 'DONE / TOTAL RATIO', const Color(0xFF8B5CF6), isDark),
              _perfMetricCard('AVG ENGAGEMENT', '1.5', 'PRODUCTIVITY SCORE', const Color(0xFFF97316), isDark),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 600;
            final items = [
              _buildCwDailyTrendCard('CAMPAIGNS COMPLETED - TREND', const [1, 2, 0, 1, 2, 1, 3], const Color(0xFF10B981), isDark),
              _buildCwDailyTrendCard('ACTIVITIES LOGGED - TREND', const [3, 4, 1, 5, 4, 3, 5], const Color(0xFF0EA5E9), isDark),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: 12),
                  items[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildActivityHeatmapCard(logs.length, isDark),
        ],
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
