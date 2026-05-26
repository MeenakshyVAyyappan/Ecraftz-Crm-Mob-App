// projects_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ─── DATA MODELS ────────────────────────────────────────────────────────────

enum ProjectStatus { planning, inProgress, onHold, completed, cancelled }

extension ProjectStatusExt on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'planning';
      case ProjectStatus.inProgress:
        return 'in progress';
      case ProjectStatus.onHold:
        return 'on hold';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return const Color(0xFF6366F1);
      case ProjectStatus.inProgress:
        return const Color(0xFF10B981);
      case ProjectStatus.onHold:
        return const Color(0xFFF59E0B);
      case ProjectStatus.completed:
        return const Color(0xFF3B82F6);
      case ProjectStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Color get bgColor {
    switch (this) {
      case ProjectStatus.planning:
        return const Color(0xFFEEF2FF);
      case ProjectStatus.inProgress:
        return const Color(0xFFD1FAE5);
      case ProjectStatus.onHold:
        return const Color(0xFFFEF3C7);
      case ProjectStatus.completed:
        return const Color(0xFFDBEAFE);
      case ProjectStatus.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }
}

class Project {
  final String id;
  final String name;
  final String clientName;
  final ProjectStatus status;
  final String? deadline;
  final int totalTasks;
  final int completedTasks;
  final double progress;
  final String? teamLead;
  final bool isArchived;

  Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.status,
    this.deadline,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.progress = 0.0,
    this.teamLead,
    this.isArchived = false,
  });
}

// ─── SAMPLE DATA ─────────────────────────────────────────────────────────────

final List<Project> sampleProjects = [
  Project(
    id: '1',
    name: 'ecocraft',
    clientName: 'ecocraft',
    status: ProjectStatus.inProgress,
    isArchived: true,
  ),
  Project(
    id: '2',
    name: 'aliya',
    clientName: 'shock stark',
    status: ProjectStatus.inProgress,
    isArchived: true,
  ),
  Project(
    id: '3',
    name: 'aesthetrix',
    clientName: 'meethu',
    status: ProjectStatus.cancelled,
    isArchived: true,
  ),
  Project(
    id: '4',
    name: 'flexora',
    clientName: '',
    status: ProjectStatus.onHold,
    isArchived: true,
  ),
  Project(
    id: '5',
    name: 'livekeralam',
    clientName: '',
    status: ProjectStatus.completed,
    isArchived: true,
  ),
  Project(
    id: '6',
    name: 'arsenal',
    clientName: '',
    status: ProjectStatus.inProgress,
    isArchived: true,
  ),
];

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
  List<Project> _projects = List.from(sampleProjects);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Project> get _filteredProjects {
    bool archived = _tabController.index == 1;
    return _projects.where((p) {
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
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
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projects & Growth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Manage active projects and monitor growth.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            _buildFilterBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProjectsList(false),
                  _buildProjectsList(true),
                ],
              ),
            ),
          ],
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
        side: const BorderSide(color: _border),
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
                      const TextStyle(fontSize: 13, color: _textSecondary),
                  prefixIcon: const Icon(Icons.search,
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
  }

  Widget _buildProjectsList(bool archived) {
    final projects = _filteredProjects;

    if (projects.isEmpty) {
      return _buildEmptyState();
    }

    if (_viewMode == 2) {
      return _buildListView(projects);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 195,
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
          setState(() => _projects.add(project));
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
            onPressed: () => Navigator.pop(context),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: selected
              ? Border.all(color: const Color(0xFFE2E8F0))
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
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
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
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
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectStatus?>(
          value: selected,
          hint: const Text('All Status',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<ProjectStatus?>(
              value: null,
              child: Text('All Status', style: TextStyle(fontSize: 13)),
            ),
            ...ProjectStatus.values.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s.label[0].toUpperCase() + s.label.substring(1),
                  style: const TextStyle(fontSize: 13),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              : const Color(0xFF94A3B8),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: project.status),
                const Spacer(),
                Icon(Icons.more_horiz, size: 18, color: const Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              project.clientName.isEmpty
                  ? 'No Client Assigned'
                  : project.clientName,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  project.deadline ?? 'No deadline',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const Spacer(),
                const Icon(Icons.check_box_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${project.completedTasks}/${project.totalTasks} Tasks',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Progress',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
                const Spacer(),
                Text(
                  '${project.progress.toInt()}%',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0EA5E9)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 14, color: Color(0xFF94A3B8)),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TEAM LEAD',
                      style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5),
                    ),
                    Text(
                      project.teamLead?.toUpperCase() ?? 'UNASSIGNED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  project.clientName.isEmpty
                      ? 'No Client Assigned'
                      : project.clientName,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
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
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
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
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

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

    final projectNameField = _FormField(
      label: 'PROJECT NAME',
      child: TextField(
        controller: _nameController,
        decoration: _inputDecoration('e.g. Website Redesign'),
      ),
    );

    final projectCategoryField = _FormField(
      label: 'PROJECT CATEGORY',
      child: DropdownButtonFormField<String>(
        value: _category,
        isExpanded: true,
        decoration: _inputDecoration(''),
        items: _categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) => setState(() => _category = v!),
      ),
    );

    final assignedClientField = _FormField(
      label: 'ASSIGNED CLIENT',
      child: DropdownButtonFormField<String?>(
        value: _client,
        isExpanded: true,
        decoration: _inputDecoration('Select a client'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select a client', overflow: TextOverflow.ellipsis)),
          ..._clients.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: (v) => setState(() => _client = v),
      ),
    );

    final assignedDepartmentField = _FormField(
      label: 'ASSIGNED DEPARTMENT',
      child: DropdownButtonFormField<String?>(
        value: _department,
        isExpanded: true,
        decoration: _inputDecoration('Select a department'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select a department', overflow: TextOverflow.ellipsis)),
          ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: (v) => setState(() => _department = v),
      ),
    );

    final descriptionField = _FormField(
      label: 'DESCRIPTION (OPTIONAL)',
      child: TextField(
        controller: _descController,
        maxLines: 3,
        decoration: _inputDecoration(''),
      ),
    );

    final currentPhaseField = _FormField(
      label: 'CURRENT PHASE',
      child: DropdownButtonFormField<ProjectStatus>(
        value: _phase,
        isExpanded: true,
        decoration: _inputDecoration(''),
        items: ProjectStatus.values
            .map((s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s.label[0].toUpperCase() + s.label.substring(1),
                  overflow: TextOverflow.ellipsis,
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
        decoration: _inputDecoration('Select Team lead'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Team lead', overflow: TextOverflow.ellipsis)),
          ..._teamLeads.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90 - MediaQuery.of(context).viewInsets.bottom,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: const Color(0xFFE2E8F0),
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
                      const Text(
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
                  icon: const Icon(Icons.close, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Submit Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: Color(0xFF94A3B8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      );
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
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}