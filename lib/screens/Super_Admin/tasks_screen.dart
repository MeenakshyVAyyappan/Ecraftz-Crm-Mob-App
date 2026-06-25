// tasks_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../blocs/task/task_bloc.dart';
import '../../models/task_model.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter state
  final Set<TaskPriority> _selectedPriorities = {};
  final Set<TaskStatus> _selectedStatuses = {};

  static const Color _primary = Color(0xFF0EA5E9);

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  List<TaskItem> _filtered(List<TaskItem> tasks) => tasks.where((t) {
        // Search filter
        if (_searchQuery.isNotEmpty &&
            !t.summary.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        // Priority filter
        if (_selectedPriorities.isNotEmpty && !_selectedPriorities.contains(t.priority)) {
          return false;
        }
        // Status filter
        if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(t.status)) {
          return false;
        }
        return true;
      }).toList();

  int _unassignedCount(List<TaskItem> tasks) =>
      tasks.where((t) => t.owner == null || t.owner!.isEmpty).length;

  int _overloadedCount(List<TeamMember> members) =>
      members.where((m) => m.workloadStatus == 'Overloaded').length;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              'Collaborate and track progress across all project tasks.',
              style: TextStyle(fontSize: 11, color: _textSecondary),
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
          IconButton(
            icon: Icon(Icons.add, color: _primary),
            onPressed: () {
              final members = context.read<TaskBloc>().state.members;
              _showCreateTaskModal(context, members: members);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(state.tasks, state.members),
                _buildViewTabs(),
                Expanded(child: _buildBody(state.tasks, state.members)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<TaskItem> tasks, List<TeamMember> members) {
    final isWide = MediaQuery.of(context).size.width > 600;

    final importBtn = OutlinedButton.icon(
      onPressed: () => _showImportSheet(context),
      icon: const Icon(Icons.upload_file, size: 14),
      label: const Text('Import'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: BorderSide(color: _border),
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
        side: BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    final newTaskBtn = ElevatedButton.icon(
      onPressed: () => _showCreateTaskModal(context, members: members),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchField = Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: _textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMutedOf(context)),
          prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textMutedOf(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildBody(List<TaskItem> tasks, List<TeamMember> members) {
    switch (_viewIndex) {
      case 0: return _buildKanban(tasks, members);
      case 1: return _buildListView(tasks, members);
      case 2: return _buildWorkload(tasks, members);
      default: return _buildKanban(tasks, members);
    }
  }

  // ── KANBAN ────────────────────────────────────────────────────────────────

  Widget _buildKanban(List<TaskItem> allTasks, List<TeamMember> members) {
    final columns = TaskStatus.values;
    final filteredTasks = _filtered(allTasks);
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((s) {
              final colTasks = filteredTasks.where((t) => t.status == s).toList();
              return _KanbanColumn(
                status: s,
                tasks: colTasks,
                width: 240,
                onTaskTap: (t) => _showTaskDetail(context, t, members),
                onAddTask: () => _showCreateTaskModal(context, status: s, members: members),
              );
            }).toList(),
          ),
        );
      }
      // Mobile: vertical scroll with collapsible sections
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: columns.map((s) {
          final colTasks = filteredTasks.where((t) => t.status == s).toList();
          return _KanbanColumnMobile(
            status: s,
            tasks: colTasks,
            onTaskTap: (t) => _showTaskDetail(context, t, members),
            onAddTask: () => _showCreateTaskModal(context, status: s, members: members),
          );
        }).toList(),
      );
    });
  }

  // ── LIST VIEW ─────────────────────────────────────────────────────────────

  Widget _buildListView(List<TaskItem> allTasks, List<TeamMember> members) {
    final tasks = _filtered(allTasks);
    if (tasks.isEmpty) return _buildEmptyState('No tasks found');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TaskListTile(
        task: tasks[i],
        onTap: () => _showTaskDetail(context, tasks[i], members),
        onStatusChange: (s) {
          context.read<TaskBloc>().add(UpdateTaskStatusEvent(tasks[i].id, s));
        },
      ),
    );
  }

  // ── WORKLOAD ──────────────────────────────────────────────────────────────

  Widget _buildWorkload(List<TaskItem> allTasks, List<TeamMember> members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final stats = [
              _StatCard(label: 'TEAM SIZE', value: '${members.length} Members', icon: Icons.people_outline, iconColor: _primary),
              _StatCard(label: 'TOTAL BACKLOG EST.', value: '0 hrs', icon: Icons.access_time_outlined, iconColor: _primary),
              _StatCard(label: 'OVER-ALLOCATED TEAM', value: '${_overloadedCount(members)} Overloaded', icon: Icons.warning_amber_outlined, iconColor: const Color(0xFFF59E0B)),
              _StatCard(label: 'UNASSIGNED TASKS', value: '${_unassignedCount(allTasks)} Pending', icon: Icons.person_off_outlined, iconColor: const Color(0xFF6366F1)),
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
              Text(
                'Resource Allocation Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Sync Board'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: BorderSide(color: _border),
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
                children: members.map((m) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _WorkloadCard(
                      member: m,
                      onViewBreakout: () => _showWorkloadBreakout(context, m, members),
                    ),
                  ),
                )).toList(),
              );
            }
            return Column(
              children: members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkloadCard(
                  member: m,
                  onViewBreakout: () => _showWorkloadBreakout(context, m, members),
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
          Text(msg, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
        ],
      ),
    );
  }

  // ── MODALS ────────────────────────────────────────────────────────────────

  void _showCreateTaskModal(BuildContext context, {TaskStatus? status, List<TeamMember>? members}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTaskModal(
        initialStatus: status ?? TaskStatus.toDo,
        members: members ?? const [],
        onSubmit: (task) {
          context.read<TaskBloc>().add(AddTaskEvent(task));
        },
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskItem task, List<TeamMember> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailModal(
        task: task,
        members: members,
        onUpdate: () {
          context.read<TaskBloc>().add(UpdateTaskEvent(task));
        },
        onDelete: () {
          context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
        },
      ),
    );
  }

  void _showWorkloadBreakout(BuildContext context, TeamMember member, List<TeamMember> allMembers) {
    showDialog(
      context: context,
      builder: (_) => _WorkloadBreakoutDialog(
        member: member,
        allMembers: allMembers,
        onReallocate: (taskId, newOwner) {
          context.read<TaskBloc>().add(ReallocateTaskEvent(taskId, newOwner));
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    // Temporary copies so changes only apply when user taps Apply
    final tempPriorities = Set<TaskPriority>.from(_selectedPriorities);
    final tempStatuses = Set<TaskStatus>.from(_selectedStatuses);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        isDark: isDark,
        initialPriorities: tempPriorities,
        initialStatuses: tempStatuses,
        onApply: (priorities, statuses) {
          setState(() {
            _selectedPriorities
              ..clear()
              ..addAll(priorities);
            _selectedStatuses
              ..clear()
              ..addAll(statuses);
          });
        },
        onClear: () {
          setState(() {
            _selectedPriorities.clear();
            _selectedStatuses.clear();
          });
        },
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ImportDataDialog(
        onImport: () async {
          Navigator.pop(context);
          await _pickAndImportCsv(context);
        },
      ),
    );
  }

  Future<void> _pickAndImportCsv(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return;
      }

      final lines = content
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV must have a header row and at least one data row.')),
          );
        }
        return;
      }

      // Parse header
      final headers = _parseCsvLine(lines.first)
          .map((h) => h.trim().toLowerCase())
          .toList();

      final int titleIdx = headers.indexWhere((h) => h == 'title' || h == 'summary' || h == 'task');
      final int statusIdx = headers.indexWhere((h) => h == 'status');
      final int priorityIdx = headers.indexWhere((h) => h == 'priority');
      final int ownerIdx = headers.indexWhere((h) => h == 'owner' || h == 'assignee');
      final int projectIdx = headers.indexWhere((h) => h == 'project' || h == 'parent project');
      final int dueDateIdx = headers.indexWhere((h) => h == 'due date' || h == 'due_date' || h == 'duedate');
      final int descIdx = headers.indexWhere((h) => h == 'description' || h == 'desc');

      if (titleIdx == -1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV must have a "title" or "summary" column.')),
          );
        }
        return;
      }

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final cols = _parseCsvLine(lines[i]);
        if (cols.isEmpty) continue;
        String col(int idx) => (idx >= 0 && idx < cols.length) ? cols[idx].trim() : '';

        final title = col(titleIdx);
        if (title.isEmpty) continue;

        final task = TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          summary: title,
          description: col(descIdx),
          parentProject: col(projectIdx).isNotEmpty ? col(projectIdx) : null,
          owner: col(ownerIdx).isNotEmpty ? col(ownerIdx) : null,
          dueDate: dueDateIdx >= 0 ? DateTime.tryParse(col(dueDateIdx)) : null,
          status: _parseStatus(col(statusIdx)),
          priority: _parsePriority(col(priorityIdx)),
        );
        if (context.mounted) {
          context.read<TaskBloc>().add(AddTaskEvent(task));
        }
        imported++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported task${imported == 1 ? '' : 's'} successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  TaskStatus _parseStatus(String s) {
    switch (s.toLowerCase().replaceAll(' ', '_')) {
      case 'in_progress': return TaskStatus.inProgress;
      case 'review': return TaskStatus.review;
      case 'done': return TaskStatus.done;
      default: return TaskStatus.toDo;
    }
  }

  TaskPriority _parsePriority(String p) {
    switch (p.toLowerCase()) {
      case 'high': return TaskPriority.high;
      case 'low': return TaskPriority.low;
      default: return TaskPriority.medium;
    }
  }
}

// ─── FILTER SHEET ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final bool isDark;
  final Set<TaskPriority> initialPriorities;
  final Set<TaskStatus> initialStatuses;
  final void Function(Set<TaskPriority>, Set<TaskStatus>) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.isDark,
    required this.initialPriorities,
    required this.initialStatuses,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<TaskPriority> _priorities;
  late Set<TaskStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _priorities = Set.from(widget.initialPriorities);
    _statuses = Set.from(widget.initialStatuses);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    const primary = Color(0xFF0EA5E9);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filter Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priorities.clear();
                    _statuses.clear();
                  });
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Priority',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskPriority.values.map((p) {
              final selected = _priorities.contains(p);
              return FilterChip(
                label: Text(p.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected ? p.color : textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                selected: selected,
                onSelected: (v) => setState(() => v ? _priorities.add(p) : _priorities.remove(p)),
                backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                selectedColor: p.bgColor,
                checkmarkColor: p.color,
                side: BorderSide(color: selected ? p.color : AppTheme.borderOf(context)),
                showCheckmark: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Status',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map((s) {
              final selected = _statuses.contains(s);
              return FilterChip(
                label: Text(s.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected ? s.color : textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                selected: selected,
                onSelected: (v) => setState(() => v ? _statuses.add(s) : _statuses.remove(s)),
                backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                selectedColor: s.bgColor,
                checkmarkColor: s.color,
                side: BorderSide(color: selected ? s.color : AppTheme.borderOf(context)),
                showCheckmark: true,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_priorities, _statuses);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _priorities.isEmpty && _statuses.isEmpty ? 'Show All Tasks' : 'Apply Filters',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── IMPORT DATA DIALOG ───────────────────────────────────────────────────────

class _ImportDataDialog extends StatelessWidget {
  final VoidCallback onImport;
  const _ImportDataDialog({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);
    const primary = Color(0xFF0EA5E9);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primary.withOpacity(0.25)),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Data to Tasks',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Bulk migration wizard for production-grade data ingestion.',
                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 20, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: GestureDetector(
                onTap: onImport,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_rounded, size: 40, color: textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Excel or CSV File',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drop your migration file here or click to browse.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onImport,
                        icon: Icon(Icons.folder_open_outlined,
                            size: 16, color: textPrimary),
                        label: Text(
                          'Choose File',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 24, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── KANBAN COLUMN (Wide) ─────────────────────────────────────────────────────

class _KanbanColumn extends StatefulWidget {
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
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DragTarget<TaskItem>(
      onWillAccept: (task) => task != null && task.status != widget.status,
      onAccept: (task) {
        context.read<TaskBloc>().add(UpdateTaskStatusEvent(task.id, widget.status));
        setState(() {
          _isHovered = false;
        });
      },
      onMove: (details) {
        if (!_isHovered) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onLeave: (task) {
        setState(() {
          _isHovered = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 14),
          padding: _isHovered ? const EdgeInsets.all(4) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: _isHovered 
                ? (isDark ? Colors.white10 : const Color(0xFF2196F3).withOpacity(0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: _isHovered 
                ? Border.all(color: const Color(0xFF2196F3), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColumnHeader(status: widget.status, count: widget.tasks.length),
              const SizedBox(height: 10),
              ...widget.tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LongPressDraggable<TaskItem>(
                  data: t,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: widget.width,
                      child: Opacity(
                        opacity: 0.8,
                        child: _TaskCard(task: t, onTap: () {}),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _TaskCard(task: t, onTap: () {}),
                  ),
                  child: _TaskCard(task: t, onTap: () => widget.onTaskTap(t)),
                ),
              )),
              _AddTaskButton(onTap: widget.onAddTask),
            ],
          ),
        );
      },
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DragTarget<TaskItem>(
      onWillAccept: (task) => task != null && task.status != widget.status,
      onAccept: (task) {
        context.read<TaskBloc>().add(UpdateTaskStatusEvent(task.id, widget.status));
        setState(() {
          _isHovered = false;
        });
      },
      onMove: (details) {
        if (!_isHovered) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onLeave: (task) {
        setState(() {
          _isHovered = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? Colors.white10 : const Color(0xFF2196F3).withOpacity(0.05))
                : (isDark ? AppTheme.bgCardDark : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _isHovered 
                    ? const Color(0xFF2196F3) 
                    : AppTheme.borderOf(context),
                width: _isHovered ? 2 : 1),
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: Text('${widget.tasks.length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context))),
                      ),
                      const Spacer(),
                      Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18, color: AppTheme.textMutedOf(context)),
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
                        child: LongPressDraggable<TaskItem>(
                          data: t,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 60,
                              child: Opacity(
                                opacity: 0.8,
                                child: _TaskCard(task: t, onTap: () {}),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _TaskCard(task: t, onTap: () {}),
                          ),
                          child: _TaskCard(task: t, onTap: () => widget.onTaskTap(t)),
                        ),
                      )),
                      _AddTaskButton(onTap: widget.onAddTask),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final TaskStatus status;
  final int count;
  const _ColumnHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(status.label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context))),
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
          border: Border.all(color: AppTheme.borderOf(context), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: AppTheme.textMutedOf(context)),
            const SizedBox(width: 4),
            Text('Add Task', style: TextStyle(fontSize: 12, color: AppTheme.textMutedOf(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderOf(context)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
            if (task.parentProject != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.parentProject!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
                  ),
                ],
              ),
            ],
            if (task.owner != null) ...[
              const SizedBox(height: 4),
              Text('Lead: ${task.owner}', style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context))),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: AppTheme.textMutedOf(context)),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderOf(context)),
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context),
                      decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                    )),
                  if (task.parentProject != null)
                    Text(task.parentProject!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
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
                    Text(member.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
                    Text(member.role, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
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
          Text('WEEKLY LOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMutedOf(context), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              RichText(text: TextSpan(
                children: [
                  TextSpan(text: '${member.weeklyLoad}h', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
                  TextSpan(text: ' / ${member.weeklyLimit}h limit', style: TextStyle(fontSize: 12, color: AppTheme.textMutedOf(context))),
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
              backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(member.workloadColor),
            ),
          ),
          const SizedBox(height: 14),
          Text('TASK STATUS DISTRIBUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMutedOf(context), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          if (taskDist.isEmpty)
            Text('No tasks assigned', style: TextStyle(fontSize: 11, color: AppTheme.textMutedOf(context)))
          else
            Wrap(
              spacing: 10,
              children: taskDist.entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Text('${e.key.label}: ${e.value}', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedOf(context), letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
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
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parentProjectField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('PARENT PROJECT'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String?>(
          value: _parentProject,
          isExpanded: true,
          style: TextStyle(fontSize: 12, color: _textPrimary),
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          decoration: _dec('Link to project'),
          items: [
            DropdownMenuItem(value: null, child: Text('Link to project', style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis)),
            ..._projects.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis))),
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
          style: TextStyle(fontSize: 12, color: _textPrimary),
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          decoration: _dec('Unassigned'),
          items: [
            DropdownMenuItem(value: null, child: Text('Unassigned', style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis)),
            ...widget.members.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name, style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis))),
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
          style: TextStyle(fontSize: 12, color: _textPrimary),
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          decoration: _dec(''),
          items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis))).toList(),
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
          style: TextStyle(fontSize: 12, color: _textPrimary),
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          decoration: _dec(''),
          items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label[0] + p.label.substring(1).toLowerCase(), style: TextStyle(fontSize: 12, color: _textPrimary), overflow: TextOverflow.ellipsis))).toList(),
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90,
        ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Create New Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
                    Text('Add a new task to your workspace. You can optionally link it to a project.',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, size: 20, color: _textSecondary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
          Divider(height: 20, color: _border),
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
                    style: TextStyle(fontSize: 13, color: _textPrimary),
                    decoration: _dec('e.g. Design system audit...'),
                  ),
                  const SizedBox(height: 12),
                  _Label('DETAILED DESCRIPTION'),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13, color: _textPrimary),
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
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context),
                            child: child!,
                          );
                        },
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMutedOf(context)),
                        const SizedBox(width: 8),
                        Text(
                          _dueDate != null ? '${_dueDate!.day}-${_dueDate!.month}-${_dueDate!.year}' : 'dd-mm-yyyy',
                          style: TextStyle(fontSize: 13, color: _dueDate != null ? _textPrimary : AppTheme.textMutedOf(context)),
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
    hintText: hint, hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMutedOf(context)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(child: Text(t.summary, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  onPressed: () { widget.onDelete(); Navigator.pop(context); }),
                IconButton(icon: Icon(Icons.close, size: 20, color: textMuted), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Divider(height: 16, color: border),
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
                Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskStatus.values.map((s) => GestureDetector(
                    onTap: () => setState(() { t.status = s; widget.onUpdate(); }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.status == s ? s.bgColor : (isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC)),
                        border: Border.all(color: t.status == s ? s.color : (isDark ? AppTheme.bgBaseDark : const Color(0xFFE2E8F0))),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.status == s ? s.color : textMuted)),
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
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: textMuted))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return Dialog(
      backgroundColor: bg,
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
                  Text(widget.member.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                  Text('${widget.member.role} — ${widget.member.department} — WORKLOAD BREAKOUT',
                    style: TextStyle(fontSize: 10, color: textMuted)),
                ])),
                IconButton(icon: Icon(Icons.close, size: 18, color: textMuted), onPressed: () => Navigator.pop(context)),
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
                      color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GLOBAL WORKSPACE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = MediaQuery.of(context).size.width <= 600;
                              final taskDetailsCol = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.summary, style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    decoration: t.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                                  )),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    _StatusPill(status: t.status),
                                    const SizedBox(width: 6),
                                    Text('0', style: TextStyle(fontSize: 11, color: textMuted)),
                                  ]),
                                ],
                              );

                              final reallocateCol = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('REALLOCATE TASK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: _selectedOwners[t.id],
                                    isExpanded: true,
                                    style: TextStyle(fontSize: 12, color: textPrimary),
                                    dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                                    ),
                                    items: widget.allMembers.map((m) => DropdownMenuItem(
                                      value: m.name,
                                      child: Text(
                                        m.name == widget.member.name ? '${m.name} (Current)' : m.name,
                                        style: TextStyle(fontSize: 12, color: textPrimary),
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
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
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
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? (isDark ? AppTheme.bgCardDark : Colors.white) : Colors.transparent,
          border: selected ? Border.all(color: AppTheme.borderOf(context)) : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? const Color(0xFF0EA5E9) : AppTheme.textMutedOf(context)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? AppTheme.textPrimaryOf(context) : AppTheme.textMutedOf(context))),
          ],
        ),
      ),
    );
  }
}
