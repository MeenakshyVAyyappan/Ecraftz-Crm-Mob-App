import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/rbac_models.dart';
import '../../blocs/rbac/rbac_cubit.dart';
import '../../blocs/rbac/rbac_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

class RolePermissionEditorScreen extends StatefulWidget {
  final RoleModel role;
  final String organizationId;

  const RolePermissionEditorScreen({
    super.key,
    required this.role,
    required this.organizationId,
  });

  @override
  State<RolePermissionEditorScreen> createState() =>
      _RolePermissionEditorScreenState();
}

class _RolePermissionEditorScreenState
    extends State<RolePermissionEditorScreen> {
  final Set<String> _selectedPermIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rbacState = context.read<RbacCubit>().state;
    for (var perm in rbacState.permissions) {
      if (widget.role.permissions.contains(perm.code)) {
        _selectedPermIds.add(perm.id);
      }
    }
  }

  void _selectAllAccess(List<PermissionModel> allPermissions) {
    setState(() {
      _selectedPermIds.clear();
      for (var p in allPermissions) {
        _selectedPermIds.add(p.id);
      }
    });
  }

  void _revokeAllAccess() {
    setState(() {
      _selectedPermIds.clear();
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    final rbac = context.read<RbacCubit>();
    try {
      await rbac.updateRolePermissions(
        widget.role.id,
        _selectedPermIds.toList(),
        widget.organizationId,
      );
      if (mounted) {
        AppSnackBar.showSuccess(
            context, 'Permissions for "${widget.role.name}" updated successfully.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
            context, 'Failed to update permissions: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacCubit, RbacState>(
      builder: (context, rbacState) {
        final allPerms = rbacState.permissions;
        final modules = allPerms.where((p) => p.type == 'module').toList();
        final actions = allPerms.where((p) => p.type == 'action').toList();

        // Group actions by module name
        final Map<String, List<PermissionModel>> groupedActions = {};
        for (var act in actions) {
          groupedActions.putIfAbsent(act.module, () => []).add(act);
        }

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    final totalPermCount = allPerms.length;
    final selectedCount = _selectedPermIds.length;

    // List of active visible module names for workspace preview
    final visibleModuleNames = modules
        .where((m) => _selectedPermIds.contains(m.id))
        .map((m) => m.name.replaceAll(' Module', '').toUpperCase())
        .toList();

    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Role: ${widget.role.name}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              'Define granular access rights and module visibility.',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
            label: const Text('< Back to Roles',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _isSaving ? null : _savePermissions,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Configuration',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: border, height: 1),
        ),
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Workspace Preview
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildWorkspacePreview(
                      context,
                      visibleModuleNames,
                      selectedCount,
                      totalPermCount,
                      allPerms,
                    ),
                  ),
                ),
                Container(width: 1, color: border),
                // Main Right Area: Modules & Actions Matrix
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildPermissionsMatrix(
                      context,
                      modules,
                      groupedActions,
                      textPrimary,
                      textSecondary,
                      border,
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildWorkspacePreview(
                    context,
                    visibleModuleNames,
                    selectedCount,
                    totalPermCount,
                    allPerms,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionsMatrix(
                    context,
                    modules,
                    groupedActions,
                    textPrimary,
                    textSecondary,
                    border,
                  ),
                ],
              ),
            ),
    );
  },
);
  }

  Widget _buildWorkspacePreview(
    BuildContext context,
    List<String> visibleModules,
    int selectedCount,
    int totalCount,
    List<PermissionModel> allPermissions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, size: 18, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              Text(
                'WORKSPACE PREVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'What users with this role will see',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'VISIBLE MODULES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMutedOf(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          visibleModules.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text('No modules selected',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visibleModules.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                      ),
                      child: Text(
                        m,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Divider(color: border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL PERMISSIONS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMutedOf(context),
                      letterSpacing: 0.5)),
              Text('$selectedCount / $totalCount',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0EA5E9))),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _selectAllAccess(allPermissions),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('SELECT ALL',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _revokeAllAccess,
                  icon: const Icon(Icons.highlight_off_rounded, size: 14),
                  label: const Text('REVOKE ALL',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsMatrix(
    BuildContext context,
    List<PermissionModel> modules,
    Map<String, List<PermissionModel>> groupedActions,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. MODULE ACCESS
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('1',
                  style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text(
              'MODULE ACCESS (SIDEBAR VISIBILITY)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio:
                MediaQuery.of(context).size.width > 700 ? 3.5 : 4.5,
          ),
          itemCount: modules.length,
          itemBuilder: (ctx, idx) {
            final m = modules[idx];
            final isChecked = _selectedPermIds.contains(m.id);
            return _buildPermissionTile(
              context: context,
              title: m.name,
              subtitle: m.description ?? 'Module navigation visibility',
              isChecked: isChecked,
              accentColor: const Color(0xFF0EA5E9),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedPermIds.add(m.id);
                  } else {
                    _selectedPermIds.remove(m.id);
                  }
                });
              },
            );
          },
        ),
        const SizedBox(height: 24),
        Divider(color: border, height: 1),
        const SizedBox(height: 24),
        // 2. GRANULAR ACTIONS
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('2',
                  style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text(
              'GRANULAR ACTIONS (FEATURE CAPABILITIES)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...groupedActions.entries.map((entry) {
          final groupName = entry.key;
          final actionList = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '$groupName Actions',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actionList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final act = actionList[idx];
                  final isChecked = _selectedPermIds.contains(act.id);
                  return _buildPermissionTile(
                    context: context,
                    title: act.name,
                    subtitle: act.description ?? '',
                    isChecked: isChecked,
                    accentColor: const Color(0xFFF59E0B),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPermIds.add(act.id);
                        } else {
                          _selectedPermIds.remove(act.id);
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPermissionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isChecked,
    required Color accentColor,
    required ValueChanged<bool?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked ? accentColor.withOpacity(isDark ? 0.15 : 0.05) : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isChecked ? accentColor.withOpacity(0.4) : border,
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isChecked ? FontWeight.w700 : FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
