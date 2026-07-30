import 'package:flutter/material.dart';

class ActiveUser {
  final String initial;
  final Color color;

  const ActiveUser(this.initial, this.color);
}

class RoleModel {
  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final String organizationId;
  final List<String> permissions;
  final int userCount;
  final List<ActiveUser> activeUsers;

  RoleModel({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    required this.organizationId,
    this.permissions = const [],
    this.userCount = 0,
    this.activeUsers = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> json, Map<String, int> userCounts) {
    List<String> permCodes = [];
    if (json['role_permissions'] != null) {
      for (var rp in json['role_permissions']) {
        if (rp['permission'] != null && rp['permission']['code'] != null) {
          permCodes.add(rp['permission']['code'] as String);
        } else if (rp['code'] != null) {
          permCodes.add(rp['code'] as String);
        }
      }
    }

    final uCount = userCounts[json['id']] ?? 0;

    // Generate avatar samples based on user count
    final List<ActiveUser> avatars = [];
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.green,
    ];
    for (int i = 0; i < (uCount > 5 ? 5 : uCount); i++) {
      final letter = String.fromCharCode(65 + (i % 26));
      avatars.add(ActiveUser(letter, colors[i % colors.length]));
    }

    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Role',
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      organizationId: json['organization_id'] as String? ?? '',
      permissions: permCodes,
      userCount: uCount,
      activeUsers: avatars,
    );
  }

  RoleModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSystem,
    String? organizationId,
    List<String>? permissions,
    int? userCount,
    List<ActiveUser>? activeUsers,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      organizationId: organizationId ?? this.organizationId,
      permissions: permissions ?? this.permissions,
      userCount: userCount ?? this.userCount,
      activeUsers: activeUsers ?? this.activeUsers,
    );
  }
}

class PermissionModel {
  final String id;
  final String code;
  final String module;
  final String name;
  final String? description;
  final String type; // 'module' or 'action'

  PermissionModel({
    required this.id,
    required this.code,
    required this.module,
    required this.name,
    this.description,
    required this.type,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    final rawCode = json['code']?.toString() ?? '';
    final rawType = json['type']?.toString();
    final inferredType = rawType ?? (rawCode.startsWith('module.') ? 'module' : 'action');

    return PermissionModel(
      id: json['id'] as String,
      code: rawCode,
      module: json['module']?.toString() ?? 'General',
      name: json['name']?.toString() ?? rawCode,
      description: json['description']?.toString(),
      type: inferredType,
    );
  }
}
