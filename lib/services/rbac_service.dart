import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rbac_models.dart';

class RbacService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch active permission codes for current user via Postgres RPC
  Future<List<String>> fetchUserPermissions(String userId) async {
    try {
      final response = await _client.rpc(
        'get_user_permission_codes_v2',
        params: {'p_user_id': userId},
      );
      if (response is List) {
        return response
            .map((e) => (e['permission_code'] ?? e['code'] ?? e).toString())
            .where((code) => code.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user permissions: $e');
      return [];
    }
  }

  /// Fetch organization roles with permission mappings and active user counts
  Future<List<RoleModel>> fetchRoles(String organizationId) async {
    try {
      dynamic query = _client.from('roles').select('''
        id, name, description, is_system, organization_id, created_at,
        role_permissions (
          permission:permissions ( id, code )
        )
      ''');

      if (organizationId.isNotEmpty && organizationId != '00000000-0000-0000-0000-000000000000') {
        query = query.eq('organization_id', organizationId);
      }

      final dynamic rolesData = await query;

      // Fetch user_roles counts
      Map<String, int> counts = {};
      try {
        final dynamic userRolesData = await _client.from('user_roles').select('role_id');
        if (userRolesData is List) {
          for (var ur in userRolesData) {
            final roleId = ur['role_id']?.toString();
            if (roleId != null) {
              counts[roleId] = (counts[roleId] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        debugPrint('Error counting user roles: $e');
      }

      if (rolesData is List) {
        return rolesData
            .map((r) => RoleModel.fromJson(r as Map<String, dynamic>, counts))
            .where((r) => r.name.toLowerCase() != 'super admin')
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching roles: $e');
      return [];
    }
  }

  /// Fetch master static catalogue of permissions
  Future<List<PermissionModel>> fetchPermissions() async {
    try {
      final dynamic data = await _client
          .from('permissions')
          .select('*')
          .order('module');
      if (data is List) {
        return data
            .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching permissions catalog: $e');
      return [];
    }
  }

  /// Create custom role for organization
  Future<void> createRole({
    required String name,
    required String description,
    required String organizationId,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'is_system': false,
    };

    if (organizationId.isNotEmpty && organizationId != '00000000-0000-0000-0000-000000000000') {
      payload['organization_id'] = organizationId;
    } else {
      payload['organization_id'] = '00000000-0000-0000-0000-000000000000';
    }

    await _client.from('roles').insert(payload);
  }

  /// Update role name and description
  Future<void> updateRoleDetails({
    required String roleId,
    required String name,
    required String description,
  }) async {
    await _client.from('roles').update({
      'name': name,
      'description': description,
    }).eq('id', roleId);
  }

  /// Update role permissions atomically using Postgres RPC
  Future<void> updateRolePermissions(String roleId, List<String> permissionIds) async {
    await _client.rpc('update_role_permissions', params: {
      'p_role_id': roleId,
      'p_permission_ids': permissionIds,
    });
  }

  /// Delete role with safety check for active users
  Future<void> deleteRole(String roleId) async {
    try {
      final dynamic activeUsers = await _client
          .from('user_roles')
          .select('user_id')
          .eq('role_id', roleId);
      if (activeUsers is List && activeUsers.isNotEmpty) {
        throw Exception(
            'Cannot delete role: ${activeUsers.length} user(s) are assigned to it.');
      }
    } catch (e) {
      if (e.toString().contains('Cannot delete role')) rethrow;
    }

    await _client.from('roles').delete().eq('id', roleId);
  }

  /// Fetch profiles for organization
  Future<List<Map<String, dynamic>>> fetchProfiles(String organizationId) async {
    try {
      dynamic query = _client.from('profiles').select('id, full_name, email, role, organization_id');
      if (organizationId.isNotEmpty && organizationId != '00000000-0000-0000-0000-000000000000') {
        query = query.eq('organization_id', organizationId);
      }
      final dynamic res = await query;
      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      return [];
    }
  }

  /// Fetch user IDs assigned to role
  Future<List<String>> fetchAssignedUserIds(String roleId) async {
    try {
      final dynamic res = await _client.from('user_roles').select('user_id').eq('role_id', roleId);
      if (res is List) {
        return res.map((r) => r['user_id'].toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching assigned user ids: $e');
      return [];
    }
  }

  /// Assign user to role
  Future<void> assignUserToRole(String userId, String roleId) async {
    await _client.from('user_roles').upsert({
      'user_id': userId,
      'role_id': roleId,
    });
  }

  /// Remove user from role
  Future<void> removeUserFromRole(String userId, String roleId) async {
    await _client
        .from('user_roles')
        .delete()
        .eq('user_id', userId)
        .eq('role_id', roleId);
  }
}
