import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/signin.dart';

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
                  _buildNavItem(8, Icons.autorenew_rounded, 'Asset Renewals'),
                  _buildNavItem(9, Icons.description_outlined, 'Client Statements'),
                  _buildNavItem(10, Icons.calendar_month_outlined, 'Scheduler'),
                  _buildNavItem(11, Icons.analytics_outlined, 'Reports'),
                  _buildNavItem(12, Icons.access_time_rounded, 'Team Timesheets'),
                  _buildNavItem(13, Icons.event_busy_outlined, 'Leave Approvals'),
                  _buildNavItem(14, Icons.manage_accounts_outlined, 'Roles & Access'),
                  const SizedBox(height: 8),
                  _buildSectionDivider('ADMINISTRATION'),
                  _buildNavItem(15, Icons.admin_panel_settings_outlined, 'Super Admin'),
                  _buildNavItem(16, Icons.group_work_outlined, 'HR & Payroll'),
                  _buildNavItem(17, Icons.monitor_heart_outlined, 'Time Monitoring'),
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
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/ecraftzlogolight.png',
        height: 36,
        fit: BoxFit.contain,
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
