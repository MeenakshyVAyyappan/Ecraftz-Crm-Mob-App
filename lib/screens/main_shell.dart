import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'crm_leads_page.dart';
import 'active_clients_screen.dart';
import 'client_onboarding_screen.dart';
import 'project_screen.dart';
import 'tasks_screen.dart';
import 'teams_screen.dart';
import 'billing_invoice.dart';
import 'asset_renewal.dart';

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

      default:
        return DashboardScreen(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
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
  }
}
