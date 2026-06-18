// teams_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../services/supabase_service.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum MemberStatus { active, pending, denied, archived }

extension MemberStatusExt on MemberStatus {
  String get label {
    switch (this) {
      case MemberStatus.active: return 'ACTIVE';
      case MemberStatus.pending: return 'PENDING';
      case MemberStatus.denied: return 'DENIED';
      case MemberStatus.archived: return 'ARCHIVED';
    }
  }

  Color get color {
    switch (this) {
      case MemberStatus.active: return const Color(0xFF10B981);
      case MemberStatus.pending: return const Color(0xFFF59E0B);
      case MemberStatus.denied: return const Color(0xFFEF4444);
      case MemberStatus.archived: return const Color(0xFF6B7280);
    }
  }
}

class TeamMember {
  final String id;
  String name;
  String email;
  String role;
  String department;
  MemberStatus status;
  final DateTime registeredAt;
  final bool isSuperAdmin;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.registeredAt,
    this.isSuperAdmin = false,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── AVAILABLE ROLES & DEPARTMENTS ───────────────────────────────────────────

const _roles = [
  'Administrator', 'Employee', 'HR', 'Sales', 'Team Lead',
];

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'super admin': return const Color(0xFF7C3AED);
    case 'administrator': return const Color(0xFF2563EB);
    case 'hr': return const Color(0xFF059669);
    case 'team lead': return const Color(0xFFF97316);
    case 'sales': return const Color(0xFFEC4899);
    case 'employee': return const Color(0xFF6B7280);
    case 'designer': return const Color(0xFF8B5CF6);
    case 'developer': return const Color(0xFF3B82F6);
    default: return const Color(0xFF6B7280);
  }
}

Color _deptColor(String dept) {
  if (dept == 'No Department') return const Color(0xFF6B7280);
  switch (dept.toLowerCase()) {
    case 'web developing': return const Color(0xFF3B82F6);
    case 'bde': return const Color(0xFFF59E0B);
    case 'digital marketing': return const Color(0xFFEC4899);
    case 'design': return const Color(0xFF8B5CF6);
    case 'hr': return const Color(0xFF10B981);
    case 'sales': return const Color(0xFFF97316);
    case 'crm': return const Color(0xFF14B8A6);
    case 'content writer': return const Color(0xFF8B5CF6);
    case 'video editing': return const Color(0xFF6366F1);
    case 'videography': return const Color(0xFFEC4899);
    default: return const Color(0xFF00BCD4);
  }
}

MemberStatus _parseStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'active':
      return MemberStatus.active;
    case 'pending':
      return MemberStatus.pending;
    case 'denied':
      return MemberStatus.denied;
    case 'archived':
      return MemberStatus.archived;
    default:
      return MemberStatus.pending;
  }
}

String _statusToString(MemberStatus status) {
  switch (status) {
    case MemberStatus.active:
      return 'active';
    case MemberStatus.pending:
      return 'pending';
    case MemberStatus.denied:
      return 'denied';
    case MemberStatus.archived:
      return 'archived';
  }
}

String _mapRoleFromDb(String? role) {
  if (role == null) return 'Employee';
  switch (role.toLowerCase()) {
    case 'admin':
    case 'administrator':
      return 'Administrator';
    case 'super admin':
    case 'super_admin':
      return 'Super Admin';
    case 'hr':
      return 'HR';
    case 'team lead':
    case 'manager':
      return 'Team Lead';
    case 'sales':
      return 'Sales';
    case 'employee':
      return 'Employee';
    case 'designer':
      return 'Designer';
    case 'developer':
      return 'Developer';
    default:
      return role;
  }
}

String _mapRoleToDb(String role) {
  switch (role.toLowerCase()) {
    case 'super admin':
    case 'super_admin':
      return 'super_admin';
    case 'administrator':
    case 'admin':
      return 'admin';
    case 'hr':
      return 'hr';
    case 'team lead':
    case 'manager':
      return 'manager';
    case 'sales':
      return 'sales';
    default:
      return 'employee';
  }
}

List<TeamMember> teamMembers = [];

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class TeamsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;  
  const TeamsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MemberStatus _tab = MemberStatus.active;
  String _search = '';
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List<TeamMember> _members = [];
  List<Map<String, dynamic>> _dynamicDepartments = [];
  RealtimeChannel? _profileSubscription;

  List<String> get _departmentNames => ['No Department'] + _dynamicDepartments.map((d) => d['name'] as String).toList();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _subscribeToProfiles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_profileSubscription != null) {
      SupabaseService.client.removeChannel(_profileSubscription!);
    }
    super.dispose();
  }

  void _subscribeToProfiles() {
    _profileSubscription = SupabaseService.client
        .channel('public:profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            _fetchData(showLoading: false);
          },
        )
        .subscribe();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final deptsRes = await SupabaseService.client.from('departments').select('id, name');
      final fetchedDepts = List<Map<String, dynamic>>.from(deptsRes as List);

      final profilesRes = await SupabaseService.client
          .from('profiles')
          .select('*, departments:departments!fk_profiles_dept(id, name)');
      
      final fetchedProfiles = List<Map<String, dynamic>>.from(profilesRes as List);

      final List<TeamMember> loadedMembers = fetchedProfiles.map((p) {
        final id = p['id']?.toString() ?? '';
        final name = p['full_name']?.toString() ?? 'Unknown';
        final email = p['email']?.toString() ?? '';
        
        final rawRole = p['role']?.toString();
        final role = _mapRoleFromDb(rawRole);

        final deptMap = p['departments'];
        final department = deptMap != null ? (deptMap['name']?.toString() ?? 'No Department') : 'No Department';

        final rawStatus = p['status']?.toString();
        final status = _parseStatus(rawStatus);

        final createdAtStr = p['created_at']?.toString() ?? '';
        final registeredAt = createdAtStr.isNotEmpty ? DateTime.parse(createdAtStr) : DateTime.now();

        final isSuperAdmin = email == 'viswajithjithu3335@gmail.com' ||
                             email == 'viswajithjithu333@gmail.com' ||
                             id == 'f417dc7e-a4c3-4964-9e62-553ffffcef8c' ||
                             role.toLowerCase() == 'super admin';

        return TeamMember(
          id: id,
          name: name,
          email: email,
          role: role,
          department: department,
          status: status,
          registeredAt: registeredAt,
          isSuperAdmin: isSuperAdmin,
        );
      }).toList();

      setState(() {
        _dynamicDepartments = fetchedDepts;
        _members = loadedMembers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to load data from Supabase: $e', Colors.red);
    }
  }

  List<TeamMember> get _filtered {
    return _members.where((m) {
      final matchTab = m.status == _tab;
      final matchSearch = _search.isEmpty ||
          m.name.toLowerCase().contains(_search.toLowerCase()) ||
          m.email.toLowerCase().contains(_search.toLowerCase()) ||
          m.role.toLowerCase().contains(_search.toLowerCase()) ||
          m.department.toLowerCase().contains(_search.toLowerCase());
      return matchTab && matchSearch;
    }).toList();
  }

  int _countByStatus(MemberStatus s) =>
      _members.where((m) => m.status == s).length;

  int get _pendingCount => _countByStatus(MemberStatus.pending);

  Future<void> _updateStatus(TeamMember m, MemberStatus newStatus) async {
    final statusStr = _statusToString(newStatus);
    try {
      await SupabaseService.client.from('profiles').update({
        'status': statusStr,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', m.id);

      setState(() {
        m.status = newStatus;
      });
      
      String msg;
      Color color;
      switch (newStatus) {
        case MemberStatus.active:
          msg = '${m.name} approved';
          color = const Color(0xFF10B981);
          break;
        case MemberStatus.pending:
          msg = '${m.name} reinstated to pending';
          color = const Color(0xFFF59E0B);
          break;
        case MemberStatus.denied:
          msg = '${m.name} denied';
          color = Colors.red;
          break;
        case MemberStatus.archived:
          msg = '${m.name} archived';
          color = const Color(0xFF6B7280);
          break;
      }
      _snack(msg, color);
    } catch (e) {
      _snack('Failed to update status: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _updateRole(TeamMember m, String role) async {
    try {
      final dbRole = _mapRoleToDb(role);
      await SupabaseService.client.from('profiles').update({
        'role': dbRole,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', m.id);

      setState(() {
        m.role = role;
      });
      _snack('Role updated to $role', const Color(0xFF10B981));
    } catch (e) {
      _snack('Failed to update role: $e', Colors.red);
    }
  }

  String? _findDeptIdByName(String name) {
    if (name == 'No Department') return null;
    final dept = _dynamicDepartments.firstWhere(
      (d) => d['name'] == name,
      orElse: () => {},
    );
    return dept['id']?.toString();
  }

  Future<void> _updateDepartment(TeamMember m, String deptName) async {
    final deptId = _findDeptIdByName(deptName);
    try {
      // 1. Update profiles table
      await SupabaseService.client.from('profiles').update({
        'department_id': deptId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', m.id);

      // 2. Sync department_members table
      final dmRes = await SupabaseService.client.from('department_members').select('id').eq('profile_id', m.id);
      if (dmRes.isNotEmpty) {
        final dmId = dmRes.first['id'];
        if (deptId == null) {
          await SupabaseService.client.from('department_members').delete().eq('id', dmId);
        } else {
          await SupabaseService.client.from('department_members').update({
            'department_id': deptId,
          }).eq('id', dmId);
        }
      } else if (deptId != null) {
        await SupabaseService.client.from('department_members').insert({
          'profile_id': m.id,
          'department_id': deptId,
        });
      }

      setState(() {
        m.department = deptName;
      });
      _snack('Department updated to $deptName', const Color(0xFF10B981));
    } catch (e) {
      _snack('Failed to update department: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _filtered;
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _bg = Theme.of(context).scaffoldBackgroundColor;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);

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
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: _textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Members',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary)),
            Text('View and manage all registered users within the CRM platform.',
                style: TextStyle(fontSize: 10, color: _textSecondary)),
          ],
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
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          // Pending banner
          if (_pendingCount > 0) _buildPendingBanner(isDark),
          // Tabs
          _buildTabs(isDark, _cardBg, _border, _textSecondary),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: _textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle:
                    TextStyle(color: _textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    color: _textSecondary, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            size: 16, color: _textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: _cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF00BCD4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Table header
          _buildTableHeader(isWide, _border),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                : (members.isEmpty
                    ? _buildEmpty(_textSecondary)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: members.length,
                        itemBuilder: (_, i) {
                          if (!isWide) {
                            return _MemberCardMobile(
                              member: members[i],
                              tab: _tab,
                              onApprove: () => _updateStatus(members[i], MemberStatus.active),
                              onDeny: () => _updateStatus(members[i], MemberStatus.denied),
                              onReinstate: () => _updateStatus(members[i], MemberStatus.pending),
                              onArchive: () => _updateStatus(members[i], MemberStatus.archived),
                              onRoleChange: (r) => _updateRole(members[i], r),
                              onDeptChange: (d) => _updateDepartment(members[i], d),
                              deptItems: _departmentNames,
                            );
                          }
                          return _MemberRow(
                            member: members[i],
                            isWide: isWide,
                            tab: _tab,
                            onApprove: () => _updateStatus(members[i], MemberStatus.active),
                            onDeny: () => _updateStatus(members[i], MemberStatus.denied),
                            onReinstate: () => _updateStatus(members[i], MemberStatus.pending),
                            onArchive: () => _updateStatus(members[i], MemberStatus.archived),
                            onRoleChange: (r) => _updateRole(members[i], r),
                            onDeptChange: (d) => _updateDepartment(members[i], d),
                            deptItems: _departmentNames,
                          );
                        },
                      )),
          ),

        ],
      ),
    );
  }

  Widget _buildPendingBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF452B09) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_pendingCount Pending Approval${_pendingCount > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.amber : const Color(0xFF92400E))),
                Text(
                    'New users are waiting for admin approval to access the system.',
                    style:
                        TextStyle(fontSize: 11, color: isDark ? Colors.amber[200]! : const Color(0xFF78350F))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _tab = MemberStatus.pending),
            child: const Text('Review Now',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B))),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark, Color cardBg, Color border, Color textSecondary) {
    final tabs = [
      (MemberStatus.active, 'ACTIVE'),
      (MemberStatus.pending, 'PENDING'),
      (MemberStatus.denied, 'DENIED'),
      (MemberStatus.archived, 'ARCHIVED'),
    ];

    return Container(
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((t) {
            final status = t.$1;
            final label = t.$2;
            final count = _countByStatus(status);
            final isSelected = _tab == status;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _tab = status;
                  _search = '';
                  _searchCtrl.clear();
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00BCD4)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00BCD4)
                          : border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : textSecondary)),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : (isDark ? AppTheme.bgBaseDark : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableHeader(bool isWide, Color border) {
    if (!isWide) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        border: Border.all(color: border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: _TH('MEMBER')),
          const Expanded(flex: 2, child: _TH('ROLE')),
          if (isWide) const Expanded(flex: 2, child: _TH('DEPARTMENT')),
          if (isWide) const Expanded(flex: 2, child: _TH('REGISTERED')),
          const Expanded(flex: 2, child: _TH('STATUS')),
          const Expanded(flex: 2, child: _TH('ACTIONS')),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color textSecondary) {
    const msgs = {
      MemberStatus.active: 'No active members',
      MemberStatus.pending: 'No pending approvals',
      MemberStatus.denied: 'No denied members',
      MemberStatus.archived: 'No archived members found.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(msgs[_tab] ?? 'No members found',
            style: TextStyle(color: textSecondary, fontSize: 14)),
      ),
    );
  }


}

// ─── TABLE HEADER CELL ────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    final _textSecondary = AppTheme.textSecondaryOf(context);
    return Text(text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 0.5));
  }
}

// ─── MEMBER ROW ───────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final TeamMember member;
  final bool isWide;
  final MemberStatus tab;
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  final VoidCallback onReinstate;
  final VoidCallback onArchive;
  final Function(String) onRoleChange;
  final Function(String) onDeptChange;
  final List<String> deptItems;

  const _MemberRow({
    required this.member,
    required this.isWide,
    required this.tab,
    required this.onApprove,
    required this.onDeny,
    required this.onReinstate,
    required this.onArchive,
    required this.onRoleChange,
    required this.onDeptChange,
    required this.deptItems,
  });

  @override
  Widget build(BuildContext context) {
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          left: BorderSide(color: _border),
          right: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          // Member info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(initials: member.initials, color: _roleColor(member.role)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 10, color: _textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(member.email,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Role
          Expanded(
            flex: 2,
            child: member.isSuperAdmin
                ? _RoleBadge(role: member.role)
                : _DropdownBadge(
                    value: member.role,
                    items: _roles,
                    color: _roleColor(member.role),
                    onChanged: onRoleChange,
                  ),
          ),
          // Department (wide only)
          if (isWide)
            Expanded(
              flex: 2,
              child: member.isSuperAdmin
                  ? _DeptBadge(dept: member.department)
                  : _DropdownBadge(
                      value: member.department,
                      items: deptItems,
                      color: _deptColor(member.department),
                      onChanged: onDeptChange,
                    ),
            ),
          // Registered (wide only)
          if (isWide)
            Expanded(
              flex: 2,
              child: Text(
                _fmt(member.registeredAt),
                style: TextStyle(
                    fontSize: 11, color: _textSecondary),
              ),
            ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: member.status.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(member.status.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: member.status.color)),
              ],
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (member.isSuperAdmin) return const SizedBox();

    switch (tab) {
      case MemberStatus.pending:
        return Row(
          children: [
            _ActionBtn(
              icon: Icons.check,
              label: 'Approve',
              color: const Color(0xFF10B981),
              onTap: onApprove,
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              icon: Icons.close,
              label: 'Deny',
              color: Colors.red,
              onTap: onDeny,
            ),
          ],
        );
      case MemberStatus.denied:
        return _ActionBtn(
          icon: Icons.restore_rounded,
          label: 'Reinstate',
          color: const Color(0xFF00BCD4),
          onTap: onReinstate,
        );
      case MemberStatus.active:
        return _ActionBtn(
          icon: Icons.archive_outlined,
          label: 'Archive',
          color: const Color(0xFF6B7280),
          onTap: onArchive,
        );
      case MemberStatus.archived:
        return _ActionBtn(
          icon: Icons.restore_rounded,
          label: 'Restore',
          color: const Color(0xFF10B981),
          onTap: onReinstate,
        );
    }
  }

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─── SMALL WIDGETS ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DeptBadge extends StatelessWidget {
  final String dept;
  const _DeptBadge({required this.dept});

  @override
  Widget build(BuildContext context) {
    final color = _deptColor(dept);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(dept,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _DropdownBadge extends StatelessWidget {
  final String value;
  final List<String> items;
  final Color color;
  final Function(String) onChanged;

  const _DropdownBadge({
    required this.value,
    required this.items,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> dropdownItems = items.contains(value) ? items : [value, ...items];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: color),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
          items: dropdownItems
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── MEMBER CARD MOBILE ───────────────────────────────────────────────────────

class _MemberCardMobile extends StatelessWidget {
  final TeamMember member;
  final MemberStatus tab;
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  final VoidCallback onReinstate;
  final VoidCallback onArchive;
  final Function(String) onRoleChange;
  final Function(String) onDeptChange;
  final List<String> deptItems;

  const _MemberCardMobile({
    required this.member,
    required this.tab,
    required this.onApprove,
    required this.onDeny,
    required this.onReinstate,
    required this.onArchive,
    required this.onRoleChange,
    required this.onDeptChange,
    required this.deptItems,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = Theme.of(context).colorScheme.surface;
    final _border = AppTheme.borderOf(context);
    final _textPrimary = AppTheme.textPrimaryOf(context);
    final _textSecondary = AppTheme.textSecondaryOf(context);
    final _textMuted = AppTheme.textMutedOf(context);
    final statusColor = member.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initials: member.initials, color: _roleColor(member.role)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 12, color: _textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(member.email,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 20, color: _border),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ROLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    member.isSuperAdmin
                        ? _RoleBadge(role: member.role)
                        : _DropdownBadge(
                            value: member.role,
                            items: _roles,
                            color: _roleColor(member.role),
                            onChanged: onRoleChange,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEPARTMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    member.isSuperAdmin
                        ? _DeptBadge(dept: member.department)
                        : _DropdownBadge(
                            value: member.department,
                            items: deptItems,
                            color: _deptColor(member.department),
                            onChanged: onDeptChange,
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REGISTERED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(member.registeredAt),
                    style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(member.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (!member.isSuperAdmin) ...[
            Divider(height: 24, color: _border),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActions(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (tab) {
      case MemberStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionBtn(
              icon: Icons.check,
              label: 'Approve',
              color: const Color(0xFF10B981),
              onTap: onApprove,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.close,
              label: 'Deny',
              color: Colors.red,
              onTap: onDeny,
            ),
          ],
        );
      case MemberStatus.denied:
        return _ActionBtn(
          icon: Icons.restore_rounded,
          label: 'Reinstate',
          color: const Color(0xFF00BCD4),
          onTap: onReinstate,
        );
      case MemberStatus.active:
        return _ActionBtn(
          icon: Icons.archive_outlined,
          label: 'Archive',
          color: const Color(0xFF6B7280),
          onTap: onArchive,
        );
      case MemberStatus.archived:
        return _ActionBtn(
          icon: Icons.restore_rounded,
          label: 'Restore',
          color: const Color(0xFF10B981),
          onTap: onReinstate,
        );
    }
  }

  String _fmt(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}