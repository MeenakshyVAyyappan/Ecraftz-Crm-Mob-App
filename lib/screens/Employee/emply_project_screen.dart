import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/project_model.dart';
import '../../services/supabase_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedStatus = 'All Status';
  int _viewMode = 0; // 0=kanban, 1=grid, 2=list
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<Project> _activeProjects = [];
  bool _isLoading = true;
  User? _currentUser;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      _currentUser = user;
      if (user != null) {
        final profileRows = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .limit(1);
        if (profileRows.isNotEmpty) {
          _profile = Map<String, dynamic>.from(profileRows.first as Map);
        }
      }
      await _fetchActiveProjects();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveProjects() async {
    try {
      if (_currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await SupabaseService.client.from('active_projects').select();
      
      final currentId = _currentUser!.id.toString().trim().toLowerCase();
      final currentFullName = _profile?['full_name']?.toString().trim().toLowerCase() ?? '';
      final currentEmail = _currentUser!.email?.toString().trim().toLowerCase() ?? '';

      bool containsValue(String source, String value) {
        return value.isNotEmpty && source.contains(value);
      }

      List<Project> loaded = [];
      for (var row in res as List) {
        final assignedRaw = (row['assigned_to'] ?? row['employee_name'] ?? row['employee'] ?? row['owner'] ?? '').toString().trim().toLowerCase();
        
        bool matchesOwner = true;
        if (assignedRaw.isNotEmpty) {
           matchesOwner = assignedRaw == currentId ||
                     assignedRaw == currentFullName ||
                     assignedRaw == currentEmail ||
                     containsValue(assignedRaw, currentFullName) ||
                     containsValue(assignedRaw, currentEmail);
        }

        if (matchesOwner) {
           loaded.add(Project(
             id: row['id']?.toString() ?? '',
             name: row['name']?.toString() ?? row['project_name']?.toString() ?? 'Unnamed Project',
             clientName: row['client_name']?.toString() ?? '',
             status: _parseStatus(row['status']),
             deadline: row['end_date']?.toString() ?? row['deadline']?.toString() ?? row['start_date']?.toString(),
           ));
        }
      }

      if (mounted) {
        setState(() {
          _activeProjects = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching active projects: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ProjectStatus _parseStatus(dynamic val) {
    if (val == null) return ProjectStatus.planning;
    final s = val.toString().toLowerCase().replaceAll('_', ' ');
    if (s.contains('progress')) return ProjectStatus.inProgress;
    if (s.contains('hold')) return ProjectStatus.onHold;
    if (s.contains('completed')) return ProjectStatus.completed;
    if (s.contains('cancel')) return ProjectStatus.cancelled;
    return ProjectStatus.planning;
  }

  Future<void> _updateProjectStatus(String projectId, ProjectStatus newStatus) async {
    String statusStr = 'planning';
    switch (newStatus) {
      case ProjectStatus.planning: statusStr = 'planning'; break;
      case ProjectStatus.inProgress: statusStr = 'in progress'; break;
      case ProjectStatus.onHold: statusStr = 'on hold'; break;
      case ProjectStatus.completed: statusStr = 'completed'; break;
      case ProjectStatus.cancelled: statusStr = 'cancelled'; break;
    }
    
    try {
      await SupabaseService.client
          .from('active_projects')
          .update({'status': statusStr})
          .eq('id', projectId);
      
      _fetchActiveProjects();
      
      if (mounted) {
        AppSnackBar.showCustom(context, 
          const SnackBar(content: Text('Project status updated successfully')),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        AppSnackBar.showCustom(context, 
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  void _showStatusUpdateMenu(BuildContext context, Project project, Offset position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: isDark ? AppTheme.bgCardDark : Colors.white,
      items: ProjectStatus.values.map((status) {
        return PopupMenuItem<ProjectStatus>(
          value: status,
          child: Text(
            status.label.toUpperCase(),
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    ).then((selectedStatus) {
      if (selectedStatus != null && selectedStatus != project.status) {
        _updateProjectStatus(project.id, selectedStatus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredProjects = _activeProjects.where((p) {
      // Apply search query
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // Apply status filter
      if (_selectedStatus == 'Active') {
        return p.status == ProjectStatus.inProgress ||
               p.status == ProjectStatus.planning ||
               p.status == ProjectStatus.onHold;
      } else if (_selectedStatus == 'Completed') {
        return p.status == ProjectStatus.completed;
      } else if (_selectedStatus == 'On Hold') {
        return p.status == ProjectStatus.onHold;
      }
      return true; // 'All Status'
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              _buildBreadcrumb(['Dashboard', 'Projects']),
              const SizedBox(height: 12),
              // Header
              Text('Assigned Projects',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              Text('Manage projects assigned to you.',
                  style: TextStyle(
                      fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
              const SizedBox(height: 16),
              // Active tab
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('MY PROJECTS',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              ),
              const SizedBox(height: 16),
              // Search + Filter + View
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2196F3), width: 1.5),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF596780) : Colors.grey[400],
                                  fontSize: 13),
                              prefixIcon: Icon(Icons.search,
                                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400],
                                  size: 18),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusDropdown(),
                        const SizedBox(width: 8),
                        _buildViewModeButtons(),
                      ],
                    ),
                    const Divider(height: 16),
                    filteredProjects.isEmpty
                        ? _buildEmptyState()
                        : _buildProjectsContent(filteredProjects),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildBreadcrumb(List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.key == 0)
              Icon(Icons.home_outlined,
                  size: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
            if (e.key > 0)
              Icon(Icons.chevron_right,
                  size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
            Text(e.value,
                style: TextStyle(
                    fontSize: 11,
                    color: isLast
                        ? const Color(0xFF2196F3)
                        : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus,
        isDense: true,
        underline: const SizedBox(),
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500),
        items: ['All Status', 'Active', 'Completed', 'On Hold']
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) =>
            setState(() => _selectedStatus = v ?? 'All Status'),
      ),
    );
  }

  Widget _buildViewModeButtons() {
    return Row(
      children: [
        _viewBtn(Icons.view_column_outlined, 0),
        _viewBtn(Icons.grid_view_outlined, 1),
        _viewBtn(Icons.format_list_bulleted, 2),
      ],
    );
  }

  Widget _viewBtn(IconData icon, int mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: _viewMode == mode
              ? const Color(0xFF2196F3).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: _viewMode == mode
                ? const Color(0xFF2196F3)
                : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined,
                color: Color(0xFF2196F3), size: 30),
          ),
          const SizedBox(height: 14),
          Text('No projects found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('You have no active projects assigned to you.',
              style: TextStyle(
                  fontSize: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildProjectsContent(List<Project> projects) {
    if (_viewMode == 2) return _buildListView(projects);
    if (_viewMode == 1) return _buildGridView(projects);
    return _buildKanbanView(projects);
  }

  Widget _buildListView(List<Project> projects) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _buildProjectListTile(projects[i]),
    );
  }

  Widget _buildGridView(List<Project> projects) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: projects.length,
      itemBuilder: (ctx, i) => _buildProjectGridCard(projects[i]),
    );
  }

  Widget _buildKanbanView(List<Project> projects) {
    return _buildListView(projects);
  }

  Widget _buildProjectListTile(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (details) {
        _showStatusUpdateMenu(context, project, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: const Color(0xFF2196F3),
                radius: 16,
                child: Text(
                    project.name.isNotEmpty ? project.name.substring(0, 1).toUpperCase() : '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? project.status.color.withOpacity(0.2) : project.status.bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.status.label.toUpperCase(),
                          style: TextStyle(fontSize: 9, color: project.status.color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGridCard(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (details) {
        _showStatusUpdateMenu(context, project, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
                backgroundColor: const Color(0xFF2196F3),
                radius: 16,
                child: Text(
                    project.name.isNotEmpty ? project.name.substring(0, 1).toUpperCase() : '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12))),
            const SizedBox(height: 8),
            Text(project.name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? project.status.color.withOpacity(0.2) : project.status.bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    project.status.label.toUpperCase(),
                    style: TextStyle(fontSize: 9, color: project.status.color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
