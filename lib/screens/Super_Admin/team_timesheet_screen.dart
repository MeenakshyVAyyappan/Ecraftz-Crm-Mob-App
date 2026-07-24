import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/team_timesheet/team_timesheet_bloc.dart';
import '../../models/team_timesheet_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class TeamTimesheetScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const TeamTimesheetScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<TeamTimesheetScreen> createState() => _TeamTimesheetScreenState();
}

class _TeamTimesheetScreenState extends State<TeamTimesheetScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TeamTimesheetBloc>().add(LoadTeamTimesheetsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TeamTimesheetEntry> _filtered(List<TeamTimesheetEntry> entries) {
    if (_searchQuery.isEmpty) return entries;
    final q = _searchQuery.toLowerCase();
    return entries.where((e) =>
      e.userName.toLowerCase().contains(q) ||
      (e.userEmail ?? '').toLowerCase().contains(q) ||
      e.status.toLowerCase().contains(q)
    ).toList();
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

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
            Text('Team Timesheets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textTitle)),
            Text('Monitor employee punches, work hours & overtime', style: TextStyle(fontSize: 11, color: textSub)),
          ],
        ),
      ) : null,
      body: BlocBuilder<TeamTimesheetBloc, TeamTimesheetState>(
        builder: (context, state) {
          if (state.status == TeamTimesheetStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = _filtered(state.entries);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surface,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search employee timesheets...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(child: Text('No team timesheets recorded.', style: TextStyle(color: textSub, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) {
                          final item = list[idx];
                          final clockInStr = item.clockIn != null ? DateFormat('hh:mm a').format(item.clockIn!) : '--:--';
                          final clockOutStr = item.clockOut != null ? DateFormat('hh:mm a').format(item.clockOut!) : '--:--';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isDark ? AppTheme.bgCardDark : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.userName,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textTitle),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.isLate ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isLate ? 'LATE' : item.status.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isLate ? Colors.orange : Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(item.date),
                                    style: TextStyle(fontSize: 11, color: textSub),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTimeCol('Punch In', clockInStr, Icons.login_rounded, Colors.green, isDark),
                                      ),
                                      Expanded(
                                        child: _buildTimeCol('Punch Out', clockOutStr, Icons.logout_rounded, Colors.red, isDark),
                                      ),
                                      Expanded(
                                        child: _buildTimeCol('Total Work', _formatDuration(item.totalWorkMinutes), Icons.timer_outlined, Colors.blue, isDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeCol(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
      ],
    );
  }
}
