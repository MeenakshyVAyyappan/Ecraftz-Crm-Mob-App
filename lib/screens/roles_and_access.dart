import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';


// ─── Data Models ─────────────────────────────────────────────────────────────

class RoleModel {
  final String id;
  final String name;
  final String description;
  final int permissionsEnabled;
  final int totalPermissions;
  final List<ActiveUser> activeUsers;
  final bool isSystem;
  final Color shieldColor;
  final Map<String, List<Permission>> permissionGroups;
  final List<ModuleAccess> moduleAccesses;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionsEnabled,
    required this.totalPermissions,
    required this.activeUsers,
    required this.isSystem,
    required this.shieldColor,
    required this.permissionGroups,
    required this.moduleAccesses,
  });
}

class ActiveUser {
  final String initial;
  final Color color;
  const ActiveUser(this.initial, this.color);
}

class Permission {
  final String id;
  final String name;
  final String description;
  bool enabled;
  Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.enabled,
  });
}

class ModuleAccess {
  final String name;
  final String description;
  bool enabled;
  ModuleAccess({
    required this.name,
    required this.description,
    required this.enabled,
  });
}

// ─── All Modules List ─────────────────────────────────────────────────────────

List<ModuleAccess> _buildAdminModules() => [
  ModuleAccess(name: 'Teams', description: 'Access to organization teams management.', enabled: false),
  ModuleAccess(name: 'Admin Dashboard Module', description: 'Access to admin-level team, settings, and workspace controls.', enabled: true),
  ModuleAccess(name: 'Client Statements', description: 'Access to client statements and ledger views.', enabled: false),
  ModuleAccess(name: 'Billing Module', description: 'Access to corporate invoicing, manual billing, and renewals.', enabled: true),
  ModuleAccess(name: 'Scheduler Module', description: 'Access to the interactive corporate calendar and task schedules.', enabled: true),
  ModuleAccess(name: 'Client Onboarding Module', description: 'Access to client onboarding and dynamic forms.', enabled: true),
  ModuleAccess(name: 'CRM Module', description: 'Access to customer relations, leads, and client lists.', enabled: true),
  ModuleAccess(name: 'Document Vault Module', description: 'Access to secure file repository and documentation storage.', enabled: false),
  ModuleAccess(name: 'Dashboard Module', description: 'Access to the main overview dashboard and team workload metrics.', enabled: true),
  ModuleAccess(name: 'HR & Leave Module', description: 'Access to corporate HR, employee listings, and attendance.', enabled: true),
  ModuleAccess(name: 'View Leave Approvals Manager', description: 'Access the high-level manager leave request queue.', enabled: true),
  ModuleAccess(name: 'Leave Approvals', description: 'Access to leave approvals dashboard.', enabled: false),
  ModuleAccess(name: 'Leave Requests', description: 'Access to personal leave requests.', enabled: false),
  ModuleAccess(name: 'Projects Module', description: 'Access to company projects, project boards, and milestones.', enabled: true),
  ModuleAccess(name: 'Renewals Module', description: 'Access to track hosting, domain, and mail renewals.', enabled: true),
  ModuleAccess(name: 'Reports Module', description: 'Access to executive financial, operational, and audit reports.', enabled: true),
  ModuleAccess(name: 'Audit Trail', description: 'Access to system-wide audit logs and histories.', enabled: false),
  ModuleAccess(name: 'Roles & Access', description: 'Access to roles and permissions management.', enabled: false),
  ModuleAccess(name: 'Super Admin Module', description: 'Full system access and platform-wide configurations.', enabled: false),
  ModuleAccess(name: 'Roles & Access Module', description: 'Manage dynamic workspace roles and access control configurations.', enabled: false),
  ModuleAccess(name: 'Support Desk Module', description: 'Access to internal support requests and system feedback.', enabled: false),
  ModuleAccess(name: 'Tasks Module', description: 'Access to standard task lists and collaborative work boards.', enabled: true),
  ModuleAccess(name: 'My Timesheet Module', description: 'Access to personal timesheet logs and work session records.', enabled: false),
  ModuleAccess(name: 'Team Timesheets Module', description: 'Access to review and verify team timesheet entries.', enabled: true),
  ModuleAccess(name: 'Time Monitor Module', description: 'Access to real-time user time monitoring and desktop activity.', enabled: true),
];

Map<String, List<Permission>> _buildAdminPermissions() => {
  'Admin Actions': [
    Permission(id: 'a1', name: 'Manage Organization Roster', description: 'Invite users, assign roles, and handle team structures.', enabled: true),
    Permission(id: 'a2', name: 'Manage Company Settings', description: 'Update profile settings, brand logos, and systems configs.', enabled: true),
    Permission(id: 'a3', name: 'Manage Time Desk Settings', description: 'Configure work session limits, break cycles, and screenshot frequency.', enabled: true),
  ],
  'Billing Actions': [
    Permission(id: 'b1', name: 'Manage Payments', description: 'Record and verify payments.', enabled: true),
    Permission(id: 'b2', name: 'Manage Asset Renewals', description: 'Track and update dynamic asset or subscription renewals.', enabled: true),
    Permission(id: 'b3', name: 'Record Payments', description: 'Log client payments and reconcile ledger files.', enabled: true),
    Permission(id: 'b4', name: 'Delete Invoices', description: 'Delete, void, or cancel generated invoices.', enabled: true),
    Permission(id: 'b5', name: 'View Financials', description: 'Ability to view invoices, financials, and transaction histories.', enabled: true),
    Permission(id: 'b6', name: 'Create Invoices', description: 'Generate client invoices and configure rates.', enabled: true),
    Permission(id: 'b7', name: 'Create Invoice', description: 'Generate client invoices.', enabled: true),
  ],
  'Client Onboarding Actions': [
    Permission(id: 'co1', name: 'View Submissions', description: 'Ability to review form submissions.', enabled: true),
    Permission(id: 'co2', name: 'Manage Forms', description: 'Create and edit dynamic intake forms.', enabled: true),
    Permission(id: 'co3', name: 'View Forms', description: 'Access form templates and submissions.', enabled: true),
    Permission(id: 'co4', name: 'Assign Form Submissions', description: 'Delegate incoming onboarding files to operational departments.', enabled: true),
    Permission(id: 'co5', name: 'Manage Submissions', description: 'Review and process form submissions.', enabled: true),
    Permission(id: 'co6', name: 'Edit Form Fields & Logic', description: 'Ability to design sections, modify fields, and add conditional logic.', enabled: true),
    Permission(id: 'co7', name: 'Create Forms', description: 'Ability to build new dynamic forms.', enabled: true),
    Permission(id: 'co8', name: 'Submit Onboarding Requests', description: 'Ability to fill out client-facing request forms.', enabled: true),
  ],
  'CRM Actions': [
    Permission(id: 'c1', name: 'Edit Lead', description: 'Ability to modify existing lead information.', enabled: true),
    Permission(id: 'c2', name: 'View Leads & Proposals', description: 'Ability to view the lead lists, pipeline, and proposals.', enabled: true),
    Permission(id: 'c3', name: 'Create Lead', description: 'Ability to add new leads into the sales funnel.', enabled: true),
    Permission(id: 'c4', name: 'Delete Lead', description: 'Permanently remove leads from the system.', enabled: true),
    Permission(id: 'c5', name: 'Manage Clients', description: 'Convert leads to clients and update active customer directories.', enabled: true),
    Permission(id: 'c6', name: 'Manage Proposals', description: 'Create, send, and edit business proposals.', enabled: true),
    Permission(id: 'c7', name: 'View Client Statements', description: 'Access client billing statements.', enabled: true),
  ],
  'Documents Actions': [
    Permission(id: 'd1', name: 'View Documents', description: 'Access to the document vault and files.', enabled: false),
    Permission(id: 'd2', name: 'Delete Documents', description: 'Remove files from the vault.', enabled: false),
    Permission(id: 'd3', name: 'Upload Documents', description: 'Upload new files to the vault.', enabled: false),
  ],
  'HR Actions': [
    Permission(id: 'h1', name: 'Approve/Reject Leave', description: 'Approve or deny employee paid time off (PTO) requests.', enabled: true),
    Permission(id: 'h2', name: 'View Own Leaves', description: 'Allows employee to see their leave history.', enabled: true),
    Permission(id: 'h3', name: 'Manage Approvals', description: 'Allows HR/Admin to approve or reject leaves.', enabled: true),
    Permission(id: 'h4', name: 'Manage Policies', description: 'Allows HR/Admin to configure leave types and rules.', enabled: true),
    Permission(id: 'h5', name: 'View HR Directory', description: 'Access the employee rosters, profiles, and hierarchy charts.', enabled: true),
    Permission(id: 'h6', name: 'Manage Attendance', description: 'View and modify team work hours and attendance cards.', enabled: true),
    Permission(id: 'h7', name: 'Create Leave Request', description: 'Request leaves of absence and vacation cycles.', enabled: true),
  ],
  'Marketing Actions': [
    Permission(id: 'm1', name: 'View Campaigns', description: 'Access to marketing campaigns and analytics.', enabled: false),
    Permission(id: 'm2', name: 'Manage Campaigns', description: 'Create and edit email/SMS marketing flows.', enabled: false),
  ],
  'Projects Actions': [
    Permission(id: 'p1', name: 'Manage Project Modules', description: 'Classify projects into modules and sub-modules.', enabled: true),
    Permission(id: 'p2', name: 'Manage Milestones', description: 'Create, edit, and delete project milestones.', enabled: true),
    Permission(id: 'p3', name: 'Manage Project Settings', description: 'Delete, archive, and manage high-level project parameters.', enabled: true),
    Permission(id: 'p4', name: 'Edit Project', description: 'Ability to edit project metadata and fields.', enabled: true),
    Permission(id: 'p5', name: 'View Projects', description: 'Ability to view active organization projects.', enabled: true),
    Permission(id: 'p6', name: 'Create Project', description: 'Ability to initialize new corporate projects.', enabled: true),
  ],
  'Renewals Actions': [
    Permission(id: 'r1', name: 'Send Reminders', description: 'Ability to trigger manual email reminders to clients.', enabled: true),
  ],
  'Reports Actions': [
    Permission(id: 'rp1', name: 'View Reports Directory', description: 'Access the analytics reports listing dashboard.', enabled: true),
    Permission(id: 'rp2', name: 'Run Audit & Security Reports', description: 'Inspect workspace audit logs, action histories, and records.', enabled: true),
    Permission(id: 'rp3', name: 'Run Financial Reports', description: 'Generate revenue, invoice, payment, and profitability statistics.', enabled: true),
    Permission(id: 'rp4', name: 'Run Performance Reports', description: 'Generate employee workloads, task delivery, and timesheet reports.', enabled: true),
  ],
  'Tasks Actions': [
    Permission(id: 't1', name: 'View Tasks', description: 'Ability to view and filter workspace tasks.', enabled: true),
    Permission(id: 't2', name: 'Manage All Tasks', description: 'Edit or delete tasks assigned to other team members.', enabled: true),
    Permission(id: 't3', name: 'Assign Tasks', description: 'Ability to assign tasks to active employees.', enabled: true),
    Permission(id: 't4', name: 'Create Task', description: 'Ability to add new tasks to project lists.', enabled: true),
  ],
};

// ─── Sample Roles ─────────────────────────────────────────────────────────────

List<RoleModel> buildSampleRoles() => [
  RoleModel(
    id: '1',
    name: 'Administrator',
    description: 'Full organization access and team management',
    permissionsEnabled: 61,
    totalPermissions: 77,
    activeUsers: [ActiveUser('S', Colors.indigo)],
    isSystem: true,
    shieldColor: const Color(0xFF0EA5E9),
    permissionGroups: _buildAdminPermissions(),
    moduleAccesses: _buildAdminModules(),
  ),
  RoleModel(
    id: '2',
    name: 'Employee',
    description: 'Standard workspace access for operations',
    permissionsEnabled: 8,
    totalPermissions: 77,
    activeUsers: [
      ActiveUser('R', Colors.red),
      ActiveUser('F', Colors.purple),
      ActiveUser('H', Colors.teal),
    ],
    isSystem: true,
    shieldColor: const Color(0xFF0EA5E9),
    permissionGroups: {
      'HR Actions': [
        Permission(id: 'eh1', name: 'View Own Leaves', description: 'Allows employee to see their leave history.', enabled: true),
        Permission(id: 'eh2', name: 'Create Leave Request', description: 'Request leaves of absence and vacation cycles.', enabled: true),
      ],
      'Tasks Actions': [
        Permission(id: 'et1', name: 'View Tasks', description: 'Ability to view and filter workspace tasks.', enabled: true),
        Permission(id: 'et2', name: 'Create Task', description: 'Ability to add new tasks to project lists.', enabled: true),
      ],
    },
    moduleAccesses: [
      ModuleAccess(name: 'Dashboard Module', description: 'Access to main overview dashboard.', enabled: true),
      ModuleAccess(name: 'Tasks Module', description: 'Access to task lists.', enabled: true),
      ModuleAccess(name: 'Leave Requests', description: 'Access to personal leave requests.', enabled: true),
    ],
  ),
  RoleModel(
    id: '3',
    name: 'HR',
    description: 'Manage employee directory, attendance and leave',
    permissionsEnabled: 36,
    totalPermissions: 77,
    activeUsers: [
      ActiveUser('A', Colors.orange),
      ActiveUser('H', Colors.teal),
    ],
    isSystem: true,
    shieldColor: const Color(0xFF0EA5E9),
    permissionGroups: {
      'HR Actions': [
        Permission(id: 'hh1', name: 'Approve/Reject Leave', description: 'Approve or deny employee PTO requests.', enabled: true),
        Permission(id: 'hh2', name: 'Manage Approvals', description: 'Allows HR/Admin to approve or reject leaves.', enabled: true),
        Permission(id: 'hh3', name: 'View HR Directory', description: 'Access the employee rosters.', enabled: true),
        Permission(id: 'hh4', name: 'Manage Attendance', description: 'View and modify team work hours.', enabled: true),
      ],
    },
    moduleAccesses: [
      ModuleAccess(name: 'HR & Leave Module', description: 'Access to corporate HR.', enabled: true),
      ModuleAccess(name: 'Leave Approvals', description: 'Access to leave approvals dashboard.', enabled: true),
    ],
  ),
  RoleModel(
    id: '4',
    name: 'Sales',
    description: 'Manage Sales',
    permissionsEnabled: 29,
    totalPermissions: 77,
    activeUsers: [
      ActiveUser('T', Colors.blue),
      ActiveUser('R', Colors.red),
    ],
    isSystem: false,
    shieldColor: const Color(0xFF0EA5E9),
    permissionGroups: {
      'CRM Actions': [
        Permission(id: 'sc1', name: 'Edit Lead', description: 'Ability to modify existing lead information.', enabled: true),
        Permission(id: 'sc2', name: 'Create Lead', description: 'Ability to add new leads into the sales funnel.', enabled: true),
        Permission(id: 'sc3', name: 'View Leads & Proposals', description: 'Ability to view the lead lists.', enabled: true),
      ],
    },
    moduleAccesses: [
      ModuleAccess(name: 'CRM Module', description: 'Access to customer relations.', enabled: true),
      ModuleAccess(name: 'Dashboard Module', description: 'Access to main dashboard.', enabled: true),
    ],
  ),
  RoleModel(
    id: '5',
    name: 'Team Lead',
    description: 'No description provided.',
    permissionsEnabled: 40,
    totalPermissions: 77,
    activeUsers: [ActiveUser('C', Colors.green)],
    isSystem: false,
    shieldColor: const Color(0xFF0EA5E9),
    permissionGroups: {
      'Projects Actions': [
        Permission(id: 'tlp1', name: 'View Projects', description: 'Ability to view active organization projects.', enabled: true),
        Permission(id: 'tlp2', name: 'Edit Project', description: 'Ability to edit project metadata.', enabled: true),
        Permission(id: 'tlp3', name: 'Manage Milestones', description: 'Create, edit, and delete project milestones.', enabled: true),
      ],
      'Tasks Actions': [
        Permission(id: 'tlt1', name: 'View Tasks', description: 'Ability to view and filter workspace tasks.', enabled: true),
        Permission(id: 'tlt2', name: 'Assign Tasks', description: 'Ability to assign tasks to active employees.', enabled: true),
        Permission(id: 'tlt3', name: 'Manage All Tasks', description: 'Edit or delete tasks.', enabled: true),
      ],
    },
    moduleAccesses: [
      ModuleAccess(name: 'Projects Module', description: 'Access to company projects.', enabled: true),
      ModuleAccess(name: 'Tasks Module', description: 'Access to task lists.', enabled: true),
      ModuleAccess(name: 'Team Timesheets Module', description: 'Access to review team timesheet entries.', enabled: true),
    ],
  ),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────

class RolesAccessScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const RolesAccessScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<RolesAccessScreen> createState() => _RolesAccessScreenState();
}

class _RolesAccessScreenState extends State<RolesAccessScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late List<RoleModel> _roles;

  @override
  void initState() {
    super.initState();
    _roles = buildSampleRoles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RoleModel> get _filtered => _roles
      .where((r) =>
          _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (_) => _CreateRoleDialog(
        onCreated: (name, desc) {
          setState(() {
            _roles.add(RoleModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              description: desc.isEmpty ? 'No description provided.' : desc,
              permissionsEnabled: 0,
              totalPermissions: 77,
              activeUsers: [],
              isSystem: false,
              shieldColor: const Color(0xFF0EA5E9),
              permissionGroups: {},
              moduleAccesses: _buildAdminModules()
                  .map((m) => ModuleAccess(
                        name: m.name,
                        description: m.description,
                        enabled: false,
                      ))
                  .toList(),
            ));
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role "$name" created successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  void _showRoleOptions(RoleModel role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleOptionsSheet(
        role: role,
        onConfigure: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ConfigureRoleScreen(role: role),
            ),
          );
        },
        onDelete: role.isSystem
            ? null
            : () {
                Navigator.pop(context);
                setState(() => _roles.removeWhere((r) => r.id == role.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role "${role.name}" deleted'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
          'Roles & Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24, color: Color(0xFF0EA5E9)),
            onPressed: _showCreateRoleDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define enterprise roles, assign permissions, and control dynamic module visibility.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search roles by name or description...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats bar
          _StatsBar(roles: _roles),
          // Roles grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text('No roles found',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14)),
                      ],
                    ),
                  )
                : isTablet
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: ((w - 32 - 14) / 2) / 180.0,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _RoleCard(
                          role: filtered[i],
                          onMore: () => _showRoleOptions(filtered[i]),
                          onConfigure: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _ConfigureRoleScreen(role: filtered[i]),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _RoleCard(
                          role: filtered[i],
                          onMore: () => _showRoleOptions(filtered[i]),
                          onConfigure: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _ConfigureRoleScreen(role: filtered[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: _showCreateRoleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<RoleModel> roles;
  const _StatsBar({required this.roles});

  @override
  Widget build(BuildContext context) {
    final systemRoles = roles.where((r) => r.isSystem).length;
    final customRoles = roles.where((r) => !r.isSystem).length;
    final totalUsers =
        roles.fold<int>(0, (s, r) => s + r.activeUsers.length);
    final w = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          _StatItem(label: 'Total Roles', value: '${roles.length}',
              color: const Color(0xFF0EA5E9)),
          _vDivider(w < 360 ? 4 : 8),
          _StatItem(label: 'System', value: '$systemRoles',
              color: const Color(0xFF8B5CF6)),
          _vDivider(w < 360 ? 4 : 8),
          _StatItem(label: 'Custom', value: '$customRoles',
              color: const Color(0xFF10B981)),
          _vDivider(w < 360 ? 4 : 8),
          _StatItem(label: 'Total Users', value: '$totalUsers',
              color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _vDivider(double horizontalMargin) => Container(
      width: 1, height: 28, color: const Color(0xFFE2E8F0),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin));
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isCompact = w < 360;
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: isCompact ? 15 : 18, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        Text(label,
            style:
                TextStyle(fontSize: isCompact ? 8 : 10, color: const Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onMore;
  final VoidCallback onConfigure;
  const _RoleCard(
      {required this.role,
      required this.onMore,
      required this.onConfigure});

  Color get _permColor {
    final pct = role.permissionsEnabled / role.totalPermissions;
    if (pct >= 0.7) return const Color(0xFF0EA5E9);
    if (pct >= 0.4) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final pct = role.permissionsEnabled / role.totalPermissions;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 20, color: Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(role.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                // Permissions badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PERMISSIONS',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0EA5E9),
                            letterSpacing: 0.5)),
                    Text(
                      '${role.permissionsEnabled} / ${role.totalPermissions}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _permColor),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onMore,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_vert_rounded,
                        size: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFF1F5F9),
                color: _permColor,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Users row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${role.activeUsers.length} Active User${role.activeUsers.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: role.isSystem
                        ? const Color(0xFFE0F2FE)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role.isSystem ? 'SYSTEM' : 'CUSTOM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: role.isSystem
                          ? const Color(0xFF0369A1)
                          : const Color(0xFF059669),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Avatar row
          if (role.activeUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: role.activeUsers
                    .take(5)
                    .map((u) => Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: u.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(u.initial,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: u.color)),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          // Configure button
          GestureDetector(
            onTap: onConfigure,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: const [
                  Text('Configure Permissions',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0EA5E9))),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Color(0xFF0EA5E9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role Options Sheet ───────────────────────────────────────────────────────

class _RoleOptionsSheet extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onConfigure;
  final VoidCallback? onDelete;
  const _RoleOptionsSheet(
      {required this.role,
      required this.onConfigure,
      this.onDelete});

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
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(role.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
            ),
          ),
          const SizedBox(height: 8),
          _SheetOption(
            icon: Icons.settings_outlined,
            label: 'Configure Permissions',
            onTap: onConfigure,
          ),
          _SheetOption(
            icon: Icons.people_outline_rounded,
            label: 'Manage Users',
            onTap: () => Navigator.pop(context),
          ),
          _SheetOption(
            icon: Icons.copy_outlined,
            label: 'Duplicate Role',
            onTap: () => Navigator.pop(context),
          ),
          if (onDelete != null)
            _SheetOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Role',
              labelColor: const Color(0xFFEF4444),
              iconColor: const Color(0xFFEF4444),
              onTap: onDelete!,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: Color(0xFFCBD5E1)),
                  const SizedBox(width: 8),
                  const Text('System roles cannot be deleted',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  const _SheetOption(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.labelColor,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon,
          size: 20, color: iconColor ?? const Color(0xFF475569)),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor ?? const Color(0xFF1E293B))),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 18, color: Color(0xFFCBD5E1)),
    );
  }
}

// ─── Create Role Dialog ───────────────────────────────────────────────────────

class _CreateRoleDialog extends StatefulWidget {
  final Function(String name, String desc) onCreated;
  const _CreateRoleDialog({required this.onCreated});

  @override
  State<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<_CreateRoleDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Create Enterprise Role',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B))),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Define a new role. You can configure granular permissions after creation.',
              style:
                  TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text('Role Name',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: _inputDec('e.g. Project Manager'),
            ),
            const SizedBox(height: 14),
            const Text('Description',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration:
                  _inputDec('Explain the responsibilities of this role...'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 14)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.trim().isNotEmpty) {
                      widget.onCreated(
                          _nameCtrl.text.trim(), _descCtrl.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Create Role',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      );
}

// ─── Configure Role Screen ────────────────────────────────────────────────────

class _ConfigureRoleScreen extends StatefulWidget {
  final RoleModel role;
  const _ConfigureRoleScreen({required this.role});

  @override
  State<_ConfigureRoleScreen> createState() =>
      _ConfigureRoleScreenState();
}

class _ConfigureRoleScreenState extends State<_ConfigureRoleScreen> {
  late List<ModuleAccess> _modules;
  late Map<String, List<Permission>> _groups;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    // Deep copy
    _modules = widget.role.moduleAccesses
        .map((m) => ModuleAccess(
            name: m.name, description: m.description, enabled: m.enabled))
        .toList();
    _groups = Map.fromEntries(
      widget.role.permissionGroups.entries.map((e) => MapEntry(
        e.key,
        e.value
            .map((p) => Permission(
                id: p.id,
                name: p.name,
                description: p.description,
                enabled: p.enabled))
            .toList(),
      )),
    );
    // If no permission groups defined, build from admin template
    if (_groups.isEmpty) {
      _groups = Map.fromEntries(
        _buildAdminPermissions().entries.map((e) => MapEntry(
          e.key,
          e.value
              .map((p) => Permission(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  enabled: false))
              .toList(),
        )),
      );
    }
  }

  int get _enabledCount => _groups.values
      .fold<int>(0, (s, list) => s + list.where((p) => p.enabled).length);

  int get _totalCount =>
      _groups.values.fold<int>(0, (s, list) => s + list.length);

  int get _enabledModules => _modules.where((m) => m.enabled).length;

  List<String> get _visibleModuleNames =>
      _modules.where((m) => m.enabled).map((m) => m.name).toList();

  void _selectAll() {
    setState(() {
      for (final list in _groups.values) {
        for (final p in list) {
          p.enabled = true;
        }
      }
      for (final m in _modules) {
        m.enabled = true;
      }
    });
  }

  void _revokeAll() {
    setState(() {
      for (final list in _groups.values) {
        for (final p in list) {
          p.enabled = false;
        }
      }
      for (final m in _modules) {
        m.enabled = false;
      }
    });
  }

  int _groupEnabled(List<Permission> perms) =>
      perms.where((p) => p.enabled).length;

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure: ${widget.role.name}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _showPreview = !_showPreview);
            },
            child: Text(
              _showPreview ? 'Hide Preview' : 'Preview',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF0EA5E9)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuration saved successfully'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0EA5E9))),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Define granular access rights and module visibility. Changes reflect instantly for all assigned users.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Workspace Preview (collapsible)
            if (_showPreview) ...[
              _WorkspacePreviewCard(
                visibleModules: _visibleModuleNames,
                enabledCount: _enabledCount,
                totalCount: _totalCount,
                onSelectAll: _selectAll,
                onRevokeAll: _revokeAll,
              ),
              const SizedBox(height: 16),
            ],

            // Select/Revoke buttons (always visible)
            if (!_showPreview)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: Color(0xFF10B981)),
                      label: const Text('Select All Access',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _revokeAll,
                      icon: const Icon(Icons.cancel_outlined,
                          size: 14, color: Color(0xFFEF4444)),
                      label: const Text('Revoke All Access',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        backgroundColor: const Color(0xFFFFF5F5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Section 1: Module Access
            _SectionHeader(
              number: '1',
              title: 'MODULE ACCESS (SIDEBAR VISIBILITY)',
            ),
            const SizedBox(height: 12),
            ..._buildModuleGrid(),

            const SizedBox(height: 24),

            // Section 2: Granular Actions
            _SectionHeader(
              number: '2',
              title: 'GRANULAR ACTIONS (FEATURE RIGHTS)',
            ),
            const SizedBox(height: 12),
            ..._groups.entries.map((e) => _PermissionGroup(
                  title: e.key,
                  permissions: e.value,
                  enabledCount: _groupEnabled(e.value),
                  onToggle: (perm) =>
                      setState(() => perm.enabled = !perm.enabled),
                  onToggleGroup: (enabled) {
                    setState(() {
                      for (final p in e.value) {
                        p.enabled = enabled;
                      }
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleGrid() {
    final widgets = <Widget>[];
    for (int i = 0; i < _modules.length; i += 2) {
      widgets.add(
        Row(
          children: [
            Expanded(
                child: _ModuleToggleCard(
                    module: _modules[i],
                    onToggle: () =>
                        setState(() => _modules[i].enabled = !_modules[i].enabled))),
            const SizedBox(width: 10),
            i + 1 < _modules.length
                ? Expanded(
                    child: _ModuleToggleCard(
                        module: _modules[i + 1],
                        onToggle: () => setState(() =>
                            _modules[i + 1].enabled =
                                !_modules[i + 1].enabled)))
                : const Expanded(child: SizedBox()),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(number,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
              letterSpacing: 0.4),
        ),
      ],
    );
  }
}

// ─── Module Toggle Card ───────────────────────────────────────────────────────

class _ModuleToggleCard extends StatelessWidget {
  final ModuleAccess module;
  final VoidCallback onToggle;
  const _ModuleToggleCard(
      {required this.module, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: module.enabled
              ? const Color(0xFFEFF6FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: module.enabled
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: module.enabled
                    ? const Color(0xFF0EA5E9)
                    : Colors.transparent,
                border: module.enabled
                    ? null
                    : Border.all(
                        color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: module.enabled
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: module.enabled
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.description,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission Group ─────────────────────────────────────────────────────────

class _PermissionGroup extends StatefulWidget {
  final String title;
  final List<Permission> permissions;
  final int enabledCount;
  final Function(Permission) onToggle;
  final Function(bool) onToggleGroup;
  const _PermissionGroup({
    required this.title,
    required this.permissions,
    required this.enabledCount,
    required this.onToggle,
    required this.onToggleGroup,
  });

  @override
  State<_PermissionGroup> createState() => _PermissionGroupState();
}

class _PermissionGroupState extends State<_PermissionGroup> {
  bool _expanded = true;

  bool get _allEnabled =>
      widget.permissions.every((p) => p.enabled);

  @override
  Widget build(BuildContext context) {
    final allEnabled = _allEnabled;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          // Group header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        widget.onToggleGroup(!allEnabled),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: allEnabled
                            ? const Color(0xFF0EA5E9)
                            : Colors.transparent,
                        border: allEnabled
                            ? null
                            : Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5),
                      ),
                      child: allEnabled
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.4),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.enabledCount ==
                              widget.permissions.length
                          ? const Color(0xFFD1FAE5)
                          : widget.enabledCount == 0
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.enabledCount} / ${widget.permissions.length} ENABLED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.enabledCount ==
                                widget.permissions.length
                            ? const Color(0xFF059669)
                            : widget.enabledCount == 0
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            // Permissions grid
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (int i = 0;
                      i < widget.permissions.length;
                      i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PermissionTile(
                              perm: widget.permissions[i],
                              onToggle: () => widget
                                  .onToggle(widget.permissions[i]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          i + 1 < widget.permissions.length
                              ? Expanded(
                                  child: _PermissionTile(
                                    perm: widget.permissions[i + 1],
                                    onToggle: () => widget.onToggle(
                                        widget.permissions[i + 1]),
                                  ),
                                )
                              : const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Permission Tile ──────────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  final Permission perm;
  final VoidCallback onToggle;
  const _PermissionTile({required this.perm, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: perm.enabled
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: perm.enabled
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: perm.enabled
                    ? const Color(0xFF0EA5E9)
                    : Colors.transparent,
                border: perm.enabled
                    ? null
                    : Border.all(
                        color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: perm.enabled
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perm.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: perm.enabled
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perm.description,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Workspace Preview Card ───────────────────────────────────────────────────

class _WorkspacePreviewCard extends StatelessWidget {
  final List<String> visibleModules;
  final int enabledCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onRevokeAll;
  const _WorkspacePreviewCard({
    required this.visibleModules,
    required this.enabledCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onRevokeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 16, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 6),
              const Text('WORKSPACE PREVIEW',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0EA5E9),
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('What users with this role will see',
              style:
                  TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          const Text('VISIBLE MODULES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          visibleModules.isEmpty
              ? const Text('No modules visible',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFCBD5E1)))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visibleModules
                      .take(12)
                      .map((m) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                  letterSpacing: 0.3),
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PERMISSIONS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8))),
              Text('$enabledCount / $totalCount',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? enabledCount / totalCount : 0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF0EA5E9),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelectAll,
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 13, color: Color(0xFF10B981)),
                  label: const Text('Select All',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRevokeAll,
                  icon: const Icon(Icons.cancel_outlined,
                      size: 13, color: Color(0xFFEF4444)),
                  label: const Text('Revoke All',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFFF5F5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}