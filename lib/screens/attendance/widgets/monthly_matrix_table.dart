import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/employee_attendance_matrix.dart';
import 'wfh_toggle_dialog.dart';

class MonthlyMatrixTable extends StatelessWidget {
  final List<DateTime> dates;
  final List<Map<String, dynamic>> profiles;
  final Map<String, Map<String, DailyStatus>> matrixData;
  final Function(String, DateTime, bool) onWfhToggle;

  const MonthlyMatrixTable({
    super.key,
    required this.dates,
    required this.profiles,
    required this.matrixData,
    required this.onWfhToggle,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'P':
        return Colors.green;
      case 'L':
        return Colors.amber.shade700;
      case 'A':
        return Colors.red;
      case 'W':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'P':
        return 'Present';
      case 'L':
        return 'Late';
      case 'A':
        return 'Absent';
      case 'W':
        return 'Work From Home';
      default:
        return 'Absent';
    }
  }

  void _showCellDetail(
      BuildContext context,
      String empName,
      String dateStr,
      DateTime date,
      String pin,
      DailyStatus cell) {
    final timeFmt = DateFormat('hh:mm a');
    final canToggleWfh = cell.status == 'A' || cell.status == 'W';
    final color = _statusColor(cell.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        cell.status,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(empName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(date),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _statusLabel(cell.status),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Time Details
              Row(
                children: [
                  Expanded(
                    child: _TimeCard(
                      icon: Icons.login_outlined,
                      label: 'Check-In',
                      time: cell.firstPunchIn != null
                          ? timeFmt.format(cell.firstPunchIn!)
                          : '—',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeCard(
                      icon: Icons.logout_outlined,
                      label: 'Check-Out',
                      time: cell.lastPunchOut != null
                          ? timeFmt.format(cell.lastPunchOut!)
                          : '—',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // Total hours
              if (cell.firstPunchIn != null && cell.lastPunchOut != null) ...[
                const SizedBox(height: 12),
                _totalHoursCard(cell),
              ],

              // WFH toggle
              if (canToggleWfh) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(cell.status == 'W'
                        ? Icons.home_work_outlined
                        : Icons.add_home_work_outlined),
                    label: Text(cell.status == 'W'
                        ? 'Remove WFH Mark'
                        : 'Mark as WFH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cell.status == 'W'
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      foregroundColor:
                          cell.status == 'W' ? Colors.red : Colors.blue,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showDialog(
                        context: context,
                        builder: (_) => WfhToggleDialog(
                          employeeName: empName,
                          dateString: dateStr,
                          isCurrentlyWfh: cell.status == 'W',
                          onToggle: () =>
                              onWfhToggle(pin, date, cell.status != 'W'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalHoursCard(DailyStatus cell) {
    final diff = cell.lastPunchOut!.difference(cell.firstPunchIn!);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_outlined,
              color: Colors.teal, size: 18),
          const SizedBox(width: 8),
          const Text('Total Working Hours',
              style: TextStyle(fontSize: 13, color: Colors.teal)),
          const Spacer(),
          Text(
            '${h}h ${m}m',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.teal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No employee profiles found with biometric IDs.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (dates.isEmpty) {
      return const Center(child: Text('No date range selected.'));
    }

    const double cellW = 44;
    const double nameColW = 130;
    const double rowH = 44;
    const double headerH = 52;

    final totalW = nameColW + (dates.length * cellW);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalW,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Container(
                height: headerH,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: nameColW,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Employee',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ...dates.map((d) {
                      final isWeekend =
                          d.weekday == DateTime.saturday ||
                              d.weekday == DateTime.sunday;
                      return SizedBox(
                        width: cellW,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('d').format(d),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWeekend
                                    ? Colors.deepPurple
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                              ),
                            ),
                            Text(
                              DateFormat('E').format(d),
                              style: TextStyle(
                                fontSize: 9,
                                color: isWeekend
                                    ? Colors.deepPurple.shade300
                                    : Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // ── Rows ──────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, idx) {
                    final profile = profiles[idx];
                    final pin =
                        profile['biometric_id']?.toString() ?? '';
                    final empName =
                        (profile['full_name'] as String?) ?? 'Unknown';
                    final isEven = idx.isEven;

                    return Container(
                      height: rowH,
                      color: isEven
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: nameColW,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              child: Text(
                                empName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ...dates.map((date) {
                            final ds =
                                DateFormat('yyyy-MM-dd').format(date);
                            final cell = matrixData[pin]?[ds] ??
                                DailyStatus(status: 'A');
                            final isWeekend =
                                date.weekday == DateTime.saturday ||
                                    date.weekday == DateTime.sunday;
                            final color = _statusColor(cell.status);

                            return SizedBox(
                              width: cellW,
                              height: rowH,
                              child: GestureDetector(
                                onTap: () => _showCellDetail(
                                    context,
                                    empName,
                                    ds,
                                    date,
                                    pin,
                                    cell),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isWeekend
                                          ? Colors.deepPurple
                                              .withValues(alpha: 0.08)
                                          : color.withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(5),
                                      border: isWeekend
                                          ? Border.all(
                                              color: Colors.deepPurple
                                                  .withValues(alpha: 0.3),
                                              width: 0.5)
                                          : null,
                                    ),
                                    child: Text(
                                      cell.status,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).hintColor)),
                Text(time,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
