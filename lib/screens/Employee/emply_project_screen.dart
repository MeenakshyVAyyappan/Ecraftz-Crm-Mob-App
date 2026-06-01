import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/project/project_bloc.dart';
import '../../models/project_model.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          final filteredProjects = state.projects.where((p) {
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                _buildBreadcrumb(['Dashboard', 'Projects']),
                const SizedBox(height: 12),
                // Header
                Text('Projects & Growth',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                Text('Manage active and archived projects.',
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
                  child: Text('ACTIVE PROJECTS',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProjectDialog(),
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project',
            style: TextStyle(color: Colors.white)),
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
          GestureDetector(
            onTap: () => _showAddProjectDialog(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFF2196F3), size: 30),
            ),
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
    return Container(
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
                Text(project.status.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildProjectGridCard(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
          Text(project.status.label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
        ],
      ),
    );
  }

  void _showAddProjectDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: isDark ? const Border(top: BorderSide(color: AppTheme.borderDark)) : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Create New Project',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  labelStyle: TextStyle(color: isDark ? const Color(0xFF8E9CB8) : Colors.black54),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    context.read<ProjectBloc>().add(
                          AddProjectEvent(
                            Project(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameCtrl.text,
                              clientName: 'Demo Client',
                              status: ProjectStatus.inProgress,
                              isArchived: false,
                            ),
                          ),
                        );
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF2196F3)),
                child: const Text('Create Project',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}