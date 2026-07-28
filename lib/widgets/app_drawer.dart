import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/branch/branch_cubit.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 270,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.bgSidebarDark
          : AppTheme.bgSidebar,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavItem(1, Icons.people_alt_outlined, 'CRM Leads'),
                  _buildNavItem(2, Icons.person_outline_rounded, 'Active Clients'),
                  _buildNavItem(3, Icons.how_to_reg_outlined, 'Client Onboarding'),
                  _buildNavItem(4, Icons.folder_outlined, 'Projects'),
                  _buildNavItem(5, Icons.check_circle_outline_rounded, 'Tasks'),
                  _buildNavItem(6, Icons.groups_outlined, 'Teams'),
                  _buildNavItem(7, Icons.receipt_long_outlined, 'Billing'),
                  _buildNavItem(21, Icons.post_add_outlined, 'Create Invoices'),
                  _buildNavItem(8, Icons.autorenew_rounded, 'Asset Renewals'),
                  _buildNavItem(9, Icons.description_outlined, 'Client Statements'),
                  _buildNavItem(10, Icons.calendar_month_outlined, 'Scheduler'),
                  _buildNavItem(19, Icons.event_available_outlined, 'Meeting Scheduler'),
                  _buildNavItem(18, Icons.rate_review_outlined, 'Client Feedback'),
                  _buildNavItem(11, Icons.analytics_outlined, 'Reports'),
                  _buildNavItem(12, Icons.access_time_rounded, 'Team Timesheets'),
                  _buildNavItem(13, Icons.event_busy_outlined, 'Leave Approvals'),
                  _buildNavItem(14, Icons.manage_accounts_outlined, 'Roles & Access'),
                  const SizedBox(height: 8),
                  _buildSectionDivider('ADMINISTRATION'),
                  _buildNavItem(15, Icons.admin_panel_settings_outlined, 'Super Admin'),
                  _buildNavItem(16, Icons.group_work_outlined, 'HR & Payroll'),
                  _buildNavItem(17, Icons.monitor_heart_outlined, 'Time Monitoring'),
                  _buildNavItem(20, Icons.developer_board_outlined, 'Attendance Dashboard'),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/ecraftzlogolight.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          // Branch Switcher in drawer
          BlocBuilder<BranchCubit, BranchState>(
            builder: (context, branchState) {
              return GestureDetector(
                onTap: () => _showBranchPicker(context, branchState),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _branchIcon(branchState.selectedBranch),
                        size: 14,
                        color: _branchAccent(branchState.selectedBranch),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          branchState.selectedBranch.displayName,
                          style: TextStyle(
                            color: _branchAccent(branchState.selectedBranch),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _branchAccent(BranchFilter filter) {
    switch (filter) {
      case BranchFilter.allBranches: return const Color(0xFF8892B0);
      case BranchFilter.calicut: return const Color(0xFF3B82F6);
      case BranchFilter.dubai: return const Color(0xFFF59E0B);
    }
  }

  IconData _branchIcon(BranchFilter filter) {
    switch (filter) {
      case BranchFilter.allBranches: return Icons.public_rounded;
      case BranchFilter.calicut: return Icons.location_on_rounded;
      case BranchFilter.dubai: return Icons.business_rounded;
    }
  }

  void _showBranchPicker(BuildContext context, BranchState branchState) {
    final cubit = context.read<BranchCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _DrawerBranchSheet(
          current: branchState.selectedBranch,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.sidebarAccent.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.sidebarAccent.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppTheme.sidebarAccent
                      : const Color(0xFF8892B0),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF8892B0),
                    fontSize: 13.5,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildSectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
            child: const Text('SA',
                style: TextStyle(
                    color: AppTheme.sidebarAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Super Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('Administrator',
                    style: TextStyle(color: Color(0xFF8892B0), fontSize: 11)),
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
}

// ─── DRAWER BRANCH SHEET ─────────────────────────────────────────────────────

class _DrawerBranchSheet extends StatelessWidget {
  final BranchFilter current;
  final bool isDark;

  const _DrawerBranchSheet({required this.current, required this.isDark});

  Color _accent(BranchFilter f) {
    switch (f) {
      case BranchFilter.allBranches: return const Color(0xFF6B7280);
      case BranchFilter.calicut: return const Color(0xFF0A84FF);
      case BranchFilter.dubai: return const Color(0xFFF59E0B);
    }
  }

  IconData _icon(BranchFilter f) {
    switch (f) {
      case BranchFilter.allBranches: return Icons.public_rounded;
      case BranchFilter.calicut: return Icons.location_on_rounded;
      case BranchFilter.dubai: return Icons.business_rounded;
    }
  }

  String _subtitle(BranchFilter f) {
    switch (f) {
      case BranchFilter.allBranches: return 'Show data from all branches combined';
      case BranchFilter.calicut: return 'Kozhikode, Kerala — Head Office';
      case BranchFilter.dubai: return 'Dubai, UAE — International Branch';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF101B2B) : Colors.white;
    final border = isDark ? const Color(0xFF1E2E42) : const Color(0xFFE8EDF5);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 18, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7A99)),
                const SizedBox(width: 8),
                Text('Switch Branch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0D1B2A))),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          const SizedBox(height: 8),
          ...BranchFilter.values.map((filter) {
            final isSelected = filter == current;
            final accent = _accent(filter);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.read<BranchCubit>().selectBranch(filter);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withOpacity(isDark ? 0.15 : 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? accent.withOpacity(0.3) : Colors.transparent, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: accent.withOpacity(isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_icon(filter), color: accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(filter.displayName, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? accent : (isDark ? Colors.white : const Color(0xFF0D1B2A)))),
                            const SizedBox(height: 2),
                            Text(_subtitle(filter), style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7A99))),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: accent, size: 20)
                      else
                        Icon(Icons.radio_button_unchecked_rounded, color: isDark ? const Color(0xFF596780) : const Color(0xFFADB5C9), size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
