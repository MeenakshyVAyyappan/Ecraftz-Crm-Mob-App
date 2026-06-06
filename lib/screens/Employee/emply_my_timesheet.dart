import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bde_report_model.dart';
import '../../services/bde_report_service.dart';
import '../../theme/app_theme.dart';

class MyTimesheetScreen extends StatefulWidget {
  const MyTimesheetScreen({super.key});

  @override
  State<MyTimesheetScreen> createState() => _MyTimesheetScreenState();
}

class _MyTimesheetScreenState extends State<MyTimesheetScreen> {
  final TextEditingController _staffNameController = TextEditingController(text: 'Tony Stark');
  final TextEditingController _databasePlannedController = TextEditingController();
  final TextEditingController _databaseCountController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  final TextEditingController _justDialController = TextEditingController();
  final TextEditingController _otherPlatformsController = TextEditingController();
  final TextEditingController _meetingsScheduledController = TextEditingController();
  final TextEditingController _meetingsAttendedController = TextEditingController();
  final TextEditingController _callsConnectedController = TextEditingController();
  final TextEditingController _amountCollectedController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  DateTime _reportDate = DateTime.now();
  String _selectedPeriod = 'Today';
  DateTimeRange? _selectedRange;
  final _service = BdeReportService.instance;

  List<BdeReportEntry> get _historyReports {
    if (_selectedRange != null) {
      return _service.filterByRange(_selectedRange!.start, _selectedRange!.end);
    }
    return _service.filterByPeriod(_selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = _historyReports;
    final totalReports = reports.length;
    final meetingsScheduled = reports.fold<int>(0, (sum, entry) => sum + entry.login.meetingsScheduled);
    final amountCollected = reports.fold<double>(0.0, (sum, entry) => sum + (entry.logout?.amountCollected ?? 0.0));

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
                'Submit your daily login and logout self-report. All entries are stored dynamically and can be reviewed with filters.',
                style: TextStyle(
                    fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
            const SizedBox(height: 20),
            _buildSummaryCards(totalReports, meetingsScheduled, amountCollected),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildReportForms()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildHistoryPanel()),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportForms(),
                  const SizedBox(height: 16),
                  _buildHistoryPanel(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportForms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Login Report', 'Capture planned leads and scheduled meetings before the shift.'),
        const SizedBox(height: 12),
        _buildLoginForm(),
        const SizedBox(height: 20),
        _buildSectionHeader('Logout Report', 'Record meetings, calls, collection and remarks after the shift.'),
        const SizedBox(height: 12),
        _buildLogoutForm(),
      ],
    );
  }

  Widget _buildHistoryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Report History', 'Filter your entries by period or date range and view details in one place.'),
        const SizedBox(height: 12),
        _buildFilterRow(),
        const SizedBox(height: 12),
        _buildHistoryList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600])),
      ],
    );
  }

  Widget _buildFilterRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Today', 'This Week', 'This Month', 'All'].map((period) {
            final selected = _selectedPeriod == period && _selectedRange == null;
            return ChoiceChip(
              label: Text(period),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedRange = null;
                  _selectedPeriod = period;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(_selectedRange == null
                    ? 'Choose date range'
                    : '${DateFormat.yMMMd().format(_selectedRange!.start)} - ${DateFormat.yMMMd().format(_selectedRange!.end)}'),
              ),
            ),
            if (_selectedRange != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => setState(() => _selectedRange = null),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (result != null) {
      setState(() {
        _selectedRange = result;
      });
    }
  }

  Widget _buildHistoryList() {
    final reports = _historyReports;
    if (reports.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Center(
          child: Text('No self-report history found for this range.',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : Colors.grey[600])),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return GestureDetector(
          onTap: () => _showReportDetails(report),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(report.staffName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: report.isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(report.isComplete ? 'COMPLETE' : 'INCOMPLETE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: report.isComplete ? const Color(0xFF166534) : const Color(0xFF92400E))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(DateFormat.yMMMMd().format(report.reportDate),
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  _smallStat(label: 'Planned', value: '${report.login.databasePlanned}'),
                  _smallStat(label: 'DB Count', value: '${report.login.databaseCount}'),
                  _smallStat(label: 'Social', value: '${report.login.socialMediaLeads}'),
                  _smallStat(label: 'Just Dial', value: '${report.login.justDialLeads}'),
                  _smallStat(label: 'Meetings', value: '${report.login.meetingsScheduled}'),
                  _smallStat(label: 'Collected', value: '₹${(report.logout?.amountCollected ?? 0).toStringAsFixed(0)}'),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _smallStat({required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF334155))),
    );
  }

  void _showReportDetails(BdeReportEntry report) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Report Details — ${DateFormat.yMMMd().format(report.reportDate)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Staff', report.staffName),
              const SizedBox(height: 8),
              _detailRow('Database Planned', report.login.databasePlanned.toString()),
              _detailRow('Database Count', report.login.databaseCount.toString()),
              _detailRow('Social Media Leads', report.login.socialMediaLeads.toString()),
              _detailRow('Just Dial Leads', report.login.justDialLeads.toString()),
              _detailRow('Other Platforms', report.login.otherPlatformLeads.toString()),
              _detailRow('Meetings Scheduled', report.login.meetingsScheduled.toString()),
              const Divider(height: 24),
              _detailRow('Meetings Attended', '${report.logout?.meetingsAttended ?? 0}'),
              _detailRow('Calls Connected', '${report.logout?.callsConnected ?? 0}'),
              _detailRow('Amount Collected', '₹${(report.logout?.amountCollected ?? 0).toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Text('Remarks', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Text(report.logout?.remarks ?? 'No remarks provided', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : Colors.grey[700])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_staffNameController, 'Staff Name', helper: 'Employee name or auto-detected user'),
          const SizedBox(height: 12),
          _buildDatePicker(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildTextField(_databasePlannedController, 'Database Planned', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_databaseCountController, 'Database Count', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildTextField(_socialMediaController, 'Social Media Leads', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_justDialController, 'Just Dial Leads', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildTextField(_otherPlatformsController, 'Other Platforms', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_meetingsScheduledController, 'Meetings Scheduled', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saveLoginReport,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
              child: const Text('Save Login Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _buildTextField(_meetingsAttendedController, 'Meetings Attended', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_callsConnectedController, 'Calls Connected', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          _buildTextField(_amountCollectedController, 'Amount Collected', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField(_remarksController, 'Remarks', maxLines: 4),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saveLogoutReport,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Save Logout Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickReportDate,
      child: AbsorbPointer(
        child: TextField(
          controller: TextEditingController(text: DateFormat.yMMMMd().format(_reportDate)),
          decoration: InputDecoration(
            labelText: 'Report Date',
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? helper, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _reportDate = picked);
    }
  }

  void _saveLoginReport() {
    final staffName = _staffNameController.text.trim();
    if (staffName.isEmpty) {
      _showMessage('Please enter the staff name.');
      return;
    }
    final login = BdeLoginDetails(
      staffName: staffName,
      reportDate: _reportDate,
      databasePlanned: int.tryParse(_databasePlannedController.text.trim()) ?? 0,
      databaseCount: int.tryParse(_databaseCountController.text.trim()) ?? 0,
      socialMediaLeads: int.tryParse(_socialMediaController.text.trim()) ?? 0,
      justDialLeads: int.tryParse(_justDialController.text.trim()) ?? 0,
      otherPlatformLeads: int.tryParse(_otherPlatformsController.text.trim()) ?? 0,
      meetingsScheduled: int.tryParse(_meetingsScheduledController.text.trim()) ?? 0,
    );
    _service.addOrUpdateLogin(login);
    _showMessage('Login report saved successfully.');
    setState(() {});
  }

  void _saveLogoutReport() {
    final staffName = _staffNameController.text.trim();
    if (staffName.isEmpty) {
      _showMessage('Please enter the staff name before saving logout data.');
      return;
    }
    final logout = BdeLogoutDetails(
      meetingsAttended: int.tryParse(_meetingsAttendedController.text.trim()) ?? 0,
      callsConnected: int.tryParse(_callsConnectedController.text.trim()) ?? 0,
      amountCollected: double.tryParse(_amountCollectedController.text.trim()) ?? 0.0,
      remarks: _remarksController.text.trim(),
    );
    _service.addOrUpdateLogout(staffName, _reportDate, logout);
    _showMessage('Logout report saved successfully.');
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Widget _buildSummaryCards(int totalReports, int meetingsScheduled, double amountCollected) {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth < 720) {
        return Column(
          children: [
            _statCard(Icons.list_alt_rounded, 'REPORTS SUBMITTED', '$totalReports', const Color(0xFF2196F3)),
            const SizedBox(height: 10),
            _statCard(Icons.meeting_room_rounded, 'MEETINGS SCHEDULED', '$meetingsScheduled', const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            _statCard(Icons.currency_rupee, 'AMOUNT COLLECTED', '₹${amountCollected.toStringAsFixed(0)}', const Color(0xFF10B981)),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _statCard(Icons.list_alt_rounded, 'REPORTS SUBMITTED', '$totalReports', const Color(0xFF2196F3))),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.meeting_room_rounded, 'MEETINGS SCHEDULED', '$meetingsScheduled', const Color(0xFF4CAF50))),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.currency_rupee, 'AMOUNT COLLECTED', '₹${amountCollected.toStringAsFixed(0)}', const Color(0xFF10B981))),
        ],
      );
    });
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(fontSize: 20, color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
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