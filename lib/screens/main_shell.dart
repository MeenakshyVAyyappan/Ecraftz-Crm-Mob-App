import 'package:flutter/material.dart';
import 'Super_Admin/dashboard_screen.dart';
import 'Super_Admin/crm_leads_page.dart';
import 'Super_Admin/active_clients_screen.dart';
import 'Super_Admin/client_onboarding_screen.dart';
import 'Super_Admin/project_screen.dart';
import 'Super_Admin/tasks_screen.dart';
import 'Super_Admin/teams_screen.dart';
import 'Super_Admin/billing_invoice.dart';
import 'Super_Admin/asset_renewal.dart';
import 'Super_Admin/scheduler_screen.dart';
import 'Super_Admin/client_statement_screen.dart';
import 'Super_Admin/reports_screen.dart';
import 'Super_Admin/team_timesheets.dart';
import 'Super_Admin/leave_approval.dart';
import 'Super_Admin/roles_and_access.dart';
import 'Super_Admin/time_monitoring_screen.dart';
import 'Super_Admin/hr_and_payroll.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 1:
        return CRMLeadsPage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 2:
        return ActiveClientsPage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 3:
        return ClientOnboardingPage(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 4:
        return ProjectsPage(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 5:
        return TasksPage(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 6:
          return TeamsPage(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );    
      case 7:
        return BillingPage(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );  
      case 8:
        return AssetRenewalsPage(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );  
      case 9:
        return ClientStatementsScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 10:
        return SchedulerScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 11:
        return ReportsScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 12:
        return TeamTimesheetsScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 13:
        return LeaveApprovalsScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 14:
        return RolesAccessScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 15:
        return RolesAccessScreen(  
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 16:
        return HRPayrollScreen(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
      case 17:
        return TimeMonitorScreen(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );

      default:
        return DashboardScreen(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;
    
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _buildPage(_selectedIndex),
      ),
    );
    
    if (isDesktop) {
      return content;
    }

    int bottomNavIndex = 0;
    switch (_selectedIndex) {
      case 0: bottomNavIndex = 0; break;
      case 2: bottomNavIndex = 1; break;
      case 4: bottomNavIndex = 2; break;
      case 5: bottomNavIndex = 3; break;
      case 16: bottomNavIndex = 4; break;
      default: bottomNavIndex = 0;
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavIndex,
        onTap: (index) {
          int newIndex = 0;
          switch (index) {
            case 0: newIndex = 0; break;
            case 1: newIndex = 2; break; // Active Clients
            case 2: newIndex = 4; break; // Projects
            case 3: newIndex = 5; break; // Tasks
            case 4: newIndex = 16; break; // HR
          }
          if (_selectedIndex != newIndex) {
            _onItemSelected(newIndex);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: const Color(0xFF0EA5E9),
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8892B0) : const Color(0xFF6B7A99),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 20), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined, size: 20), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_rounded, size: 20), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined, size: 20), label: 'HR'),
        ],
      ),
    );
  }
}
