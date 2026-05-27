import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({super.key});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  String _selectedStatus = 'All Status';
  int _viewMode = 2; // Default to list view (0=kanban, 1=grid, 2=list)
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tasks = [
    {
      'name': 'UI Designing & Responsiveness',
      'project': 'CRM Mobile App',
      'priority': 'HIGH',
      'priorityColor': const Color(0xFFEF5350),
      'priorityBg': const Color(0xFFFFEBEE),
      'status': 'In Progress',
      'statusColor': const Color(0xFFFF9800),
      'statusBg': const Color(0xFFFFF3E0),
      'dueDate': 'MAY 30, 2026',
    },
    {
      'name': 'Develop employee auth flow',
      'project': 'CRM Backend',
      'priority': 'HIGH',
      'priorityColor': const Color(0xFFEF5350),
      'priorityBg': const Color(0xFFFFEBEE),
      'status': 'Completed',
      'statusColor': const Color(0xFF4CAF50),
      'statusBg': const Color(0xFFE8F5E9),
      'dueDate': 'MAY 26, 2026',
    },
    {
      'name': 'Scheduler calendar integration',
      'project': 'CRM Mobile App',
      'priority': 'MEDIUM',
      'priorityColor': const Color(0xFFFFB74D),
      'priorityBg': const Color(0xFFFFF8E1),
      'status': 'Pending',
      'statusColor': Colors.grey,
      'statusBg': const Color(0xFFF5F5F5),
      'dueDate': 'JUNE 5, 2026',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _tasks.where((t) {
      final matchesSearch = t['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t['project'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All Status' ||
          t['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
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
      body: SingleChildScrollView(
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
                  _filtered.isEmpty ? _buildEmptyState() : _buildTasksContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white)),
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
          GestureDetector(
            onTap: () => _showAddTaskDialog(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF2196F3), size: 30),
            ),
          ),
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

  Widget _buildTasksContent() {
    if (_viewMode == 1) return _buildGridView();
    if (_viewMode == 0) return _buildKanbanView();
    return _buildListView();
  }

  Widget _buildListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildTaskListTile(_filtered[i]),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _buildTaskGridCard(_filtered[i]),
    );
  }

  Widget _buildKanbanView() {
    // Kanban grouped layout
    final pending = _filtered.where((t) => t['status'] == 'Pending').toList();
    final inProgress = _filtered.where((t) => t['status'] == 'In Progress').toList();
    final completed = _filtered.where((t) => t['status'] == 'Completed').toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          children: [
            _kanbanColumn('PENDING', pending),
            const SizedBox(height: 16),
            _kanbanColumn('IN PROGRESS', inProgress),
            const SizedBox(height: 16),
            _kanbanColumn('COMPLETED', completed),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _kanbanColumn('PENDING', pending)),
          const SizedBox(width: 12),
          Expanded(child: _kanbanColumn('IN PROGRESS', inProgress)),
          const SizedBox(width: 12),
          Expanded(child: _kanbanColumn('COMPLETED', completed)),
        ],
      );
    });
  }

  Widget _kanbanColumn(String title, List<Map<String, dynamic>> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: isDark ? Border.all(color: AppTheme.borderDark) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCardDark : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: isDark ? Border.all(color: AppTheme.borderDark) : null,
                ),
                child: Text(
                  '${list.length}',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Text(
                'Empty',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildTaskGridCard(list[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskListTile(Map<String, dynamic> task) {
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
            backgroundColor: task['priorityColor'].withOpacity(0.1),
            radius: 16,
            child: Icon(Icons.task_alt_outlined, color: task['priorityColor'], size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['name'],
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${task['project']} • Due ${task['dueDate']}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? task['statusBg'].withOpacity(0.2) : task['statusBg'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['status'],
                  style: TextStyle(fontSize: 9, color: task['statusColor'], fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? task['priorityBg'].withOpacity(0.2) : task['priorityBg'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['priority'],
                  style: TextStyle(fontSize: 8, color: task['priorityColor'], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGridCard(Map<String, dynamic> task) {
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
                  color: isDark ? task['priorityBg'].withOpacity(0.2) : task['priorityBg'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['priority'],
                  style: TextStyle(fontSize: 8, color: task['priorityColor'], fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? task['statusBg'].withOpacity(0.2) : task['statusBg'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['status'],
                  style: TextStyle(fontSize: 8, color: task['statusColor'], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              task['name'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task['project'],
            style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Due: ${task['dueDate']}',
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
                      Color pColor = const Color(0xFFFFB74D);
                      Color pBg = const Color(0xFFFFF8E1);
                      if (priority == 'HIGH') {
                        pColor = const Color(0xFFEF5350);
                        pBg = const Color(0xFFFFEBEE);
                      } else if (priority == 'LOW') {
                        pColor = const Color(0xFF4CAF50);
                        pBg = const Color(0xFFE8F5E9);
                      }

                      Color sColor = Colors.grey;
                      Color sBg = const Color(0xFFF5F5F5);
                      if (status == 'In Progress') {
                        sColor = const Color(0xFFFF9800);
                        sBg = const Color(0xFFFFF3E0);
                      } else if (status == 'Completed') {
                        sColor = const Color(0xFF4CAF50);
                        sBg = const Color(0xFFE8F5E9);
                      }

                      setState(() {
                        _tasks.insert(0, {
                          'name': nameCtrl.text,
                          'project': projCtrl.text,
                          'priority': priority,
                          'priorityColor': pColor,
                          'priorityBg': pBg,
                          'status': status,
                          'statusColor': sColor,
                          'statusBg': sBg,
                          'dueDate': 'TODAY',
                        });
                      });
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