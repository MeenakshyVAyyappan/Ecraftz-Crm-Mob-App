// teams_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

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
  'Super Admin', 'Administrator', 'HR', 'Team Lead',
  'Sales', 'Employee', 'Designer', 'Developer',
];

const _departments = [
  'No Department', 'Web Developing', 'BDE',
  'Digital Marketing', 'Design', 'HR', 'Sales',
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
    default: return const Color(0xFF6B7280);
  }
}

final List<TeamMember> teamMembers = [
  TeamMember(id: '1', name: 'viswajith e', email: 'viswajithithu333@gmail.com', role: 'Super Admin', department: 'No Department', status: MemberStatus.active, registeredAt: DateTime(2026, 4, 30), isSuperAdmin: true),
  TeamMember(id: '2', name: 'Sasi', email: 'viswajith.e.cs@gmail.com', role: 'Administrator', department: 'No Department', status: MemberStatus.active, registeredAt: DateTime(2026, 4, 30)),
  TeamMember(id: '3', name: 'ananthu', email: 'viswajith8025@gmail.com', role: 'HR', department: 'No Department', status: MemberStatus.active, registeredAt: DateTime(2026, 4, 30)),
  TeamMember(id: '4', name: 'Chimbu', email: 'hackerhacker0424@gmail.com', role: 'Team Lead', department: 'Web Developing', status: MemberStatus.active, registeredAt: DateTime(2026, 5, 5)),
  TeamMember(id: '5', name: 'Tony Stark', email: 'viswajith.ecraftz@gmail.com', role: 'Sales', department: 'BDE', status: MemberStatus.active, registeredAt: DateTime(2026, 5, 12)),
  TeamMember(id: '6', name: 'Fathima Safa', email: 'fathmasafa.work@gmail.com', role: 'Employee', department: 'Digital Marketing', status: MemberStatus.active, registeredAt: DateTime(2026, 5, 26)),
  TeamMember(id: '7', name: 'Roronoa', email: 'roronoa@gmail.com', role: 'Employee', department: 'Web Developing', status: MemberStatus.active, registeredAt: DateTime(2026, 5, 26)),
  TeamMember(id: '8', name: 'admin', email: 'admin@ecraftz.com', role: 'Employee', department: 'No Department', status: MemberStatus.pending, registeredAt: DateTime(2026, 5, 26)),
  TeamMember(id: '9', name: 'Test Active', email: 'testactive@gmail.com', role: 'Employee', department: 'No Department', status: MemberStatus.pending, registeredAt: DateTime(2026, 5, 26)),
  TeamMember(id: '10', name: 'Roopesh', email: 'livein@jananilifestyle.in', role: 'Employee', department: 'No Department', status: MemberStatus.denied, registeredAt: DateTime(2026, 5, 5)),
];

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

  List<TeamMember> get _members => teamMembers;

  List<TeamMember> get _filtered {
    return _members.where((m) {
      final matchTab = m.status == _tab;
      final matchSearch = _search.isEmpty ||
          m.name.toLowerCase().contains(_search.toLowerCase()) ||
          m.email.toLowerCase().contains(_search.toLowerCase()) ||
          m.role.toLowerCase().contains(_search.toLowerCase());
      return matchTab && matchSearch;
    }).toList();
  }

  int _countByStatus(MemberStatus s) =>
      _members.where((m) => m.status == s).length;

  int get _pendingCount => _countByStatus(MemberStatus.pending);

  void _approve(TeamMember m) {
    setState(() => m.status = MemberStatus.active);
    _snack('${m.name} approved', const Color(0xFF10B981));
  }

  void _deny(TeamMember m) {
    setState(() => m.status = MemberStatus.denied);
    _snack('${m.name} denied', Colors.red);
  }

  void _reinstate(TeamMember m) {
    setState(() => m.status = MemberStatus.pending);
    _snack('${m.name} reinstated to pending', const Color(0xFFF59E0B));
  }

  void _archive(TeamMember m) {
    setState(() => m.status = MemberStatus.archived);
    _snack('${m.name} archived', const Color(0xFF6B7280));
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  void _changeRole(TeamMember m, String role) =>
      setState(() => m.role = role);

  void _changeDept(TeamMember m, String dept) =>
      setState(() => m.department = dept);

  @override
  Widget build(BuildContext context) {
    final members = _filtered;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
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
            Text('Team Members',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
            Text('View and manage all registered users within the CRM platform.',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // Pending banner
          if (_pendingCount > 0) _buildPendingBanner(),
          // Tabs
          _buildTabs(),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF9CA3AF), size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Color(0xFF6B7280)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF00BCD4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Table header
          _buildTableHeader(isWide),
          // List
          Expanded(
            child: members.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      if (!isWide) {
                        return _MemberCardMobile(
                          member: members[i],
                          tab: _tab,
                          onApprove: () => _approve(members[i]),
                          onDeny: () => _deny(members[i]),
                          onReinstate: () => _reinstate(members[i]),
                          onArchive: () => _archive(members[i]),
                          onRoleChange: (r) => _changeRole(members[i], r),
                          onDeptChange: (d) => _changeDept(members[i], d),
                        );
                      }
                      return _MemberRow(
                        member: members[i],
                        isWide: isWide,
                        tab: _tab,
                        onApprove: () => _approve(members[i]),
                        onDeny: () => _deny(members[i]),
                        onReinstate: () => _reinstate(members[i]),
                        onArchive: () => _archive(members[i]),
                        onRoleChange: (r) => _changeRole(members[i], r),
                        onDeptChange: (d) => _changeDept(members[i], d),
                      );
                    },
                  ),
          ),
          // Dynamic role info
          _buildRoleInfo(),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
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
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E))),
                const Text(
                    'New users are waiting for admin approval to access the system.',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFF78350F))),
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

  Widget _buildTabs() {
    final tabs = [
      (MemberStatus.active, 'ACTIVE'),
      (MemberStatus.pending, 'PENDING'),
      (MemberStatus.denied, 'DENIED'),
      (MemberStatus.archived, 'ARCHIVED'),
    ];

    return Container(
      color: Colors.white,
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
                          : const Color(0xFFE5E7EB),
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
                                  : const Color(0xFF6B7280))),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280))),
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

  Widget _buildTableHeader(bool isWide) {
    if (!isWide) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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

  Widget _buildEmpty() {
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
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      ),
    );
  }

  Widget _buildRoleInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Color(0xFF00BCD4)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DYNAMIC ROLE SYSTEM',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0369A1),
                        letterSpacing: 0.4)),
                SizedBox(height: 4),
                Text(
                    '• Roles are fully dynamic — create custom roles in Roles & Access Control.\n'
                    '• Assigning a role here instantly updates the user\'s permissions.\n'
                    '• Super Admin has permanent full access and cannot be reassigned.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0369A1),
                        height: 1.5)),
              ],
            ),
          ),
        ],
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
    return Text(text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
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
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 10, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(member.email,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280)),
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
                      items: _departments,
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
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: color),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i,
                      style: const TextStyle(fontSize: 11))))
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

  const _MemberCardMobile({
    required this.member,
    required this.tab,
    required this.onApprove,
    required this.onDeny,
    required this.onReinstate,
    required this.onArchive,
    required this.onRoleChange,
    required this.onDeptChange,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = member.status.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
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
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(member.email,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280)),
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
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ROLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
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
                    const Text('DEPARTMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    member.isSuperAdmin
                        ? _DeptBadge(dept: member.department)
                        : _DropdownBadge(
                            value: member.department,
                            items: _departments,
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
                  const Text('REGISTERED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(member.registeredAt),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
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
            const Divider(height: 24),
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