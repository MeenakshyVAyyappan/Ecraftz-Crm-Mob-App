import 'package:flutter/material.dart';

enum ProjectStatus { planning, inProgress, onHold, completed, cancelled }

extension ProjectStatusExt on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'planning';
      case ProjectStatus.inProgress:
        return 'in progress';
      case ProjectStatus.onHold:
        return 'on hold';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return const Color(0xFF6366F1);
      case ProjectStatus.inProgress:
        return const Color(0xFF10B981);
      case ProjectStatus.onHold:
        return const Color(0xFFF59E0B);
      case ProjectStatus.completed:
        return const Color(0xFF3B82F6);
      case ProjectStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Color get bgColor {
    switch (this) {
      case ProjectStatus.planning:
        return const Color(0xFFEEF2FF);
      case ProjectStatus.inProgress:
        return const Color(0xFFD1FAE5);
      case ProjectStatus.onHold:
        return const Color(0xFFFEF3C7);
      case ProjectStatus.completed:
        return const Color(0xFFDBEAFE);
      case ProjectStatus.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }
}

class Project {
  final String id;
  final String name;
  final String clientName;
  final ProjectStatus status;
  final String? deadline;
  final int totalTasks;
  final int completedTasks;
  final double progress;
  final String? teamLead;
  final bool isArchived;

  Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.status,
    this.deadline,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.progress = 0.0,
    this.teamLead,
    this.isArchived = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final clientsMap = json['clients'];
    final cName = (clientsMap is Map && clientsMap['name'] != null)
        ? clientsMap['name'].toString()
        : '';
    final statusStr = json['status']?.toString() ?? 'planning';
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clientName: cName.isNotEmpty ? cName : (json['client_id']?.toString() ?? ''),
      status: _parseProjectStatus(statusStr),
      deadline: json['start_date']?.toString() ?? json['end_date']?.toString(),
      isArchived: json['is_archived'] == true,
      teamLead: 'Chimbu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': _projectStatusToString(status),
      'is_archived': isArchived,
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}

ProjectStatus _parseProjectStatus(String? statusStr) {
  if (statusStr == null) return ProjectStatus.planning;
  switch (statusStr.toLowerCase()) {
    case 'planning': return ProjectStatus.planning;
    case 'in_progress':
    case 'inprogress':
    case 'in progress':
      return ProjectStatus.inProgress;
    case 'on_hold':
    case 'onhold':
    case 'on hold':
      return ProjectStatus.onHold;
    case 'completed': return ProjectStatus.completed;
    case 'cancelled': return ProjectStatus.cancelled;
    default: return ProjectStatus.planning;
  }
}

String _projectStatusToString(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning: return 'planning';
    case ProjectStatus.inProgress: return 'in_progress';
    case ProjectStatus.onHold: return 'on_hold';
    case ProjectStatus.completed: return 'completed';
    case ProjectStatus.cancelled: return 'cancelled';
  }
}
