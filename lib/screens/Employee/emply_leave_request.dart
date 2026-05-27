import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() =>
      _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  final List<Map<String, dynamic>> _leaveHistory = [
    {
      'type': 'CASUAL LEAVE',
      'startDate': 'MAY 19, 2026',
      'endDate': 'MAY 19, 2026',
      'duration': '1 Day',
      'reason': '"brother wedding"',
      'status': 'NEEDS INFO',
      'statusColor': const Color(0xFFFF9800),
      'statusBg': const Color(0xFFFFF3E0),
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
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Leave Requests',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Text(
                          'Manage your time off, track approvals, and view leave balances.',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Submit + Apply row
            LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth < 400) {
                return Column(
                  children: [
                    _buildSubmitCard(),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: _buildApplyButton()),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildSubmitCard()),
                  const SizedBox(width: 12),
                  _buildApplyButton(),
                ],
              );
            }),
            const SizedBox(height: 20),
            // Leave history
            Row(
              children: [
                const Icon(Icons.history,
                    size: 14, color: Color(0xFF2196F3)),
                const SizedBox(width: 6),
                Text('LEAVE HISTORY',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            ..._leaveHistory
                .map((l) => _buildLeaveCard(l))
                .toList(),
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
      title: Text('Leave Requests',
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
            style: TextStyle(
                fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        Icon(Icons.chevron_right, size: 14, color: isDark ? const Color(0xFF596780) : Colors.grey[400]),
        const Text('Leave requests',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF2196F3))),
      ],
    );
  }

  Widget _buildSubmitCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.borderDark) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUBMIT NEW REQUEST',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                Text('PLAN YOUR TIME OFF IN ADVANCE.',
                    style: TextStyle(
                        fontSize: 10, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton.icon(
      onPressed: () => _showApplyLeaveDialog(null),
      icon: const Icon(Icons.add, color: Colors.white, size: 16),
      label: const Text('APPLY FOR LEAVE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF2196F3), size: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: leave['statusBg'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(leave['status'],
                    style: TextStyle(
                        fontSize: 10,
                        color: leave['statusColor'],
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(leave['type'],
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 3),
          Text('${leave['startDate']} - ${leave['endDate']}',
              style: TextStyle(
                  fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 12),
          Divider(color: isDark ? AppTheme.borderDark : Colors.grey[200]),
          const SizedBox(height: 8),
          _leaveDetailRow('DURATION', leave['duration']),
          const SizedBox(height: 8),
          _leaveDetailRow('REASON', leave['reason']),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  _showApplyLeaveDialog(leave),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
                side: const BorderSide(
                    color: Color(0xFF2196F3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('UPDATE & RESUBMIT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaveDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500],
                letterSpacing: 0.3)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        ),
      ],
    );
  }

  void _showApplyLeaveDialog(Map<String, dynamic>? existing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? selectedLeaveType;
    bool isEmergency = false;
    DateTime startDate = existing != null
        ? DateTime(2026, 5, 19)
        : DateTime.now();
    DateTime endDate = existing != null
        ? DateTime(2026, 5, 19)
        : DateTime.now();
    final reasonCtrl = TextEditingController(
        text: existing != null
            ? existing['reason']
                .toString()
                .replaceAll('"', '')
            : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isDark ? const BorderSide(color: AppTheme.borderDark) : BorderSide.none),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        existing != null
                            ? 'UPDATE & RESUBMIT LEAVE'
                            : 'APPLY FOR LEAVE',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    IconButton(
                        onPressed: () =>
                            Navigator.pop(ctx),
                        icon: Icon(Icons.close,
                            color: isDark ? Colors.white : Colors.black,
                            size: 18)),
                  ],
                ),
                const SizedBox(height: 16),
                // Leave type
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LEAVE TYPE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                    GestureDetector(
                      onTap: () =>
                          _showLeavePolicy(ctx),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  const Color(0xFF2196F3)),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                                Icons.info_outline,
                                size: 12,
                                color: Color(0xFF2196F3)),
                            SizedBox(width: 4),
                            Text('VIEW POLICY',
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Color(0xFF2196F3),
                                    fontWeight:
                                        FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedLeaveType,
                  dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                  hint: Text('Select leave type',
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.black54)),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Casual Leave',
                    'Sick Leave',
                    'Annual Leave',
                    'Emergency Leave',
                    'Maternity Leave',
                  ]
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setInner(() => selectedLeaveType = v),
                ),
                const SizedBox(height: 14),
                // Dates
                LayoutBuilder(builder: (ctx2, c) {
                  if (c.maxWidth < 280) {
                    return Column(children: [
                      _datePicker(
                          'START DATE',
                          startDate,
                          (d) => setInner(
                              () => startDate = d)),
                      const SizedBox(height: 10),
                      _datePicker(
                          'END DATE',
                          endDate,
                          (d) => setInner(
                              () => endDate = d)),
                    ]);
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _datePicker(
                            'START DATE',
                            startDate,
                            (d) => setInner(
                                () => startDate = d))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _datePicker(
                            'END DATE',
                            endDate,
                            (d) => setInner(
                                () => endDate = d))),
                    ],
                  );
                }),
                const SizedBox(height: 14),
                Text('REASON FOR LEAVE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                // Emergency checkbox
                GestureDetector(
                  onTap: () => setInner(
                      () => isEmergency = !isEmergency),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFFFF3E0),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: isEmergency
                              ? Colors.red
                              : const Color(0xFFFFB74D)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            isEmergency
                                ? Icons.check_box
                                : Icons
                                    .check_box_outline_blank,
                            color: isEmergency
                                ? Colors.red
                                : const Color(0xFFE65100),
                            size: 18),
                        const SizedBox(width: 8),
                        const Text(
                            'THIS IS AN EMERGENCY LEAVE',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE65100),
                                fontWeight:
                                    FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                          side: BorderSide(
                              color: isDark ? AppTheme.borderDark : Colors.grey[400]!),
                          shape:
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8)),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12),
                        ),
                        child: const Text('CANCEL',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedLeaveType != null &&
                              reasonCtrl.text.isNotEmpty) {
                            Navigator.pop(ctx);
                            _submitLeave(
                                selectedLeaveType!,
                                reasonCtrl.text,
                                startDate,
                                endDate);
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Please fill all fields'),
                              backgroundColor: Colors.red,
                              behavior:
                                  SnackBarBehavior.floating,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2196F3),
                          shape:
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8)),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12),
                        ),
                        child: Text(
                            existing != null
                                ? 'UPDATE & RESUBMIT'
                                : 'APPLY FOR LEAVE',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _datePicker(
      String label, DateTime date, Function(DateTime) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: isDark
                      ? ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF2196F3),
                            onPrimary: Colors.white,
                            surface: AppTheme.bgCardDark,
                            onSurface: Colors.white,
                          ),
                          dialogBackgroundColor: AppTheme.bgCardDark,
                        )
                      : ThemeData.light(),
                  child: child!,
                );
              },
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppTheme.borderDark : Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitLeave(String type, String reason,
      DateTime start, DateTime end) {
    final months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    setState(() {
      _leaveHistory.insert(0, {
        'type': type.toUpperCase(),
        'startDate':
            '${months[start.month]} ${start.day}, ${start.year}',
        'endDate':
            '${months[end.month]} ${end.day}, ${end.year}',
        'duration':
            '${end.difference(start).inDays + 1} Day${end.difference(start).inDays > 0 ? 's' : ''}',
        'reason': '"$reason"',
        'status': 'PENDING',
        'statusColor': const Color(0xFF2196F3),
        'statusBg': const Color(0xFFE3F2FD),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Leave request submitted!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLeavePolicy(BuildContext ctx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark ? const BorderSide(color: AppTheme.borderDark) : BorderSide.none),
        title: Text('Leave Policy', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Casual Leave: 12 days/year', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text('• Sick Leave: 7 days/year', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text('• Annual Leave: 15 days/year', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text('• Emergency Leave: As needed', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 6),
            Text(
                '• Apply at least 3 days in advance for planned leaves.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Close')),
        ],
      ),
    );
  }
}