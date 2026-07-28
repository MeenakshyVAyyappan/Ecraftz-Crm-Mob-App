import 'package:flutter/material.dart';

class WfhToggleDialog extends StatelessWidget {
  final String employeeName;
  final String dateString;
  final bool isCurrentlyWfh;
  final VoidCallback onToggle;

  const WfhToggleDialog({
    super.key,
    required this.employeeName,
    required this.dateString,
    required this.isCurrentlyWfh,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final action = isCurrentlyWfh ? 'Remove' : 'Mark';
    final actionLower = isCurrentlyWfh ? 'remove' : 'mark';

    return AlertDialog(
      title: Text('$action WFH'),
      content: Text(
        'Do you want to $actionLower Work From Home for '
        '$employeeName on $dateString?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onToggle();
            Navigator.of(context).pop();
          },
          child: Text(action),
        ),
      ],
    );
  }
}
