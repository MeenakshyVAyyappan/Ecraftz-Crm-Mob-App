import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _leaveTypes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        if (mounted) setState(() { _error = 'Not signed in'; _isLoading = false; });
        return;
      }

      final typesRes = await SupabaseService.client.from('leave_types').select();
      _leaveTypes = (typesRes as List).cast<Map<String, dynamic>>();

      final reqsRes = await SupabaseService.client
          .from('leave_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _leaveRequests = (reqsRes as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getLeaveTypeName(String? typeId) {
    if (typeId == null) return 'Unknown Leave';
    final type = _leaveTypes.firstWhere((t) => t['id']?.toString() == typeId, orElse: () => {});
    return type['name']?.toString() ?? 'Unknown Leave';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'rejected': return Colors.red;
      case 'pending':
      default: return const Color(0xFFFF9800);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFFE8F5E9);
      case 'rejected': return const Color(0xFFFFEBEE);
      case 'pending':
      default: return const Color(0xFFFFF3E0);
    }
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
            LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth < 400) {
                return Column(
                  children: [
                    _buildSubmitCard(),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: _buildApplyButton()),
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
            Row(
              children: [
                const Icon(Icons.history, size: 14, color: Color(0xFF2196F3)),
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
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
            else if (_leaveRequests.isEmpty)
              _buildEmptyState()
            else
              ..._leaveRequests.map((l) => _buildLeaveCard(l)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: isDark ? const Color(0xFF334155) : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No leave requests found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('You have not submitted any leave requests yet.',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
        ],
      ),
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
    final status = leave['status']?.toString() ?? 'pending';
    final isPending = status.toLowerCase() == 'pending';
    
    DateTime? start;
    DateTime? end;
    if (leave['start_date'] != null) start = DateTime.tryParse(leave['start_date'].toString());
    if (leave['end_date'] != null) end = DateTime.tryParse(leave['end_date'].toString());
    
    String dateRange = '';
    String duration = '';
    if (start != null && end != null) {
      dateRange = '${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}';
      final days = end.difference(start).inDays + 1;
      duration = '$days Day${days > 1 ? 's' : ''}';
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.calendar_today_outlined, color: Color(0xFF2196F3), size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBg(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_getLeaveTypeName(leave['leave_type_id']?.toString()).toUpperCase(),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 3),
          Text(dateRange,
              style: TextStyle(
                  fontSize: 11, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[500])),
          const SizedBox(height: 12),
          Divider(color: isDark ? AppTheme.borderDark : Colors.grey[200]),
          const SizedBox(height: 8),
          _leaveDetailRow('DURATION', duration),
          const SizedBox(height: 8),
          _leaveDetailRow('REASON', leave['reason']?.toString() ?? ''),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showApplyLeaveDialog(leave),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(color: Color(0xFF2196F3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('UPDATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteLeaveRequest(leave['id'].toString()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('DELETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ]
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
    
    String? selectedLeaveType = existing?['leave_type_id']?.toString();
    if (_leaveTypes.isNotEmpty && selectedLeaveType == null) {
      selectedLeaveType = _leaveTypes.first['id']?.toString();
    }
    
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    
    if (existing != null) {
      if (existing['start_date'] != null) {
        startDate = DateTime.tryParse(existing['start_date'].toString()) ?? DateTime.now();
      }
      if (existing['end_date'] != null) {
        endDate = DateTime.tryParse(existing['end_date'].toString()) ?? DateTime.now().add(const Duration(days: 1));
      }
    }

    final reasonCtrl = TextEditingController(text: existing?['reason']?.toString() ?? '');

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(existing != null ? 'UPDATE LEAVE' : 'APPLY FOR LEAVE',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black, size: 18)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LEAVE TYPE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8E9CB8) : Colors.grey)),
                    GestureDetector(
                      onTap: () => _showLeavePolicy(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF2196F3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Color(0xFF2196F3)),
                            SizedBox(width: 4),
                            Text('VIEW POLICY', style: TextStyle(fontSize: 10, color: Color(0xFF2196F3), fontWeight: FontWeight.w600)),
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _leaveTypes
                      .map((t) => DropdownMenuItem(value: t['id'].toString(), child: Text(t['name'].toString())))
                      .toList(),
                  onChanged: (v) => setInner(() => selectedLeaveType = v),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (ctx2, c) {
                  if (c.maxWidth < 280) {
                    return Column(children: [
                      _datePicker('START DATE', startDate, (d) => setInner(() => startDate = d)),
                      const SizedBox(height: 10),
                      _datePicker('END DATE', endDate, (d) => setInner(() => endDate = d)),
                    ]);
                  }
                  return Row(
                    children: [
                      Expanded(child: _datePicker('START DATE', startDate, (d) => setInner(() => startDate = d))),
                      const SizedBox(width: 10),
                      Expanded(child: _datePicker('END DATE', endDate, (d) => setInner(() => endDate = d))),
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600],
                          side: BorderSide(color: isDark ? AppTheme.borderDark : Colors.grey[400]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('CANCEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedLeaveType != null && reasonCtrl.text.isNotEmpty) {
                            Navigator.pop(ctx);
                            _submitLeave(
                              existing?['id']?.toString(),
                              selectedLeaveType!,
                              reasonCtrl.text,
                              startDate,
                              endDate,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Please fill all fields'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(existing != null ? 'UPDATE' : 'APPLY',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _datePicker(String label, DateTime date, Function(DateTime) onChanged) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitLeave(String? id, String leaveTypeId, String reason, DateTime start, DateTime end) async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception("Not signed in");

      final payload = {
        'user_id': user.id,
        'leave_type_id': leaveTypeId,
        'start_date': DateFormat('yyyy-MM-dd').format(start),
        'end_date': DateFormat('yyyy-MM-dd').format(end),
        'reason': reason,
        'status': 'pending',
        'organization_id': '00000000-0000-0000-0000-000000000000',
      };

      if (id != null) {
        await SupabaseService.client.from('leave_requests').update(payload).eq('id', id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request updated!'), backgroundColor: Color(0xFF4CAF50)));
      } else {
        await SupabaseService.client.from('leave_requests').insert(payload);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted!'), backgroundColor: Color(0xFF4CAF50)));
      }
      _fetchData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _deleteLeaveRequest(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this pending leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await SupabaseService.client.from('leave_requests').delete().eq('id', id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully'), backgroundColor: Color(0xFF4CAF50)));
                _fetchData();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            Text('• Apply at least 3 days in advance for planned leaves.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
        ],
      ),
    );
  }
}