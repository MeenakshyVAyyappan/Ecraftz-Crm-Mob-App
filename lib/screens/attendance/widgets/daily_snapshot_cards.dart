import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/employee_attendance_matrix.dart';

class DailySnapshotCards extends StatelessWidget {
  final Map<String, DailyStatus> dailyData;
  final List<Map<String, dynamic>> profiles;

  const DailySnapshotCards({
    super.key,
    required this.dailyData,
    required this.profiles,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> presentList = [];
    final List<Map<String, dynamic>> absentList = [];
    final List<Map<String, dynamic>> wfhList = [];

    for (final profile in profiles) {
      final pin = profile['biometric_id']?.toString() ?? '';
      final empName = (profile['full_name'] as String?) ?? 'Unknown';
      final statusData = dailyData[pin] ?? DailyStatus(status: 'A');

      final item = {'name': empName, 'statusData': statusData};

      switch (statusData.status) {
        case 'P':
        case 'L':
          presentList.add(item);
          break;
        case 'W':
          wfhList.add(item);
          break;
        default:
          absentList.add(item);
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SnapshotCard(title: 'Present', list: presentList, color: Colors.green, icon: Icons.check_circle_outline)),
            const SizedBox(width: 8),
            Expanded(child: _SnapshotCard(title: 'Absent', list: absentList, color: Colors.red, icon: Icons.cancel_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _SnapshotCard(title: 'WFH', list: wfhList, color: Colors.blue, icon: Icons.home_work_outlined)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _SnapshotCard(title: 'Present', list: presentList, color: Colors.green, icon: Icons.check_circle_outline),
        const SizedBox(height: 8),
        _SnapshotCard(title: 'Absent', list: absentList, color: Colors.red, icon: Icons.cancel_outlined),
        const SizedBox(height: 8),
        _SnapshotCard(title: 'WFH', list: wfhList, color: Colors.blue, icon: Icons.home_work_outlined),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> list;
  final Color color;
  final IconData icon;

  const _SnapshotCard({
    required this.title,
    required this.list,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color.withValues(alpha: 0.08);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${list.length}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // List
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('None',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final name = item['name'] as String;
                  final status = item['statusData'] as DailyStatus;
                  return _EmpTile(name: name, status: status, cardTitle: title);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmpTile extends StatelessWidget {
  final String name;
  final DailyStatus status;
  final String cardTitle;

  const _EmpTile({
    required this.name,
    required this.status,
    required this.cardTitle,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailing;

    if (cardTitle == 'Present' && status.firstPunchIn != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('hh:mm a').format(status.firstPunchIn!),
            style: const TextStyle(fontSize: 12),
          ),
          if (status.status == 'L') ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Late',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      );
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
      ),
      title: Text(name,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis),
      trailing: trailing,
    );
  }
}
