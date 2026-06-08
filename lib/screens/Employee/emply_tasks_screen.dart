import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../blocs/task/task_bloc.dart';
import '../../models/task_model.dart';
import '../../services/supabase_service.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  String _selectedStatus = 'All Status';
  int _viewMode = 0; // Default to Kanban view (0=kanban, 1=grid, 2=list)
  final _searchController = TextEditingController();
  String _searchQuery = '';
  User? _currentUser;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    context.read<TaskBloc>().add(LoadTasksEvent());
  }

  Future<void> _loadProfile() async {
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
          setState(() {
            _profile = Map<String, dynamic>.from(profileRows.first as Map);
          });
        }
      }
    } catch (_) {}
  }

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
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final currentId = _currentUser?.id.toString().trim().toLowerCase() ?? '';
          final currentFullName = _profile?['full_name']?.toString().trim().toLowerCase() ?? '';
          final currentEmail = _currentUser?.email?.toString().trim().toLowerCase() ?? '';

          bool containsValue(String source, String value) {
            return value.isNotEmpty && source.contains(value);
          }

          final myTasks = state.tasks.where((task) {
            final ownerRaw = task.owner?.toString().trim().toLowerCase() ?? '';
            if (ownerRaw.isNotEmpty) {
              final matchesOwner = ownerRaw == currentId ||
                  ownerRaw == currentFullName ||
                  ownerRaw == currentEmail ||
                  containsValue(ownerRaw, currentFullName) ||
                  containsValue(ownerRaw, currentEmail);
              if (!matchesOwner) return false;
            }
            return true;
          }).toList();

          final filteredTasks = myTasks.where((t) {
            final matchesSearch = t.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (t.parentProject != null && t.parentProject!.toLowerCase().contains(_searchQuery.toLowerCase()));
            if (!matchesSearch) return false;

            if (_selectedStatus == 'Pending') {
              return t.status == TaskStatus.toDo || t.status == TaskStatus.review;
            } else if (_selectedStatus == 'In Progress') {
              return t.status == TaskStatus.inProgress;
            } else if (_selectedStatus == 'Completed') {
              return t.status == TaskStatus.done;
            }
            return true; // 'All Status'
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(['Dashboard', 'Tasks']),
                const SizedBox(height: 12),
                Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Track and update your assigned tasks and self-made tasks.',
                  style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      LayoutBuilder(builder: (ctx, constraints) {
                        if (constraints.maxWidth < 450) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  hintStyle: TextStyle(color: isDark ? const Color(0xFF596780) : Colors.grey[400], fontSize: 13),
                                  prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400], size: 18),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                              Divider(color: isDark ? AppTheme.borderDark : Colors.grey[200]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatusDropdown(),
                                  _buildViewModeButtons(),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  hintStyle: TextStyle(color: isDark ? const Color(0xFF596780) : Colors.grey[400], fontSize: 13),
                                  prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400], size: 18),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusDropdown(),
                            const SizedBox(width: 8),
                            _buildViewModeButtons(),
                          ],
                        );
                      }),
                      Divider(height: 16, color: isDark ? AppTheme.borderDark : Colors.grey[200]),
                      _viewMode == 0 
                          ? _buildKanbanView(filteredTasks) 
                          : (filteredTasks.isEmpty ? _buildEmptyState() : _buildTasksContent(filteredTasks)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            if (e.key == 0) Icon(Icons.home_outlined, size: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
            if (e.key > 0) Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
            Text(
              e.value,
              style: TextStyle(
                fontSize: 11,
                color: isLast ? const Color(0xFF2196F3) : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          fontWeight: FontWeight.w500,
        ),
        items: ['All Status', 'Pending', 'In Progress', 'Completed']
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _selectedStatus = v ?? 'All Status'),
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
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: _viewMode == mode ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: _viewMode == mode ? const Color(0xFF2196F3) : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
        ),
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
          const SizedBox(height: 14),
          Text(
            'No tasks found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a new task to get started.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksContent(List<TaskItem> tasks) {
    if (_viewMode == 1) return _buildGridView(tasks);
    if (_viewMode == 0) return _buildKanbanView(tasks);
    return _buildListView(tasks);
  }

  Widget _buildListView(List<TaskItem> tasks) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildTaskListTile(tasks[i]),
    );
  }

  Widget _buildGridView(List<TaskItem> tasks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) => _buildTaskGridCard(tasks[i]),
    );
  }

  Widget _buildKanbanView(List<TaskItem> tasks) {
    final todo = tasks.where((t) => t.status == TaskStatus.toDo).toList();
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final review = tasks.where((t) => t.status == TaskStatus.review).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kanbanColumn('TO DO', todo, TaskStatus.toDo),
          const SizedBox(width: 12),
          _kanbanColumn('IN PROGRESS', inProgress, TaskStatus.inProgress),
          const SizedBox(width: 12),
          _kanbanColumn('REVIEW', review, TaskStatus.review),
          const SizedBox(width: 12),
          _kanbanColumn('DONE', done, TaskStatus.done),
        ],
      ),
    );
  }

  Widget _kanbanColumn(String title, List<TaskItem> list, TaskStatus targetStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DragTarget<TaskItem>(
      onWillAccept: (data) => data != null && data.status != targetStatus,
      onAccept: (task) {
        context.read<TaskBloc>().add(UpdateTaskStatusEvent(task.id, targetStatus));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 260, // Fixed width for columns
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered 
                ? (isDark ? Colors.white10 : const Color(0xFF2196F3).withOpacity(0.05))
                : (isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isHovered 
                    ? const Color(0xFF2196F3) 
                    : (isDark ? AppTheme.borderDark : Colors.grey[200]!),
                width: isHovered ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgCardDark : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: isDark ? Border.all(color: AppTheme.borderDark) : null,
                    ),
                    child: Text(
                      '${list.length}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: Text(
                    'Empty',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final task = list[i];
                    return LongPressDraggable<TaskItem>(
                      data: task,
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 240,
                          child: Opacity(
                            opacity: 0.8,
                            child: _buildTaskGridCard(task),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTaskGridCard(task),
                      ),
                      child: _buildTaskGridCard(task),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskListTile(TaskItem task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: task.priority.color.withOpacity(0.1),
            radius: 16,
            child: Icon(Icons.task_alt_rounded, color: task.priority.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.summary,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${task.parentProject ?? "N/A"} • Due ${task.dueDate != null ? DateFormat('MMM d, y').format(task.dueDate!).toUpperCase() : "TODAY"}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? task.status.color.withOpacity(0.2) : task.status.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.status.label,
                  style: TextStyle(fontSize: 9, color: task.status.color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? task.priority.color.withOpacity(0.2) : task.priority.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(fontSize: 8, color: task.priority.color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGridCard(TaskItem task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? task.priority.color.withOpacity(0.2) : task.priority.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(fontSize: 8, color: task.priority.color, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? task.status.color.withOpacity(0.2) : task.status.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.status.label,
                  style: TextStyle(fontSize: 8, color: task.status.color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.summary,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            task.parentProject ?? 'N/A',
            style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Due: ${task.dueDate != null ? DateFormat('MMM d, y').format(task.dueDate!) : "TODAY"}',
            style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final projCtrl = TextEditingController();
    String priority = 'MEDIUM';
    String status = 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: isDark ? const Border(top: BorderSide(color: AppTheme.borderDark)) : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Create New Task', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 16)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.black54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.black54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                        ),
                        items: ['LOW', 'MEDIUM', 'HIGH'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setInnerState(() => priority = v ?? 'MEDIUM'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                        ),
                        items: ['Pending', 'In Progress', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setInnerState(() => status = v ?? 'Pending'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && projCtrl.text.isNotEmpty) {
                      final tPriority = priority == 'HIGH'
                          ? TaskPriority.high
                          : (priority == 'LOW' ? TaskPriority.low : TaskPriority.medium);
                      
                      final tStatus = status == 'Completed'
                          ? TaskStatus.done
                          : (status == 'In Progress' ? TaskStatus.inProgress : TaskStatus.toDo);

                      final ownerName = _profile?['full_name']?.toString() ?? _currentUser?.email ?? 'Chimbu';
                      context.read<TaskBloc>().add(
                        AddTaskEvent(
                          TaskItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            summary: nameCtrl.text,
                            parentProject: projCtrl.text,
                            owner: ownerName.isNotEmpty ? ownerName : null,
                            dueDate: DateTime.now(),
                            status: tStatus,
                            priority: tPriority,
                          ),
                        ),
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF2196F3),
                  ),
                  child: const Text('Create Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}