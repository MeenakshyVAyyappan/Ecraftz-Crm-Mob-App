// tasks_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ─── ENUMS & MODELS ──────────────────────────────────────────────────────────

enum TaskStatus { toDo, inProgress, review, done }
enum TaskPriority { low, medium, high }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.toDo: return 'To Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.review: return 'Review';
      case TaskStatus.done: return 'Done';
    }
  }
  Color get color {
    switch (this) {
      case TaskStatus.toDo: return const Color(0xFF94A3B8);
      case TaskStatus.inProgress: return const Color(0xFF0EA5E9);
      case TaskStatus.review: return const Color(0xFFF59E0B);
      case TaskStatus.done: return const Color(0xFF10B981);
    }
  }
  Color get bgColor {
    switch (this) {
      case TaskStatus.toDo: return const Color(0xFFF1F5F9);
      case TaskStatus.inProgress: return const Color(0xFFE0F2FE);
      case TaskStatus.review: return const Color(0xFFFEF3C7);
      case TaskStatus.done: return const Color(0xFFD1FAE5);
    }
  }
}

extension TaskPriorityExt on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low: return 'LOW';
      case TaskPriority.medium: return 'MEDIUM';
      case TaskPriority.high: return 'HIGH';
    }
  }
  Color get color {
    switch (this) {
      case TaskPriority.low: return const Color(0xFF10B981);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.high: return const Color(0xFFEF4444);
    }
  }
  Color get bgColor {
    switch (this) {
      case TaskPriority.low: return const Color(0xFFD1FAE5);
      case TaskPriority.medium: return const Color(0xFFFEF3C7);
      case TaskPriority.high: return const Color(0xFFFEE2E2);
    }
  }
}

class TaskItem {
  final String id;
  String summary;
  String description;
  String? parentProject;
  String? owner;
  DateTime? dueDate;
  TaskStatus status;
  TaskPriority priority;

  TaskItem({
    required this.id,
    required this.summary,
    this.description = '',
    this.parentProject,
    this.owner,
    this.dueDate,
    required this.status,
    required this.priority,
  });
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String department;
  final int weeklyLoad;
  final int weeklyLimit;
  final List<TaskItem> tasks;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    this.weeklyLoad = 0,
    this.weeklyLimit = 40,
    required this.tasks,
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  String get workloadStatus {
    final pct = weeklyLoad / weeklyLimit;
    if (pct >= 1.0) return 'Overloaded';
    if (pct >= 0.8) return 'At Risk';
    return 'Balanced';
  }

  Color get workloadColor {
    final pct = weeklyLoad / weeklyLimit;
    if (pct >= 1.0) return const Color(0xFFEF4444);
    if (pct >= 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}

// ─── SAMPLE DATA ─────────────────────────────────────────────────────────────

List<TaskItem> _sampleTasks = [
  TaskItem(
    id: '1',
    summary: 'landing page',
    parentProject: 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE...',
    owner: 'Chimbu',
    dueDate: DateTime(2026, 5, 27),
    status: TaskStatus.inProgress,
    priority: TaskPriority.low,
  ),
  TaskItem(
    id: '2',
    summary: 'hello brooo',
    parentProject: 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE...',
    owner: 'Tony Stark',
    dueDate: DateTime(2026, 5, 28),
    status: TaskStatus.done,
    priority: TaskPriority.medium,
  ),
  TaskItem(
    id: '3',
    summary: 'design dashboard',
    parentProject: 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE...',
    owner: 'Chimbu',
    dueDate: DateTime(2026, 5, 23),
    status: TaskStatus.done,
    priority: TaskPriority.high,
  ),
  TaskItem(
    id: '4',
    summary: 'develop this',
    parentProject: 'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICA...',
    owner: 'Chimbu',
    dueDate: DateTime(2026, 5, 22),
    status: TaskStatus.done,
    priority: TaskPriority.high,
  ),
];

List<TeamMember> _sampleMembers = [
  TeamMember(
    id: '1',
    name: 'Chimbu',
    role: 'TEAM LEAD',
    department: 'WEB DEVELOPING',
    weeklyLoad: 0,
    weeklyLimit: 40,
    tasks: _sampleTasks.where((t) => t.owner == 'Chimbu').toList(),
  ),
  TeamMember(
    id: '2',
    name: 'Tony Stark',
    role: 'SALES',
    department: 'BDE',
    weeklyLoad: 0,
    weeklyLimit: 40,
    tasks: _sampleTasks.where((t) => t.owner == 'Tony Stark').toList(),
  ),
];

// ─── TASKS PAGE ───────────────────────────────────────────────────────────────

class TasksPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;  
  const TasksPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int _viewIndex = 0; // 0=Kanban, 1=List, 2=Workload
  String _searchQuery = '';
  List<TaskItem> _tasks = List.from(_sampleTasks);
  List<TeamMember> _members = List.from(_sampleMembers);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  List<TaskItem> get _filtered => _tasks.where((t) {
        if (_searchQuery.isEmpty) return true;
        return t.summary.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

  int get _unassignedCount =>
      _tasks.where((t) => t.owner == null || t.owner!.isEmpty).length;

  int get _overloadedCount =>
      _members.where((m) => m.workloadStatus == 'Overloaded').length;

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
              'Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Collaborate and track progress across all project tasks.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildViewTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskModal(context),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final isWide = MediaQuery.of(context).size.width > 600;

    final importBtn = OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.upload_file, size: 14),
      label: const Text('Import'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: const BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    final filterBtn = OutlinedButton.icon(
      onPressed: () => _showFilterSheet(context),
      icon: const Icon(Icons.tune, size: 14),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: const BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    final newTaskBtn = ElevatedButton.icon(
      onPressed: () => _showCreateTaskModal(context),
      icon: const Icon(Icons.add, size: 14),
      label: const Text('New Task'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                importBtn,
                const SizedBox(width: 6),
                filterBtn,
                const SizedBox(width: 6),
                newTaskBtn,
              ],
            )
          : Row(
              children: [
                Expanded(child: importBtn),
                const SizedBox(width: 6),
                Expanded(child: filterBtn),
                const SizedBox(width: 6),
                Expanded(child: newTaskBtn),
              ],
            ),
    );
  }

  Widget _buildViewTabs() {
    final isWide = MediaQuery.of(context).size.width > 600;

    final tabsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewTab(label: 'Kanban', icon: Icons.view_column_outlined, selected: _viewIndex == 0, onTap: () => setState(() => _viewIndex = 0)),
        const SizedBox(width: 4),
        _ViewTab(label: 'List', icon: Icons.view_list, selected: _viewIndex == 1, onTap: () => setState(() => _viewIndex = 1)),
        const SizedBox(width: 4),
        _ViewTab(label: 'Workload', icon: Icons.people_outline, selected: _viewIndex == 2, onTap: () => setState(() => _viewIndex = 2)),
      ],
    );

    final searchField = Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: isWide
          ? Row(
              children: [
                tabsRow,
                const SizedBox(width: 8),
                Expanded(child: searchField),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tabsRow,
                const SizedBox(height: 8),
                searchField,
              ],
            ),
    );
  }

  Widget _buildBody() {
    switch (_viewIndex) {
      case 0: return _buildKanban();
      case 1: return _buildListView();
      case 2: return _buildWorkload();
      default: return _buildKanban();
    }
  }

  // ── KANBAN ────────────────────────────────────────────────────────────────

  Widget _buildKanban() {
    final columns = TaskStatus.values;
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((s) {
              final colTasks = _filtered.where((t) => t.status == s).toList();
              return _KanbanColumn(
                status: s,
                tasks: colTasks,
                width: 240,
                onTaskTap: (t) => _showTaskDetail(context, t),
                onAddTask: () => _showCreateTaskModal(context, status: s),
              );
            }).toList(),
          ),
        );
      }
      // Mobile: vertical scroll with collapsible sections
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: columns.map((s) {
          final colTasks = _filtered.where((t) => t.status == s).toList();
          return _KanbanColumnMobile(
            status: s,
            tasks: colTasks,
            onTaskTap: (t) => _showTaskDetail(context, t),
            onAddTask: () => _showCreateTaskModal(context, status: s),
          );
        }).toList(),
      );
    });
  }

  // ── LIST VIEW ─────────────────────────────────────────────────────────────

  Widget _buildListView() {
    final tasks = _filtered;
    if (tasks.isEmpty) return _buildEmptyState('No tasks found');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TaskListTile(
        task: tasks[i],
        onTap: () => _showTaskDetail(context, tasks[i]),
        onStatusChange: (s) => setState(() => tasks[i].status = s),
      ),
    );
  }

  // ── WORKLOAD ──────────────────────────────────────────────────────────────

  Widget _buildWorkload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final stats = [
              _StatCard(label: 'TEAM SIZE', value: '${_members.length} Members', icon: Icons.people_outline, iconColor: _primary),
              _StatCard(label: 'TOTAL BACKLOG EST.', value: '0 hrs', icon: Icons.access_time_outlined, iconColor: _primary),
              _StatCard(label: 'OVER-ALLOCATED TEAM', value: '$_overloadedCount Overloaded', icon: Icons.warning_amber_outlined, iconColor: const Color(0xFFF59E0B)),
              _StatCard(label: 'UNASSIGNED TASKS', value: '$_unassignedCount Pending', icon: Icons.person_off_outlined, iconColor: const Color(0xFF6366F1)),
            ];
            if (isWide) {
              return Row(children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: s))).toList());
            }
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: stats,
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: _primary),
              const SizedBox(width: 6),
              const Text(
                'Resource Allocation Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Sync Board'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          Text(
            'Manage weekly task limits and capacity thresholds to maintain optimum work balance.',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _members.map((m) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _WorkloadCard(
                      member: m,
                      onViewBreakout: () => _showWorkloadBreakout(context, m),
                    ),
                  ),
                )).toList(),
              );
            }
            return Column(
              children: _members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkloadCard(
                  member: m,
                  onViewBreakout: () => _showWorkloadBreakout(context, m),
                ),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.task_outlined, size: 30, color: _primary),
          ),
          const SizedBox(height: 14),
          Text(msg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
        ],
      ),
    );
  }

  // ── MODALS ────────────────────────────────────────────────────────────────

  void _showCreateTaskModal(BuildContext context, {TaskStatus? status}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTaskModal(
        initialStatus: status ?? TaskStatus.toDo,
        members: _members,
        onSubmit: (task) => setState(() => _tasks.add(task)),
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskItem task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailModal(
        task: task,
        members: _members,
        onUpdate: () => setState(() {}),
        onDelete: () => setState(() => _tasks.removeWhere((t) => t.id == task.id)),
      ),
    );
  }

  void _showWorkloadBreakout(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      builder: (_) => _WorkloadBreakoutDialog(
        member: member,
        allMembers: _members,
        onReallocate: (taskId, newOwner) {
          setState(() {
            final t = _tasks.firstWhere((t) => t.id == taskId, orElse: () => _tasks.first);
            t.owner = newOwner;
          });
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((p) => FilterChip(
                label: Text(p.label),
                onSelected: (_) {},
                labelStyle: TextStyle(fontSize: 12, color: p.color),
                backgroundColor: p.bgColor,
                selectedColor: p.bgColor,
                checkmarkColor: p.color,
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((s) => FilterChip(
                label: Text(s.label),
                onSelected: (_) {},
                labelStyle: TextStyle(fontSize: 12, color: s.color),
                backgroundColor: s.bgColor,
                selectedColor: s.bgColor,
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── KANBAN COLUMN (Wide) ─────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final TaskStatus status;
  final List<TaskItem> tasks;
  final double width;
  final Function(TaskItem) onTaskTap;
  final VoidCallback onAddTask;

  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.width,
    required this.onTaskTap,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColumnHeader(status: status, count: tasks.length),
          const SizedBox(height: 10),
          ...tasks.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(task: t, onTap: () => onTaskTap(t)),
          )),
          _AddTaskButton(onTap: onAddTask),
        ],
      ),
    );
  }
}

// ─── KANBAN COLUMN (Mobile) ───────────────────────────────────────────────────

class _KanbanColumnMobile extends StatefulWidget {
  final TaskStatus status;
  final List<TaskItem> tasks;
  final Function(TaskItem) onTaskTap;
  final VoidCallback onAddTask;

  const _KanbanColumnMobile({
    required this.status,
    required this.tasks,
    required this.onTaskTap,
    required this.onAddTask,
  });

  @override
  State<_KanbanColumnMobile> createState() => _KanbanColumnMobileState();
}

class _KanbanColumnMobileState extends State<_KanbanColumnMobile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: widget.status.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.status.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Text('${widget.tasks.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                  const Spacer(),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ...widget.tasks.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskCard(task: t, onTap: () => widget.onTaskTap(t)),
                  )),
                  _AddTaskButton(onTap: widget.onAddTask),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final TaskStatus status;
  final int count;
  const _ColumnHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(status.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text('Add Task', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

// ─── TASK CARD ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityBadge(priority: task.priority),
                const Spacer(),
                if (task.owner != null)
                  _Avatar(name: task.owner!, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.summary,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            if (task.parentProject != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.parentProject!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ),
                ],
              ),
            ],
            if (task.owner != null) ...[
              const SizedBox(height: 4),
              Text('Lead: ${task.owner}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueDate!),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─── TASK LIST TILE ───────────────────────────────────────────────────────────

class _TaskListTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final Function(TaskStatus) onStatusChange;

  const _TaskListTile({required this.task, required this.onTap, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final next = TaskStatus.values[(task.status.index + 1) % TaskStatus.values.length];
                onStatusChange(next);
              },
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: task.status.color, width: 1.5),
                  shape: BoxShape.circle,
                  color: task.status == TaskStatus.done ? task.status.color : Colors.transparent,
                ),
                child: task.status == TaskStatus.done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.summary,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A),
                      decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                    )),
                  if (task.parentProject != null)
                    Text(task.parentProject!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PriorityBadge(priority: task.priority),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: task.status.bgColor, borderRadius: BorderRadius.circular(6)),
              child: Text(task.status.label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: task.status.color)),
            ),
            if (task.owner != null) ...[
              const SizedBox(width: 8),
              _Avatar(name: task.owner!, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── WORKLOAD CARD ────────────────────────────────────────────────────────────

class _WorkloadCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onViewBreakout;

  const _WorkloadCard({required this.member, required this.onViewBreakout});

  @override
  Widget build(BuildContext context) {
    final pct = member.weeklyLoad / member.weeklyLimit;
    final taskDist = <TaskStatus, int>{};
    for (final t in member.tasks) {
      taskDist[t.status] = (taskDist[t.status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: member.name, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    Text(member.role, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(member.department, style: const TextStyle(fontSize: 10, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: member.workloadColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(member.workloadStatus,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: member.workloadColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('WEEKLY LOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              RichText(text: TextSpan(
                children: [
                  TextSpan(text: '${member.weeklyLoad}h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  TextSpan(text: ' / ${member.weeklyLimit}h limit', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              )),
              const Spacer(),
              Text('${(pct * 100).toInt()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: member.workloadColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(member.workloadColor),
            ),
          ),
          const SizedBox(height: 14),
          const Text('TASK STATUS DISTRIBUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          if (taskDist.isEmpty)
            const Text('No tasks assigned', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
          else
            Wrap(
              spacing: 10,
              children: taskDist.entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Text('${e.key.label}: ${e.value}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              )).toList(),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewBreakout,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('VIEW ALLOCATION PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
                SizedBox(width: 4),
                Text('→', style: TextStyle(fontSize: 11, color: Color(0xFF0EA5E9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          Icon(icon, size: 22, color: iconColor.withOpacity(0.6)),
        ],
      ),
    );
  }
}

// ─── CREATE TASK MODAL ────────────────────────────────────────────────────────

class _CreateTaskModal extends StatefulWidget {
  final TaskStatus initialStatus;
  final List<TeamMember> members;
  final Function(TaskItem) onSubmit;

  const _CreateTaskModal({required this.initialStatus, required this.members, required this.onSubmit});

  @override
  State<_CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<_CreateTaskModal> {
  final _summaryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _parentProject;
  String? _owner;
  DateTime? _dueDate;
  late TaskStatus _status;
  TaskPriority _priority = TaskPriority.medium;

  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  final List<String> _projects = [
    'ARSENAL - Digital Marketing Premium',
    'JANANI - Web Development Dynamic',
    'ECOCRAFT - Brand Identity',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = MediaQuery.of(context).size.width > 600;

    final parentProjectField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('PARENT PROJECT'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          value: _parentProject,
          isExpanded: true,
          decoration: _dec('Link to project'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Link to project', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            ..._projects.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _parentProject = v),
        ),
      ],
    );

    final ownerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('OWNER'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          value: _owner,
          isExpanded: true,
          decoration: _dec('Unassigned'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Unassigned', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            ...widget.members.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => _owner = v),
        ),
      ],
    );

    final statusField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('STATUS'),
        const SizedBox(height: 5),
        DropdownButtonFormField<TaskStatus>(
          value: _status,
          isExpanded: true,
          decoration: _dec(''),
          items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
      ],
    );

    final priorityField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('PRIORITY LEVEL'),
        const SizedBox(height: 5),
        DropdownButtonFormField<TaskPriority>(
          value: _priority,
          isExpanded: true,
          decoration: _dec(''),
          items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label[0] + p.label.substring(1).toLowerCase(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _priority = v!),
        ),
      ],
    );

    final ownershipSection = isWide
        ? Row(
            children: [
              Expanded(child: parentProjectField),
              const SizedBox(width: 10),
              Expanded(child: ownerField),
            ],
          )
        : Column(
            children: [
              parentProjectField,
              const SizedBox(height: 12),
              ownerField,
            ],
          );

    final progressSection = isWide
        ? Row(
            children: [
              Expanded(child: statusField),
              const SizedBox(width: 10),
              Expanded(child: priorityField),
            ],
          )
        : Column(
            children: [
              statusField,
              const SizedBox(height: 12),
              priorityField,
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
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Create New Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
                    const Text('Add a new task to your workspace. You can optionally link it to a project.',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader2(icon: Icons.assignment_outlined, label: 'TASK DEFINITION', color: _primary),
                  const SizedBox(height: 12),
                  _Label('TASK SUMMARY'),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _summaryCtrl,
                    decoration: _dec('e.g. Design system audit...'),
                  ),
                  const SizedBox(height: 12),
                  _Label('DETAILED DESCRIPTION'),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _dec('Add more context...'),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader2(icon: Icons.person_outline, label: 'OWNERSHIP & TIMELINE', color: const Color(0xFF6366F1)),
                  const SizedBox(height: 12),
                  ownershipSection,
                  const SizedBox(height: 12),
                  _Label('DUE DATE'),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text(
                          _dueDate != null ? '${_dueDate!.day}-${_dueDate!.month}-${_dueDate!.year}' : 'dd-mm-yyyy',
                          style: TextStyle(fontSize: 13, color: _dueDate != null ? _textPrimary : const Color(0xFF94A3B8)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader2(icon: Icons.flag_outlined, label: 'PROGRESS & URGENCY', color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  progressSection,
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('LAUNCH TASK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task summary')));
      return;
    }
    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      summary: _summaryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      parentProject: _parentProject,
      owner: _owner,
      dueDate: _dueDate,
      status: _status,
      priority: _priority,
    );
    widget.onSubmit(task);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task created!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
  );
}

// ─── TASK DETAIL MODAL ────────────────────────────────────────────────────────

class _TaskDetailModal extends StatefulWidget {
  final TaskItem task;
  final List<TeamMember> members;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _TaskDetailModal({required this.task, required this.members, required this.onUpdate, required this.onDelete});

  @override
  State<_TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<_TaskDetailModal> {

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(child: Text(t.summary, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  onPressed: () { widget.onDelete(); Navigator.pop(context); }),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _PriorityBadge(priority: t.priority),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: t.status.bgColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(t.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.status.color)),
                  ),
                ]),
                const SizedBox(height: 14),
                _DetailRow(label: 'Owner', value: t.owner ?? 'Unassigned'),
                _DetailRow(label: 'Project', value: t.parentProject ?? 'None'),
                _DetailRow(label: 'Due Date', value: t.dueDate != null ? '${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}' : 'No deadline'),
                const SizedBox(height: 14),
                const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskStatus.values.map((s) => GestureDetector(
                    onTap: () => setState(() { t.status = s; widget.onUpdate(); }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.status == s ? s.bgColor : const Color(0xFFF8FAFC),
                        border: Border.all(color: t.status == s ? s.color : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.status == s ? s.color : const Color(0xFF94A3B8))),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}

// ─── WORKLOAD BREAKOUT DIALOG ─────────────────────────────────────────────────

class _WorkloadBreakoutDialog extends StatefulWidget {
  final TeamMember member;
  final List<TeamMember> allMembers;
  final Function(String taskId, String newOwner) onReallocate;

  const _WorkloadBreakoutDialog({required this.member, required this.allMembers, required this.onReallocate});

  @override
  State<_WorkloadBreakoutDialog> createState() => _WorkloadBreakoutDialogState();
}

class _WorkloadBreakoutDialogState extends State<_WorkloadBreakoutDialog> {
  late Map<String, String> _selectedOwners;

  @override
  void initState() {
    super.initState();
    _selectedOwners = {for (final t in widget.member.tasks) t.id: widget.member.name};
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: screenW > 600 ? 60 : 16, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: widget.member.name, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.member.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  Text('${widget.member.role} — ${widget.member.department} — WORKLOAD BREAKOUT',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ])),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.member.tasks.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GLOBAL WORKSPACE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = MediaQuery.of(context).size.width <= 600;
                              final taskDetailsCol = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.summary, style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                    decoration: t.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                                  )),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    _StatusPill(status: t.status),
                                    const SizedBox(width: 6),
                                    const Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  ]),
                                ],
                              );

                              final reallocateCol = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('REALLOCATE TASK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: _selectedOwners[t.id],
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0EA5E9))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0EA5E9))),
                                    ),
                                    items: widget.allMembers.map((m) => DropdownMenuItem(
                                      value: m.name,
                                      child: Text(
                                        m.name == widget.member.name ? '${m.name} (Current)' : m.name,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedOwners[t.id] = v);
                                    },
                                  ),
                                ],
                              );

                              if (isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    taskDetailsCol,
                                    const SizedBox(height: 12),
                                    reallocateCol,
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    Expanded(child: taskDetailsCol),
                                    const SizedBox(width: 10),
                                    Expanded(child: reallocateCol),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    for (final entry in _selectedOwners.entries) {
                      widget.onReallocate(entry.key, entry.value);
                    }
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Close Breakout', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TaskStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: status.bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(status.label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: status.color, letterSpacing: 0.4)),
    );
  }
}

// ─── SHARED SMALL WIDGETS ─────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: priority.bgColor, borderRadius: BorderRadius.circular(5)),
      child: Text(priority.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priority.color)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  Color get _color {
    final colors = [
      const Color(0xFF0EA5E9), const Color(0xFF6366F1), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFFEF4444),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

class _SectionHeader2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader2({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.6)),
    ]);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.4));
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: selected ? Border.all(color: const Color(0xFFE2E8F0)) : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}