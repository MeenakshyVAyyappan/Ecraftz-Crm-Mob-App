import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/crm_reports/crm_reports_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class CrmReportsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const CrmReportsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<CrmReportsScreen> createState() => _CrmReportsScreenState();
}

class _CrmReportsScreenState extends State<CrmReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _dateFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    DateTime? start;
    final now = DateTime.now();
    if (_dateFilter == 'Today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_dateFilter == 'This Week') {
      start = now.subtract(Duration(days: now.weekday - 1));
    } else if (_dateFilter == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    }

    context.read<CrmReportsBloc>().add(LoadCrmReportsEvent(startDate: start));
  }

  final _currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: widget.showAppBar ? AppDrawer(selectedIndex: widget.selectedIndex, onItemSelected: widget.onItemSelected) : null,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CRM Reports & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textTitle)),
            Text('Real-time KPIs, sales performance & work analytics', style: TextStyle(fontSize: 11, color: textSub)),
          ],
        ),
      ) : null,
      body: BlocBuilder<CrmReportsBloc, CrmReportsState>(
        builder: (context, state) {
          if (state.status == CrmReportsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = state.summary;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date Range Selector Header
              Row(
                children: [
                  Text('Filter Range: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _dateFilter,
                    items: ['Today', 'This Week', 'This Month', 'All Time']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _dateFilter = val);
                        _loadReports();
                      }
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2196F3)),
                    onPressed: _loadReports,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Analytics KPI Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Pipeline Value',
                      _currencyFmt.format(summary?.pipelineValue ?? 0),
                      Icons.account_balance_wallet_outlined,
                      Colors.blue,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Billed',
                      _currencyFmt.format(summary?.totalBilledAmount ?? 0),
                      Icons.receipt_long_outlined,
                      Colors.green,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Leads',
                      '${summary?.totalLeads ?? 0}',
                      Icons.people_outline,
                      Colors.purple,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Converted Leads',
                      '${summary?.convertedLeads ?? 0}',
                      Icons.check_circle_outline,
                      Colors.teal,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Meetings',
                      '${summary?.totalMeetings ?? 0}',
                      Icons.calendar_today_outlined,
                      Colors.orange,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Avg Rating',
                      '${summary?.averageRating.toStringAsFixed(1) ?? "5.0"} ★',
                      Icons.star_outline,
                      Colors.amber[700]!,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section 2: Detailed Breakdown Cards
              Text('Module Performance Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textTitle)),
              const SizedBox(height: 10),
              _buildReportSectionCard(
                'Lead Conversion & Pipeline',
                'Total Leads: ${summary?.totalLeads ?? 0} | Converted: ${summary?.convertedLeads ?? 0}',
                'Pipeline Value: ${_currencyFmt.format(summary?.pipelineValue ?? 0)}',
                Icons.trending_up_rounded,
                Colors.blue,
                isDark,
              ),
              const SizedBox(height: 10),
              _buildReportSectionCard(
                'Financial & Billing Report',
                'Total Invoices: ${summary?.totalInvoices ?? 0} | Billed: ${_currencyFmt.format(summary?.totalBilledAmount ?? 0)}',
                'Collected: ${_currencyFmt.format(summary?.totalPaidAmount ?? 0)} | Pending: ${_currencyFmt.format(summary?.totalPendingAmount ?? 0)}',
                Icons.attach_money_rounded,
                Colors.green,
                isDark,
              ),
              const SizedBox(height: 10),
              _buildReportSectionCard(
                'Client Feedback & Meetings',
                'Meetings Scheduled: ${summary?.totalMeetings ?? 0} | Completed: ${summary?.completedMeetings ?? 0}',
                'Client Feedback Submissions: ${summary?.totalFeedback ?? 0} (Avg: ${summary?.averageRating.toStringAsFixed(1)} / 5)',
                Icons.rate_review_outlined,
                Colors.orange,
                isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _buildReportSectionCard(String title, String line1, String line2, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(line1, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[700])),
                Text(line2, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
