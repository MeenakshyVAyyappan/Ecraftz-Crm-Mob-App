import 'package:flutter/material.dart';
import 'dart:convert';

enum TaskStatus { toDo, inProgress, review, done }
enum TaskPriority { low, medium, high }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.toDo: return 'To Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.review: return 'Review';
      case TaskStatus.done: return 'Done';
    }
  }
  Color get color {
    switch (this) {
      case TaskStatus.toDo: return const Color(0xFF94A3B8);
      case TaskStatus.inProgress: return const Color(0xFF0EA5E9);
      case TaskStatus.review: return const Color(0xFFF59E0B);
      case TaskStatus.done: return const Color(0xFF10B981);
    }
  }
  Color get bgColor {
    switch (this) {
      case TaskStatus.toDo: return const Color(0xFFF1F5F9);
      case TaskStatus.inProgress: return const Color(0xFFE0F2FE);
      case TaskStatus.review: return const Color(0xFFFEF3C7);
      case TaskStatus.done: return const Color(0xFFD1FAE5);
    }
  }
}

extension TaskPriorityExt on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low: return 'LOW';
      case TaskPriority.medium: return 'MEDIUM';
      case TaskPriority.high: return 'HIGH';
    }
  }
  Color get color {
    switch (this) {
      case TaskPriority.low: return const Color(0xFF10B981);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.high: return const Color(0xFFEF4444);
    }
  }
  Color get bgColor {
    switch (this) {
      case TaskPriority.low: return const Color(0xFFD1FAE5);
      case TaskPriority.medium: return const Color(0xFFFEF3C7);
      case TaskPriority.high: return const Color(0xFFFEE2E2);
    }
  }
}

class TaskItem {
  final String id;
  String summary;
  String description;
  String? parentProject;
  String? owner;
  DateTime? dueDate;
  TaskStatus status;
  TaskPriority priority;

  TaskItem({
    required this.id,
    required this.summary,
    this.description = '',
    this.parentProject,
    this.owner,
    this.dueDate,
    required this.status,
    required this.priority,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    String desc = json['description']?.toString() ?? '';
    String? ownerVal;
    
    // Parse fallback metadata from description
    final fallbackRegex = RegExp(r'\[METADATA_FALLBACK:\s*(\{.*\})\]');
    final match = fallbackRegex.firstMatch(desc);
    if (match != null) {
      try {
        final fallbackJson = jsonDecode(match.group(1)!);
        ownerVal = fallbackJson['owner']?.toString();
        desc = desc.replaceAll(fallbackRegex, '').trim();
      } catch (_) {}
    }

    final projectsMap = json['projects'];
    String pName = '';
    if (projectsMap is Map) {
      final pTitle = projectsMap['name']?.toString() ?? '';
      final clientsMap = projectsMap['clients'];
      final cName = (clientsMap is Map && clientsMap['name'] != null)
          ? clientsMap['name'].toString()
          : '';
      if (cName.isNotEmpty && pTitle.isNotEmpty) {
        pName = '${cName.toUpperCase()} - ${pTitle.toUpperCase()}';
      } else if (pTitle.isNotEmpty) {
        pName = pTitle;
      }
    }

    return TaskItem(
      id: json['id']?.toString() ?? '',
      summary: json['title']?.toString() ?? '',
      description: desc,
      parentProject: pName.isNotEmpty ? pName : (json['project_id']?.toString() ?? ''),
      owner: ownerVal,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      status: _parseTaskStatus(json['status']?.toString()),
      priority: _parseTaskPriority(json['priority']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    String finalDesc = description;
    if (owner != null && owner!.isNotEmpty) {
      finalDesc += '\n\n[METADATA_FALLBACK: {"owner": "$owner"}]';
    }
    return {
      'id': id,
      'title': summary,
      'description': finalDesc,
      'status': _taskStatusToString(status),
      'priority': _taskPriorityToString(priority),
      'due_date': dueDate?.toIso8601String(),
      'organization_id': '00000000-0000-0000-0000-000000000000',
    };
  }
}

TaskStatus _parseTaskStatus(String? str) {
  if (str == null) return TaskStatus.toDo;
  switch (str.toLowerCase()) {
    case 'todo':
    case 'to_do':
    case 'to do':
      return TaskStatus.toDo;
    case 'in_progress':
    case 'inprogress':
    case 'in progress':
      return TaskStatus.inProgress;
    case 'review':
      return TaskStatus.review;
    case 'done':
      return TaskStatus.done;
    default:
      return TaskStatus.toDo;
  }
}

String _taskStatusToString(TaskStatus s) {
  switch (s) {
    case TaskStatus.toDo: return 'todo';
    case TaskStatus.inProgress: return 'in_progress';
    case TaskStatus.review: return 'review';
    case TaskStatus.done: return 'done';
  }
}

TaskPriority _parseTaskPriority(String? str) {
  if (str == null) return TaskPriority.medium;
  switch (str.toLowerCase()) {
    case 'low': return TaskPriority.low;
    case 'medium': return TaskPriority.medium;
    case 'high': return TaskPriority.high;
    default: return TaskPriority.medium;
  }
}

String _taskPriorityToString(TaskPriority p) {
  switch (p) {
    case TaskPriority.low: return 'low';
    case TaskPriority.medium: return 'medium';
    case TaskPriority.high: return 'high';
  }
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String department;
  final int weeklyLoad;
  final int weeklyLimit;
  final List<TaskItem> tasks;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    this.weeklyLoad = 0,
    this.weeklyLimit = 40,
    required this.tasks,
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  String get workloadStatus {
    final pct = weeklyLoad / weeklyLimit;
    if (pct >= 1.0) return 'Overloaded';
    if (pct >= 0.8) return 'At Risk';
    return 'Balanced';
  }

  Color get workloadColor {
    final pct = weeklyLoad / weeklyLimit;
    if (pct >= 1.0) return const Color(0xFFEF4444);
    if (pct >= 0.8) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}
