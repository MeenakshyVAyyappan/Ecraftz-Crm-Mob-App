import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_punch_model.dart';
import '../../models/wfh_record_model.dart';
import '../../models/employee_attendance_matrix.dart';
import '../../services/attendance_repository.dart';
import '../../services/attendance_export_service.dart';
import 'widgets/monthly_matrix_table.dart';
import 'widgets/daily_snapshot_cards.dart';

/// Normalize a DateTime to midnight
DateTime _toDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;
  String? _errorMessage;

  // All dates midnight-normalised
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _selectedSummaryDate;

  List<Map<String, dynamic>> _profiles = [];
  Map<String, Map<String, DailyStatus>> _matrixData = {};

  final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final now = _toDay(DateTime.now());
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Full current month
    _selectedSummaryDate = now.isAfter(_endDate) ? _endDate : now;

    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────── Data Fetching ───────────────────────────────

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _profiles = await AttendanceRepository.instance.fetchProfiles();
      final punches = await AttendanceRepository.instance
          .fetchBiometricLogs(_startDate, _endDate);
      final wfhRecords = await AttendanceRepository.instance
          .fetchWfhRecords(_startDate, _endDate);
      _buildMatrix(punches, wfhRecords);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildMatrix(
      List<AttendancePunch> punches, List<WfhRecord> wfhRecords) {
    _matrixData = {};

    final Set<String> wfhSet = {};
    for (final wfh in wfhRecords) {
      final ds = DateFormat('yyyy-MM-dd').format(wfh.date);
      wfhSet.add('${wfh.biometricPin}|$ds');
    }

    final Map<String, Map<String, List<AttendancePunch>>> grouped = {};
    for (final punch in punches) {
      if (punch.pin == null) continue;
      final ds = DateFormat('yyyy-MM-dd').format(punch.punchTime);
      grouped.putIfAbsent(punch.pin!, () => {});
      grouped[punch.pin!]!.putIfAbsent(ds, () => []);
      grouped[punch.pin!]![ds]!.add(punch);
    }

    for (final profile in _profiles) {
      final pin = profile['biometric_id']?.toString();
      if (pin == null) continue;
      _matrixData[pin] = {};
      for (DateTime d = _startDate;
          !d.isAfter(_endDate);
          d = d.add(const Duration(days: 1))) {
        final ds = DateFormat('yyyy-MM-dd').format(d);
        final dayPunches = grouped[pin]?[ds] ?? [];
        _matrixData[pin]![ds] = DailyStatus.calculate(
          pin: pin,
          date: d,
          dayPunches: dayPunches,
          wfhSet: wfhSet,
        );
      }
    }
  }

  // ─────────────────────────── Individual Date Pickers ────────────────────

  /// Pick only the FROM date
  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 3),
      lastDate: _endDate, // cannot exceed current end date
      helpText: 'Select FROM date',
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = _toDay(picked);
        // snap summary date into range if needed
        if (_selectedSummaryDate.isBefore(_startDate)) {
          _selectedSummaryDate = _startDate;
        }
      });
      await _fetchData();
    }
  }

  /// Pick only the TO date
  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // cannot go before from date
      lastDate: DateTime(now.year + 1),
      helpText: 'Select TO date',
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = _toDay(picked);
        if (_selectedSummaryDate.isAfter(_endDate)) {
          _selectedSummaryDate = _endDate;
        }
      });
      await _fetchData();
    }
  }

  // ─────────────────────────── WFH Toggle ─────────────────────────────────

  Future<void> _handleWfhToggle(String pin, DateTime date, bool isWfh) async {
    try {
      await AttendanceRepository.instance.toggleWfh(pin, date, isWfh);
      await _fetchData();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(content: Text('Failed to update WFH: $e')),
        );
      }
    }
  }

  // ─────────────────────────── Exports ────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);
    try {
      await AttendanceExportService.instance.exportToPdf(
        context: context,
        profiles: _profiles,
        matrixData: _matrixData,
        dates: _datesInRange,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_isExportingExcel) return;
    setState(() => _isExportingExcel = true);
    try {
      await AttendanceExportService.instance.exportToExcel(
        context: context,
        profiles: _profiles,
        matrixData: _matrixData,
        dates: _datesInRange,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(content: Text('Excel export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  // ─────────────────────────── Helpers ────────────────────────────────────

  List<DateTime> get _datesInRange {
    final List<DateTime> dates = [];
    for (DateTime d = _startDate;
        !d.isAfter(_endDate);
        d = d.add(const Duration(days: 1))) {
      dates.add(d);
    }
    return dates;
  }

  Map<String, DailyStatus> get _snapshotData {
    final ds = DateFormat('yyyy-MM-dd').format(_selectedSummaryDate);
    final Map<String, DailyStatus> snap = {};
    for (final profile in _profiles) {
      final pin = profile['biometric_id']?.toString();
      if (pin != null) {
        snap[pin] = _matrixData[pin]?[ds] ?? DailyStatus(status: 'A');
      }
    }
    return snap;
  }

  // ─────────────────────────── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dates = _datesInRange;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          AppRefreshButton(
            onRefresh: () async {
              await _fetchData();
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: "Today's Summary"),
            Tab(icon: Icon(Icons.grid_on_outlined), text: 'Monthly Matrix'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSnapshotTab(dates),
                    _buildMatrixTab(dates),
                  ],
                ),
    );
  }

  // ─────────────────────────── Error State ────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load attendance data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Tab 1: Daily Snapshot ──────────────────────

  Widget _buildSnapshotTab(List<DateTime> dates) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildDateSelector(dates),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DailySnapshotCards(
                dailyData: _snapshotData,
                profiles: _profiles,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(List<DateTime> dates) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.today_outlined, size: 20),
            const SizedBox(width: 8),
            const Text('Showing data for: ',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: dates.contains(_selectedSummaryDate)
                    ? _selectedSummaryDate
                    : (dates.isNotEmpty ? dates.last : null),
                isDense: true,
                items: dates.map((d) {
                  return DropdownMenuItem<DateTime>(
                    value: d,
                    child: Text(
                      _dateFmt.format(d),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSummaryDate = val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Tab 2: Monthly Matrix ──────────────────────

  Widget _buildMatrixTab(List<DateTime> dates) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date Filter Card ─────────────────────────────────────────
          _buildDateFilterCard(),
          // ── Export Buttons ───────────────────────────────────────────
          _buildExportBar(),
          // ── Legend + stats ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: [
                Text(
                  '${_profiles.length} employees · ${dates.length} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                _buildLegend(),
              ],
            ),
          ),
          // ── Matrix ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: MonthlyMatrixTable(
                dates: dates,
                profiles: _profiles,
                matrixData: _matrixData,
                onWfhToggle: _handleWfhToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card with two separate From-Date / To-Date pickers
  Widget _buildDateFilterCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Icon(Icons.filter_list_outlined,
                      size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Filter Date Range',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Date pickers row
              Row(
                children: [
                  // FROM DATE
                  Expanded(
                    child: _DatePickerField(
                      label: 'From Date',
                      date: _startDate,
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickFromDate,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        size: 18, color: Theme.of(context).hintColor),
                  ),
                  // TO DATE
                  Expanded(
                    child: _DatePickerField(
                      label: 'To Date',
                      date: _endDate,
                      icon: Icons.event_outlined,
                      onTap: _pickToDate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Export bar — clearly shows what date range will be exported
  Widget _buildExportBar() {
    final bool anyExporting = _isExportingPdf || _isExportingExcel;
    final rangeLabel =
        '${_dateFmt.format(_startDate)} – ${_dateFmt.format(_endDate)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Range info
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reports will include: $rangeLabel',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Export buttons
              Row(
                children: [
                  Expanded(
                    child: _ExportButton(
                      label: 'Download PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      color: Colors.red.shade700,
                      isLoading: _isExportingPdf,
                      enabled: !anyExporting && !_isLoading,
                      onTap: _exportPdf,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExportButton(
                      label: 'Download Excel',
                      icon: Icons.table_chart_outlined,
                      color: Colors.green.shade700,
                      isLoading: _isExportingExcel,
                      enabled: !anyExporting && !_isLoading,
                      onTap: _exportExcel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return const Wrap(
      spacing: 8,
      children: [
        _LegendChip(label: 'P Present', color: Colors.green),
        _LegendChip(label: 'L Late', color: Colors.amber),
        _LegendChip(label: 'A Absent', color: Colors.red),
        _LegendChip(label: 'W WFH', color: Colors.blue),
      ],
    );
  }
}

// ──────────────────────── Helper Widgets ─────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).hintColor)),
                  Text(
                    DateFormat('d MMM yyyy').format(date),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: primary),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16),
      label: Text(
        isLoading ? 'Generating...' : label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
