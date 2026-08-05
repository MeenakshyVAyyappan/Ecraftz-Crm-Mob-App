// teams_page.dart
import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isCurrentUserSuperAdmin = false;
  List<TeamMember> _members = [];
  List<Map<String, dynamic>> _dynamicDepartments = [];
  List<String> _dynamicRoles = ['Administrator', 'Employee', 'HR', 'Sales', 'Team Lead'];
  Map<String, String> _roleNameToId = {};
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

      final rolesRes = await SupabaseService.client.from('roles').select('id, name');
      final fetchedRoles = List<Map<String, dynamic>>.from(rolesRes as List);

      final userRolesRes = await SupabaseService.client.from('user_roles').select('user_id, role_id, roles(name)');
      final userRolesList = List<Map<String, dynamic>>.from(userRolesRes as List);

      final Map<String, String> userIdToCustomRole = {};
      for (final ur in userRolesList) {
        final userId = ur['user_id']?.toString() ?? '';
        final roleMap = ur['roles'];
        if (roleMap is Map) {
          final roleName = roleMap['name']?.toString() ?? '';
          if (userId.isNotEmpty && roleName.isNotEmpty) {
            userIdToCustomRole[userId] = _mapRoleFromDb(roleName);
          }
        }
      }

      final Set<String> uniqueRoleNames = {};
      final Map<String, String> nameToId = {};
      for (final r in fetchedRoles) {
        final name = r['name']?.toString() ?? '';
        final id = r['id']?.toString() ?? '';
        if (name.isNotEmpty && id.isNotEmpty && name.toLowerCase() != 'super admin' && name.toLowerCase() != 'super_admin') {
          final mappedName = _mapRoleFromDb(name);
          uniqueRoleNames.add(mappedName);
          nameToId[mappedName.toLowerCase()] = id;
        }
      }

      final profilesRes = await SupabaseService.client
          .from('profiles')
          .select('*, departments:departments!fk_profiles_dept(id, name)')
          .eq('organization_id', '00000000-0000-0000-0000-000000000000');
      
      final fetchedProfiles = List<Map<String, dynamic>>.from(profilesRes as List);

      final List<TeamMember> loadedMembers = fetchedProfiles.map((p) {
        final id = p['id']?.toString() ?? '';
        final name = p['full_name']?.toString() ?? 'Unknown';
        final email = p['email']?.toString() ?? '';
        
        final rawRole = p['role']?.toString();
        final role = userIdToCustomRole[id] ?? _mapRoleFromDb(rawRole);

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

      bool isSuperAdmin = false;
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final currentEmail = currentUser.email?.toLowerCase() ?? '';
        final currentId = currentUser.id;

        final selfMember = loadedMembers.firstWhere(
          (m) => m.id == currentId || (currentEmail.isNotEmpty && m.email.toLowerCase() == currentEmail),
          orElse: () => TeamMember(
            id: '',
            name: '',
            email: '',
            role: '',
            department: '',
            status: MemberStatus.pending,
            registeredAt: DateTime.now(),
          ),
        );

        if (selfMember.id.isNotEmpty) {
          isSuperAdmin = selfMember.isSuperAdmin;
        } else {
          isSuperAdmin = currentEmail == 'viswajithjithu3335@gmail.com' ||
                         currentEmail == 'viswajithjithu333@gmail.com' ||
                         currentId == 'f417dc7e-a4c3-4964-9e62-553ffffcef8c';
        }
      }
      
      if (!isSuperAdmin) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedRole = prefs.getString('user_role')?.toLowerCase();
          if (cachedRole == 'super_admin' || cachedRole == 'super admin') {
            isSuperAdmin = true;
          }
        } catch (_) {}
      }

      setState(() {
        _dynamicDepartments = fetchedDepts;
        _members = loadedMembers;
        _isCurrentUserSuperAdmin = isSuperAdmin;
        _dynamicRoles = uniqueRoleNames.toList();
        _roleNameToId = nameToId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to load data from Supabase: $e', Colors.red);
    }
  }

  Future<void> _createTeamMember({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String department,
    String? biometricId,
  }) async {
    if (!_isCurrentUserSuperAdmin) {
      throw Exception('Permission denied: Only Super Admin can add team members.');
    }

    final tempClient = SupabaseClient(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false,
      ),
    );

    final authRes = await tempClient.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        'full_name': fullName.trim(),
        'name': fullName.trim(),
      },
    );

    final newUserId = authRes.user?.id;
    if (newUserId == null) {
      throw Exception('User account creation failed or did not return a user ID.');
    }

    final dbRole = _mapRoleToDb(role);
    final deptId = _findDeptIdByName(department);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await SupabaseService.client.from('profiles').upsert({
      'id': newUserId,
      'full_name': fullName.trim(),
      'email': email.trim(),
      'role': dbRole,
      'department_id': deptId,
      'biometric_id': (biometricId != null && biometricId.trim().isNotEmpty) ? biometricId.trim() : null,
      'status': 'active',
      'organization_id': '00000000-0000-0000-0000-000000000000',
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    final roleId = _roleNameToId[role.toLowerCase()];
    if (roleId != null) {
      try {
        await SupabaseService.client.from('user_roles').upsert({
          'user_id': newUserId,
          'role_id': roleId,
        });
      } catch (e) {
        debugPrint('Error assigning custom role to user: $e');
      }
    }

    if (deptId != null) {
      try {
        await SupabaseService.client.from('department_members').insert({
          'profile_id': newUserId,
          'department_id': deptId,
        });
      } catch (_) {}
    }

    setState(() {
      _tab = MemberStatus.active;
    });

    await _fetchData(showLoading: false);

    _snack('Team member "$fullName" created successfully.', const Color(0xFF10B981));
  }

  void _showAddTeamMemberDialog() {
    if (!_isCurrentUserSuperAdmin) {
      _snack('Only Super Admin can add new team members.', Colors.red);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final biometricCtrl = TextEditingController();

    String selectedRole = _dynamicRoles.isNotEmpty ? _dynamicRoles.first : 'Employee';
    String selectedDept = _departmentNames.isNotEmpty ? _departmentNames.first : 'No Department';

    bool isObscure = true;
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = Theme.of(context).colorScheme.surface;
            final borderClr = AppTheme.borderOf(context);
            final textPrimary = AppTheme.textPrimaryOf(context);
            final textSecondary = AppTheme.textSecondaryOf(context);
            final textMuted = AppTheme.textMutedOf(context);

            final screenWidth = MediaQuery.of(context).size.width;
            final isFormWide = screenWidth > 580;
            final dialogWidth = isFormWide ? 480.0 : (screenWidth * 0.88);

            final roleWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _dynamicRoles.contains(selectedRole) ? selectedRole : (_dynamicRoles.isNotEmpty ? _dynamicRoles.first : 'Employee'),
                  dropdownColor: dialogBg,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  items: (_dynamicRoles.contains(selectedRole) 
                      ? _dynamicRoles 
                      : [..._dynamicRoles, selectedRole]).map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 18, color: textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ],
            );

            final deptWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Department *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _departmentNames.contains(selectedDept) ? selectedDept : _departmentNames.first,
                  dropdownColor: dialogBg,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  items: _departmentNames.map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDept = val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    prefixIcon: Icon(Icons.business_outlined, size: 18, color: textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ],
            );

            return AlertDialog(
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderClr),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF00BCD4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Team Member',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Create an employee account and set role & department',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: dialogWidth,
                  padding: const EdgeInsets.only(top: 4),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: nameCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            hintStyle: TextStyle(color: textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: textSecondary),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Email Address *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email Address is required';
                            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegExp.hasMatch(v.trim())) return 'Enter a valid email address';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'employee@ecraftz.com',
                            hintStyle: TextStyle(color: textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.email_outlined, size: 18, color: textSecondary),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: isObscure,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                          decoration: InputDecoration(
                            hintText: 'Minimum 6 characters',
                            hintStyle: TextStyle(color: textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textSecondary),
                              onPressed: () => setDialogState(() => isObscure = !isObscure),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (isFormWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: roleWidget),
                              const SizedBox(width: 12),
                              Expanded(child: deptWidget),
                            ],
                          )
                        else ...[
                          roleWidget,
                          const SizedBox(height: 12),
                          deptWidget,
                        ],
                        const SizedBox(height: 12),

                        Text('Biometric ID / eSSL PIN (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: biometricCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. 1004',
                            hintStyle: TextStyle(color: textMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.fingerprint_rounded, size: 18, color: textSecondary),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderClr)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });
                          try {
                            await _createTeamMember(
                              fullName: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passwordCtrl.text.trim(),
                              role: selectedRole,
                              department: selectedDept,
                              biometricId: biometricCtrl.text.trim(),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              final errStr = e.toString();
                              if (errStr.contains('already registered') || errStr.contains('user_already_exists')) {
                                errorMessage = 'This email address is already registered.';
                              } else {
                                errorMessage = 'Failed to create member: $e';
                              }
                            });
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(isSubmitting ? 'Creating...' : 'Add Team Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
    AppSnackBar.showCustom(context, 
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

      final roleId = _roleNameToId[role.toLowerCase()];
      if (roleId != null) {
        await SupabaseService.client.from('user_roles').upsert({
          'user_id': m.id,
          'role_id': roleId,
        });
      } else {
        try {
          await SupabaseService.client.from('user_roles').delete().eq('user_id', m.id);
        } catch (e) {
          debugPrint('Error clearing user role: $e');
        }
      }

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
          if (_isCurrentUserSuperAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ElevatedButton.icon(
                onPressed: _showAddTeamMemberDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                label: Text(isWide ? 'Add Team Member' : 'Add Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 12 : 8, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          AppRefreshButton(
            onRefresh: () async {
              await _fetchData();
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
          // Search & Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: _textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16, color: _textSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              })
                          : null,
                      filled: true,
                      fillColor: _cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_isCurrentUserSuperAdmin && isWide) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddTeamMemberDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Add Team Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
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
                              roleItems: _dynamicRoles,
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
                            roleItems: _dynamicRoles,
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
  final List<String> roleItems;

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
    required this.roleItems,
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
                    items: roleItems.contains(member.role) 
                        ? roleItems 
                        : [...roleItems, member.role],
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
  final List<String> roleItems;

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
    required this.roleItems,
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
                             items: roleItems.contains(member.role) 
                                 ? roleItems 
                                 : [...roleItems, member.role],
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
