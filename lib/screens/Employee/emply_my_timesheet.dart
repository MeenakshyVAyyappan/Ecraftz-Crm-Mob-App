import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MyTimesheetScreen extends StatefulWidget {
  const MyTimesheetScreen({super.key});

  @override
  State<MyTimesheetScreen> createState() => _MyTimesheetScreenState();
}

class _MyTimesheetScreenState extends State<MyTimesheetScreen> {
  String _selectedPeriod = 'Today';

  final List<Map<String, dynamic>> _sessions = [
    {
      'date': 'Wednesday, May 27th, 2026',
      'status': 'ACTIVE',
      'statusColor': const Color(0xFF4CAF50),
      'total': '0h 10m total',
      'signIn': '02:08 PM',
      'signOff': null,
      'breaks': [],
      'tasks': [
        {'name': 'Ui designing', 'type': 'SELF TASK', 'taskStatus': 'PENDING'},
        {
          'name': 'decvelop hello',
          'type': 'ASSIGNED TO ME',
          'taskStatus': 'PENDING'
        },
      ],
    },
    {
      'date': 'Wednesday, May 27th, 2026',
      'status': 'COMPLETED',
      'statusColor': const Color(0xFF2196F3),
      'total': '0h 1m total',
      'signIn': '01:50 PM',
      'signOff': '01:53 PM',
      'breaks': [],
      'tasks': [
        {'name': 'Ui designing', 'type': 'SELF TASK', 'taskStatus': 'PENDING'},
        {
          'name': 'decvelop hello',
          'type': 'ASSIGNED TO ME',
          'taskStatus': 'PENDING'
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 12),
            Text('My Timesheet',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(
                'Evaluate your daily sign-ins, breaks, and completed tasks.',
                style: TextStyle(
                    fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 16),
            ..._sessions.map((s) => _buildSessionCard(s)).toList(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF2C3E50), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('My Timesheet',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
      actions: [
        IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: isDark ? Colors.white : const Color(0xFF2C3E50)),
            onPressed: () {}),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: Text('EMPLOYEE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderOf(context), height: 1)),
    );
  }

  Widget _buildBreadcrumb() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.home_outlined, size: 12, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
        Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
        Text('Dashboard',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
        const Text('Timesheet',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF2196F3))),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            ['Today', 'This Week', 'This Month', 'All Time'].map((p) {
          final sel = _selectedPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : (isDark ? AppTheme.bgCardDark : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF2196F3)
                        : (isDark ? AppTheme.borderDark : Colors.grey[300]!)),
              ),
              child: Text(p,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? const Color(0xFF2196F3)
                          : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[600]))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 600) {
        return Column(
          children: [
            _summaryCard(
                Icons.access_time_outlined,
                'PRODUCTIVE TIME',
                '2h 47m',
                const Color(0xFF2196F3)),
            const SizedBox(height: 10),
            _summaryCard(Icons.check_box_outlined, 'TASKS DONE',
                '0', const Color(0xFF4CAF50)),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
              child: _summaryCard(
                  Icons.access_time_outlined,
                  'PRODUCTIVE TIME',
                  '2h 47m',
                  const Color(0xFF2196F3))),
          const SizedBox(width: 12),
          Expanded(
              child: _summaryCard(
                  Icons.check_box_outlined,
                  'TASKS DONE',
                  '0',
                  const Color(0xFF4CAF50))),
        ],
      );
    });
  }

  Widget _summaryCard(
      IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                        fontWeight: FontWeight.w600)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = session['status'] == 'ACTIVE';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.borderDark) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: session['statusColor']
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_outlined,
                      color: session['statusColor'], size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(session['date'],
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: session['statusColor']
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: Text(session['status'],
                                style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        session['statusColor'],
                                    fontWeight:
                                        FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text(session['total'],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppTheme.borderDark : Colors.grey[200]),
          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth < 600) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildShiftDetails(session),
                    const SizedBox(height: 12),
                    _buildBreakDetails(session),
                    const SizedBox(height: 12),
                    _buildTaskDetails(session),
                  ],
                );
              }
              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildShiftDetails(session)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildBreakDetails(session)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTaskDetails(session)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDetails(Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text('SHIFT DETAILS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 10),
        _shiftRow(Icons.login, const Color(0xFF4CAF50),
            'Sign In', session['signIn']),
        if (session['signOff'] != null) ...[
          const SizedBox(height: 8),
          _shiftRow(Icons.logout, Colors.red, 'Sign Off',
              session['signOff']),
        ],
      ],
    );
  }

  Widget _shiftRow(
      IconData icon, Color color, String label, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(time,
                style: TextStyle(
                    fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakDetails(Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text('BREAKS (0M)',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                    letterSpacing: 0.5)),
            Icon(Icons.coffee_outlined,
                size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 10),
        if ((session['breaks'] as List).isEmpty)
          Text('No breaks taken.',
              style: TextStyle(
                  fontSize: 11, color: isDark ? const Color(0xFF596780) : Colors.grey[400]))
        else
          ...(session['breaks'] as List).map((b) => Text(b,
              style:
                  TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
      ],
    );
  }

  Widget _buildTaskDetails(Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text('ASSIGNED & SELF TASKS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                    letterSpacing: 0.5)),
            Icon(Icons.edit_outlined,
                size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 10),
        ...(session['tasks'] as List<Map<String, dynamic>>)
            .map((t) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                          t['taskStatus'] == 'DONE'
                              ? Icons.check_box_outlined
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: t['taskStatus'] == 'DONE'
                              ? Colors.green
                              : (isDark ? const Color(0xFF8E9CB8) : Colors.grey[400])),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(t['name'],
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : const Color(0xFF1A1A2E))),
                            Text(
                                '${t['type']} • ${t['taskStatus']}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}