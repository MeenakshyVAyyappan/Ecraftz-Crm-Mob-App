import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_snackbar.dart';
import '../../models/rbac_models.dart';
import '../../blocs/rbac/rbac_cubit.dart';
import '../../blocs/rbac/rbac_state.dart';
import '../../services/supabase_service.dart';
import 'role_permission_editor_screen.dart';

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
  String _orgId = '00000000-0000-0000-0000-000000000000';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseService.client
            .from('profiles')
            .select('organization_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && profile['organization_id'] != null) {
          _orgId = profile['organization_id'].toString();
        }
      } catch (e) {
        debugPrint('Org load error: $e');
      }
    }
    if (mounted) {
      context.read<RbacCubit>().loadRolesAndPermissions(_orgId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateRoleDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF0EA5E9)),
            SizedBox(width: 8),
            Text('Create Custom Role',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Role name is required' : null,
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  hintText: 'e.g. Content Lead, Sales Rep',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Briefly explain responsibilities of this role...',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                Navigator.pop(dlgCtx);
                try {
                  await context
                      .read<RbacCubit>()
                      .createRole(name, desc, _orgId);
                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                        context, 'Role "$name" created successfully.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(
                        context, 'Failed to create role: ${e.toString()}');
                  }
                }
              }
            },
            child: const Text('Create Role'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, RoleModel role) {
    final nameCtrl = TextEditingController(text: role.name);
    final descCtrl = TextEditingController(text: role.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFF0EA5E9)),
            SizedBox(width: 8),
            Text('Edit Role Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Role name is required' : null,
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                Navigator.pop(dlgCtx);
                try {
                  await context
                      .read<RbacCubit>()
                      .updateRoleDetails(role.id, name, desc, _orgId);
                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                        context, 'Role details updated successfully.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(
                        context, 'Failed to update role: ${e.toString()}');
                  }
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showUserAssignmentModal(BuildContext context, RoleModel role) async {
    final rbac = context.read<RbacCubit>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
      ),
    );

    try {
      final profiles = await rbac.fetchProfiles(_orgId);
      final assignedUserIds = await rbac.fetchAssignedUserIds(role.id);
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      final Set<String> currentAssigned = Set.from(assignedUserIds);

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetCtx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final cardBg = Theme.of(ctx).colorScheme.surface;
              final border = AppTheme.borderOf(ctx);
              final textPrimary = AppTheme.textPrimaryOf(ctx);
              final textSecondary = AppTheme.textSecondaryOf(ctx);

              return Container(
                height: MediaQuery.of(ctx).size.height * 0.75,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: border)),
                ),
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline,
                              color: Color(0xFF0EA5E9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Manage Assigned Users',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary)),
                                Text('Assign or remove team members from "${role.name}"',
                                    style: TextStyle(
                                        fontSize: 12, color: textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textSecondary),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: profiles.isEmpty
                          ? Center(
                              child: Text('No user profiles found',
                                  style: TextStyle(color: textSecondary)))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: profiles.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (itemCtx, i) {
                                final p = profiles[i];
                                final uId = p['id'].toString();
                                final isAssigned = currentAssigned.contains(uId);
                                final userName = p['full_name']?.toString() ??
                                    p['email']?.toString() ??
                                    'User';
                                final userEmail = p['email']?.toString() ?? '';

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? const Color(0xFF0EA5E9)
                                            .withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isAssigned
                                          ? const Color(0xFF0EA5E9)
                                              .withOpacity(0.3)
                                          : border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF0EA5E9)
                                            .withOpacity(0.2),
                                        radius: 18,
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                              color: Color(0xFF0EA5E9),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(userName,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: textPrimary)),
                                            Text(userEmail,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: textSecondary)),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: isAssigned,
                                        activeColor: const Color(0xFF0EA5E9),
                                        onChanged: (val) async {
                                          setSheetState(() {
                                            if (val) {
                                              currentAssigned.add(uId);
                                            } else {
                                              currentAssigned.remove(uId);
                                            }
                                          });

                                          try {
                                            if (val) {
                                              await rbac.assignUserToRole(
                                                  uId, role.id, _orgId);
                                            } else {
                                              await rbac.removeUserFromRole(
                                                  uId, role.id, _orgId);
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                'Role assignment error: $e');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator on error
        AppSnackBar.showError(context, 'Failed to fetch profiles: $e');
      }
    }
  }

  void _confirmDeleteRole(BuildContext context, RoleModel role) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Role'),
        content: Text(
            'Are you sure you want to delete the "${role.name}" role? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              try {
                await context
                    .read<RbacCubit>()
                    .deleteRole(role.id, _orgId);
                if (context.mounted) {
                  AppSnackBar.showSuccess(
                      context, 'Role "${role.name}" deleted successfully.');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.showError(
                      context, e.toString().replaceAll('Exception: ', ''));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRoleOptionsMenu(BuildContext context, RoleModel role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final cardBg = Theme.of(sheetCtx).colorScheme.surface;
        final border = AppTheme.borderOf(sheetCtx);
        final textPrimary = AppTheme.textPrimaryOf(sheetCtx);

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Text(
                role.name,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    const Icon(Icons.tune_rounded, color: Color(0xFF0EA5E9)),
                title: const Text('Configure Permissions'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _navigateToEditor(role);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.people_outline, color: Color(0xFF10B981)),
                title: const Text('Manage Assigned Users'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showUserAssignmentModal(context, role);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: Color(0xFFF59E0B)),
                title: const Text('Edit Role Details'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEditRoleDialog(context, role);
                },
              ),
              if (!role.isSystem)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text('Delete Role',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _confirmDeleteRole(context, role);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEditor(RoleModel role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RolePermissionEditorScreen(
          role: role,
          organizationId: _orgId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacCubit, RbacState>(
      builder: (context, rbacState) {
        final totalPermCount =
            rbacState.permissions.isNotEmpty ? rbacState.permissions.length : 61;

        final filtered = rbacState.roles.where((r) {
          final q = _searchQuery.toLowerCase().trim();
          if (q.isEmpty) return true;
          return r.name.toLowerCase().contains(q) ||
              (r.description?.toLowerCase().contains(q) ?? false);
        }).toList();

    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 650;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(
          'Roles & Access Control',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
          if (w >= 600)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => _showCreateRoleDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ Create Custom Role',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (w >= 600) const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Header description & search bar
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define enterprise roles, assign permissions, and control dynamic module visibility.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search roles by name or description...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: textSecondary),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                size: 16, color: textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.bgBaseDark
                        : const Color(0xFFF1F5F9),
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
          // Stats summary bar
          _StatsBar(roles: rbacState.roles),
          // Roles list / grid
          Expanded(
            child: rbacState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            Text('No matching roles found',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : isTablet
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio:
                                  ((w - 32 - 14) / 2) / 190.0,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _RoleCard(
                              role: filtered[i],
                              totalPermissions: totalPermCount,
                              onConfigure: () => _navigateToEditor(filtered[i]),
                              onMore: () =>
                                  _showRoleOptionsMenu(context, filtered[i]),
                              onManageUsers: () => _showUserAssignmentModal(
                                  context, filtered[i]),
                              onDelete: filtered[i].isSystem
                                  ? null
                                  : () => _confirmDeleteRole(
                                      context, filtered[i]),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (ctx, i) => _RoleCard(
                              role: filtered[i],
                              totalPermissions: totalPermCount,
                              onConfigure: () => _navigateToEditor(filtered[i]),
                              onMore: () =>
                                  _showRoleOptionsMenu(context, filtered[i]),
                              onManageUsers: () => _showUserAssignmentModal(
                                  context, filtered[i]),
                              onDelete: filtered[i].isSystem
                                  ? null
                                  : () => _confirmDeleteRole(
                                      context, filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: () => _showCreateRoleDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  },
);
  }
}

// ─── Stats Bar Widget ─────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<RoleModel> roles;

  const _StatsBar({required this.roles});

  @override
  Widget build(BuildContext context) {
    final systemRoles = roles.where((r) => r.isSystem).length;
    final customRoles = roles.where((r) => !r.isSystem).length;
    final totalUsers =
        roles.fold<int>(0, (s, r) => s + r.userCount);
    final w = MediaQuery.of(context).size.width;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);

    return Container(
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          _StatItem(
              label: 'Total Roles',
              value: '${roles.length}',
              color: const Color(0xFF0EA5E9)),
          _vDivider(border, w < 360 ? 4 : 8),
          _StatItem(
              label: 'System',
              value: '$systemRoles',
              color: const Color(0xFF8B5CF6)),
          _vDivider(border, w < 360 ? 4 : 8),
          _StatItem(
              label: 'Custom',
              value: '$customRoles',
              color: const Color(0xFF10B981)),
          _vDivider(border, w < 360 ? 4 : 8),
          _StatItem(
              label: 'Total Users',
              value: '$totalUsers',
              color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _vDivider(Color border, double horizontalMargin) => Container(
        width: 1,
        height: 28,
        color: border,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      );
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
                fontSize: isCompact ? 15 : 18,
                fontWeight: FontWeight.w700,
                color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        Text(label,
            style: TextStyle(
                fontSize: isCompact ? 8 : 10,
                color: AppTheme.textSecondaryOf(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Role Card Widget ─────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final int totalPermissions;
  final VoidCallback onConfigure;
  final VoidCallback onMore;
  final VoidCallback onManageUsers;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.role,
    required this.totalPermissions,
    required this.onConfigure,
    required this.onMore,
    required this.onManageUsers,
    this.onDelete,
  });

  Color _permColor(int enabled, int total) {
    final pct = total > 0 ? enabled / total : 0;
    if (pct >= 0.7) return const Color(0xFF0EA5E9);
    if (pct >= 0.3) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    final enabledCount = role.permissions.length;
    final permColor = _permColor(enabledCount, totalPermissions);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0EA5E9).withOpacity(0.15)
                        : const Color(0xFFE0F2FE),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              role.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: role.isSystem
                                  ? const Color(0xFF8B5CF6).withOpacity(0.12)
                                  : const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role.isSystem ? 'SYSTEM' : 'CUSTOM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: role.isSystem
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role.description != null && role.description!.isNotEmpty
                            ? role.description!
                            : 'No description provided.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Permissions Count Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'PERMISSIONS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$enabledCount / $totalPermissions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: permColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: textSecondary),
                  onPressed: onMore,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: border, height: 1),
          // Footer Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onManageUsers,
                    child: Row(
                      children: [
                        if (role.activeUsers.isNotEmpty)
                          SizedBox(
                            height: 22,
                            width: (role.activeUsers.length * 12 + 10).toDouble(),
                            child: Stack(
                              children: List.generate(role.activeUsers.length, (idx) {
                                final user = role.activeUsers[idx];
                                return Positioned(
                                  left: idx * 10.0,
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: user.color,
                                    child: Text(
                                      user.initial,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${role.userCount} Active User${role.userCount == 1 ? '' : 's'}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF0EA5E9),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onConfigure,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Configure Permissions',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Color(0xFF0EA5E9)),
                      ],
                    ),
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
