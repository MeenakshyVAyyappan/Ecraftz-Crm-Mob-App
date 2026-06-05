// projects_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/project/project_bloc.dart';
import '../../models/project_model.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';

// ─── MAIN PROJECTS PAGE ───────────────────────────────────────────────────────

class ProjectsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;  
  const ProjectsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _viewMode = 0; // 0=kanban, 1=grid, 2=list
  ProjectStatus? _selectedStatus;
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color _primary = Color(0xFF0EA5E9);

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Project> _filteredProjects(List<Project> projects, bool archived) {
    return projects.where((p) {
      if (p.isArchived != archived) return false;
      if (_selectedStatus != null && p.status != _selectedStatus) return false;
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !p.clientName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projects & Growth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              'Manage active projects and monitor growth.',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabBar(),
                _buildFilterBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProjectsList(state.projects, false),
                      _buildProjectsList(state.projects, true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectModal(context),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final isWide = MediaQuery.of(context).size.width > 600;
    final importButton = OutlinedButton.icon(
      onPressed: () => _showBulkImportDialog(context),
      icon: const Icon(Icons.upload_file, size: 16),
      label: const Text('Bulk Import'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
    final newProjectButton = ElevatedButton.icon(
      onPressed: () => _showCreateProjectModal(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('New Project'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                importButton,
                const SizedBox(width: 8),
                newProjectButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: importButton),
                const SizedBox(width: 8),
                Expanded(child: newProjectButton),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _TabButton(
            label: 'ACTIVE PROJECTS',
            selected: _tabController.index == 0,
            onTap: () {
              setState(() => _tabController.index = 0);
            },
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'ARCHIVED',
            selected: _tabController.index == 1,
            onTap: () {
              setState(() => _tabController.index = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isWide = MediaQuery.of(context).size.width > 600;
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: _textSecondary),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StatusDropdown(
              selected: _selectedStatus,
              onChanged: (s) => setState(() => _selectedStatus = s),
            ),
            const SizedBox(width: 8),
            _ViewToggle(
              viewMode: _viewMode,
              onChanged: (v) => setState(() => _viewMode = v),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: _textSecondary),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: _textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatusDropdown(
                    selected: _selectedStatus,
                    onChanged: (s) => setState(() => _selectedStatus = s),
                  ),
                ),
                const SizedBox(width: 8),
                _ViewToggle(
                  viewMode: _viewMode,
                  onChanged: (v) => setState(() => _viewMode = v),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProjectsList(List<Project> allProjects, bool archived) {
    final projects = _filteredProjects(allProjects, archived);

    if (projects.isEmpty) {
      return _buildEmptyState();
    }

    if (_viewMode == 2) {
      return _buildListView(projects);
    }

    final isWide = MediaQuery.of(context).size.width > 600;
    final textScale = MediaQuery.maybeOf(context)?.textScaleFactor ?? 1.0;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: (isWide ? 215.0 : 240.0) * textScale,
      ),
      itemCount: projects.length,
      itemBuilder: (_, i) => _ProjectCard(project: projects[i]),
    );
  }

  Widget _buildListView(List<Project> projects) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ProjectListTile(project: projects[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 32, color: _primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get started by creating your first project\nand assigning it to a client.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateProjectModal(
        onSubmit: (project) {
          context.read<ProjectBloc>().add(AddProjectEvent(project));
        },
      ),
    );
  }

  void _showBulkImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bulk Import'),
        content: const Text(
            'Upload a CSV file to bulk import projects.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final bulkProjects = [
                Project(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'Imported Project A',
                  clientName: 'Client A',
                  status: ProjectStatus.planning,
                ),
                Project(
                  id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
                  name: 'Imported Project B',
                  clientName: 'Client B',
                  status: ProjectStatus.inProgress,
                ),
              ];
              context.read<ProjectBloc>().add(AddProjectsBulkEvent(bulkProjects));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bulk imported 2 projects!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9)),
            child: const Text('Upload CSV',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── TAB BUTTON ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected 
              ? (isDark ? AppTheme.bgCardDark : Colors.white) 
              : Colors.transparent,
          border: selected
              ? Border.all(color: AppTheme.borderOf(context))
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppTheme.textPrimaryOf(context)
                : AppTheme.textSecondaryOf(context),
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ─── STATUS DROPDOWN ──────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final ProjectStatus? selected;
  final ValueChanged<ProjectStatus?> onChanged;

  const _StatusDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectStatus?>(
          value: selected,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          hint: Text('All Status',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          onChanged: onChanged,
          items: [
            DropdownMenuItem<ProjectStatus?>(
              value: null,
              child: Text('All Status', style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
            ),
            ...ProjectStatus.values.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s.label[0].toUpperCase() + s.label.substring(1),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── VIEW TOGGLE ─────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final int viewMode;
  final ValueChanged<int> onChanged;

  const _ViewToggle({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _ToggleIcon(
            icon: Icons.view_column_outlined,
            selected: viewMode == 0,
            onTap: () => onChanged(0),
            isFirst: true,
          ),
          _ToggleIcon(
            icon: Icons.grid_view,
            selected: viewMode == 1,
            onTap: () => onChanged(1),
          ),
          _ToggleIcon(
            icon: Icons.view_list,
            selected: viewMode == 2,
            onTap: () => onChanged(2),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ToggleIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0EA5E9).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? const Color(0xFF0EA5E9)
              : AppTheme.textMutedOf(context),
        ),
      ),
    );
  }
}

// ─── PROJECT CARD (GRID) ──────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: project.status),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 18, color: AppTheme.textMutedOf(context)),
                  padding: EdgeInsets.zero,
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  onSelected: (value) {
                    if (value == 'delete') {
                      context.read<ProjectBloc>().add(DeleteProjectEvent(project.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project deleted'), backgroundColor: Colors.red),
                      );
                    } else if (value == 'archive') {
                      final updated = Project(
                        id: project.id,
                        name: project.name,
                        clientName: project.clientName,
                        status: project.status,
                        deadline: project.deadline,
                        totalTasks: project.totalTasks,
                        completedTasks: project.completedTasks,
                        progress: project.progress,
                        teamLead: project.teamLead,
                        isArchived: !project.isArchived,
                      );
                      context.read<ProjectBloc>().add(UpdateProjectEvent(updated));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(project.isArchived ? 'Project unarchived' : 'Project archived'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(project.isArchived ? 'Unarchive' : 'Archive', style: TextStyle(color: AppTheme.textPrimaryOf(context))),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              project.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              project.clientName.isEmpty
                  ? 'No Client Assigned'
                  : project.clientName,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondaryOf(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 4),
                Text(
                  project.deadline ?? 'No deadline',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                ),
                const Spacer(),
                Icon(Icons.check_box_outlined,
                    size: 13, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 4),
                Text(
                  '${project.completedTasks}/${project.totalTasks} Tasks',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Progress',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                const Spacer(),
                Text(
                  '${project.progress.toInt()}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0EA5E9)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgBaseDark : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppTheme.borderDark : Colors.white, width: 1.5),
                  ),
                  child: Icon(Icons.person_outline,
                      size: 14, color: AppTheme.textSecondaryOf(context)),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TEAM LEAD',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMutedOf(context),
                          letterSpacing: 0.5),
                    ),
                    Text(
                      project.teamLead?.toUpperCase() ?? 'UNASSIGNED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryOf(context),
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROJECT LIST TILE ────────────────────────────────────────────────────────

class _ProjectListTile extends StatelessWidget {
  final Project project;

  const _ProjectListTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: project.status.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                project.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: project.status.color,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  project.clientName.isEmpty
                      ? 'No Client Assigned'
                      : project.clientName,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _StatusBadge(status: project.status),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${project.completedTasks}/${project.totalTasks} Tasks',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondaryOf(context)),
              ),
              Text(
                '${project.progress.toInt()}%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0EA5E9)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: AppTheme.textMutedOf(context)),
            padding: EdgeInsets.zero,
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            onSelected: (value) {
              if (value == 'delete') {
                context.read<ProjectBloc>().add(DeleteProjectEvent(project.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project deleted'), backgroundColor: Colors.red),
                );
              } else if (value == 'archive') {
                final updated = Project(
                  id: project.id,
                  name: project.name,
                  clientName: project.clientName,
                  status: project.status,
                  deadline: project.deadline,
                  totalTasks: project.totalTasks,
                  completedTasks: project.completedTasks,
                  progress: project.progress,
                  teamLead: project.teamLead,
                  isArchived: !project.isArchived,
                );
                context.read<ProjectBloc>().add(UpdateProjectEvent(updated));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(project.isArchived ? 'Project unarchived' : 'Project archived'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(project.isArchived ? 'Unarchive' : 'Archive', style: TextStyle(color: AppTheme.textPrimaryOf(context))),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

// ─── CREATE PROJECT MODAL ────────────────────────────────────────────────────

class _CreateProjectModal extends StatefulWidget {
  final Function(Project) onSubmit;

  const _CreateProjectModal({required this.onSubmit});

  @override
  State<_CreateProjectModal> createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends State<_CreateProjectModal> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Software';
  String? _client;
  String? _department;
  ProjectStatus _phase = ProjectStatus.planning;
  String? _teamLead;
  DateTime? _kickoffDate;
  DateTime? _deadline;

  static const Color _primary = Color(0xFF0EA5E9);
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  final List<String> _categories = [
    'Software', 'Design', 'Marketing', 'Finance', 'HR', 'Operations'
  ];
  final List<String> _clients = [
    'ecocraft', 'shock stark', 'meethu', 'Client A', 'Client B'
  ];
  final List<String> _departments = [
    'Engineering', 'Design', 'Sales', 'Support', 'Management'
  ];
  final List<String> _teamLeads = [
    'Alice', 'Bob', 'Charlie', 'Diana', 'Eve'
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final projectNameField = _FormField(
      label: 'PROJECT NAME',
      child: TextField(
        controller: _nameController,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration('e.g. Website Redesign'),
      ),
    );

    final projectCategoryField = _FormField(
      label: 'PROJECT CATEGORY',
      child: DropdownButtonFormField<String>(
        value: _category,
        isExpanded: true,
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration(''),
        items: _categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textPrimary))))
            .toList(),
        onChanged: (v) => setState(() => _category = v!),
      ),
    );

    final assignedClientField = _FormField(
      label: 'ASSIGNED CLIENT',
      child: DropdownButtonFormField<String?>(
        value: _client,
        isExpanded: true,
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration('Select a client'),
        items: [
          DropdownMenuItem(value: null, child: Text('Select a client', overflow: TextOverflow.ellipsis, style: TextStyle(color: _textSecondary))),
          ..._clients.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textPrimary)))),
        ],
        onChanged: (v) => setState(() => _client = v),
      ),
    );

    final assignedDepartmentField = _FormField(
      label: 'ASSIGNED DEPARTMENT',
      child: DropdownButtonFormField<String?>(
        value: _department,
        isExpanded: true,
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration('Select a department'),
        items: [
          DropdownMenuItem(value: null, child: Text('Select a department', overflow: TextOverflow.ellipsis, style: TextStyle(color: _textSecondary))),
          ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textPrimary)))),
        ],
        onChanged: (v) => setState(() => _department = v),
      ),
    );

    final descriptionField = _FormField(
      label: 'DESCRIPTION (OPTIONAL)',
      child: TextField(
        controller: _descController,
        maxLines: 3,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration(''),
      ),
    );

    final currentPhaseField = _FormField(
      label: 'CURRENT PHASE',
      child: DropdownButtonFormField<ProjectStatus>(
        value: _phase,
        isExpanded: true,
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration(''),
        items: ProjectStatus.values
            .map((s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s.label[0].toUpperCase() + s.label.substring(1),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _textPrimary),
                )))
            .toList(),
        onChanged: (v) => setState(() => _phase = v!),
      ),
    );

    final kickoffDateField = _FormField(
      label: 'KICK-OFF DATE',
      child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (d != null) {
            setState(() => _kickoffDate = d);
          }
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? AppTheme.bgBaseDark : Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _kickoffDate != null
                      ? '${_kickoffDate!.day}-${_kickoffDate!.month}-${_kickoffDate!.year}'
                      : 'dd-mm-yyyy',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kickoffDate != null ? _textPrimary : _textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );

    final targetDeadlineField = _FormField(
      label: 'TARGET DEADLINE',
      child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (d != null) {
            setState(() => _deadline = d);
          }
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? AppTheme.bgBaseDark : Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _deadline != null
                      ? '${_deadline!.day}-${_deadline!.month}-${_deadline!.year}'
                      : 'dd-mm-yyyy',
                  style: TextStyle(
                      fontSize: 13,
                      color: _deadline != null ? _textPrimary : _textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );

    final projectLeadField = _FormField(
      label: 'PROJECT LEAD / HR',
      child: DropdownButtonFormField<String?>(
        value: _teamLead,
        isExpanded: true,
        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
        style: TextStyle(color: _textPrimary),
        decoration: _inputDecoration('Select Team lead'),
        items: [
          DropdownMenuItem(value: null, child: Text('Select Team lead', overflow: TextOverflow.ellipsis, style: TextStyle(color: _textSecondary))),
          ..._teamLeads.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textPrimary)))),
        ],
        onChanged: (v) => setState(() => _teamLead = v),
      ),
    );

    final overviewSection = isWide
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: projectNameField),
                  const SizedBox(width: 12),
                  Expanded(child: projectCategoryField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: assignedClientField),
                  const SizedBox(width: 12),
                  Expanded(child: assignedDepartmentField),
                ],
              ),
            ],
          )
        : Column(
            children: [
              projectNameField,
              const SizedBox(height: 12),
              projectCategoryField,
              const SizedBox(height: 12),
              assignedClientField,
              const SizedBox(height: 12),
              assignedDepartmentField,
            ],
          );

    final timelineSection = isWide
        ? Row(
            children: [
              Expanded(child: currentPhaseField),
              const SizedBox(width: 12),
              Expanded(child: kickoffDateField),
              const SizedBox(width: 12),
              Expanded(child: targetDeadlineField),
            ],
          )
        : Column(
            children: [
              currentPhaseField,
              const SizedBox(height: 12),
              kickoffDateField,
              const SizedBox(height: 12),
              targetDeadlineField,
            ],
          );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90 - MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Project',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add a new project to your workspace to start tracking tasks and milestones.',
                          style: TextStyle(fontSize: 11, color: _textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 22, color: _textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    icon: Icons.business_center_outlined,
                                    label: 'PROJECT OVERVIEW',
                                    color: _primary,
                                  ),
                                  const SizedBox(height: 14),
                                  overviewSection,
                                  const SizedBox(height: 12),
                                  descriptionField,
                                  const SizedBox(height: 20),
                                  _SectionHeader(
                                    icon: Icons.calendar_month_outlined,
                                    label: 'TIMELINE & STATUS',
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(height: 14),
                                  timelineSection,
                                  const SizedBox(height: 20),
                                  _SectionHeader(
                                    icon: Icons.group_outlined,
                                    label: 'TEAM ASSIGNMENT',
                                    color: const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(height: 14),
                                  projectLeadField,
                                ],
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'INITIALIZE PROJECT',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      clientName: _client ?? '',
      status: _phase,
      deadline: _deadline != null
          ? '${_deadline!.day}-${_deadline!.month}-${_deadline!.year}'
          : null,
      teamLead: _teamLead,
      isArchived: false,
    );

    widget.onSubmit(project);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project created successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, color: AppTheme.textMutedOf(context)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        filled: true,
        fillColor: isDark ? AppTheme.bgBaseDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      );
  }
}

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryOf(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}