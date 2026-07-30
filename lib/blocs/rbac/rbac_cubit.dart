import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/rbac_service.dart';
import 'rbac_state.dart';

class RbacCubit extends Cubit<RbacState> {
  final RbacService _service = RbacService();

  RbacCubit() : super(const RbacState());

  void setUserRole(String? role) {
    emit(state.copyWith(userRole: role));
  }

  Future<void> loadUserPermissions(String userId) async {
    try {
      final perms = await _service.fetchUserPermissions(userId);
      emit(state.copyWith(userPermissions: perms));
    } catch (e) {
      debugPrint('Error loading user permissions: $e');
    }
  }

  Future<void> loadRolesAndPermissions(String orgId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final perms = await _service.fetchPermissions();
      final roles = await _service.fetchRoles(orgId);
      emit(state.copyWith(
        permissions: perms,
        roles: roles,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error in loadRolesAndPermissions: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  bool hasPermission(String code) => state.hasPermission(code);

  bool hasModuleAccess(String moduleCode) => state.hasModuleAccess(moduleCode);

  Future<void> createRole(String name, String description, String orgId) async {
    await _service.createRole(
      name: name,
      description: description,
      organizationId: orgId,
    );
    await loadRolesAndPermissions(orgId);
  }

  Future<void> updateRoleDetails(
      String roleId, String name, String description, String orgId) async {
    await _service.updateRoleDetails(
      roleId: roleId,
      name: name,
      description: description,
    );
    await loadRolesAndPermissions(orgId);
  }

  Future<void> updateRolePermissions(
      String roleId, List<String> permIds, String orgId) async {
    await _service.updateRolePermissions(roleId, permIds);
    await loadRolesAndPermissions(orgId);
  }

  Future<void> deleteRole(String roleId, String orgId) async {
    await _service.deleteRole(roleId);
    await loadRolesAndPermissions(orgId);
  }

  Future<List<Map<String, dynamic>>> fetchProfiles(String orgId) async {
    return await _service.fetchProfiles(orgId);
  }

  Future<List<String>> fetchAssignedUserIds(String roleId) async {
    return await _service.fetchAssignedUserIds(roleId);
  }

  Future<void> assignUserToRole(
      String userId, String roleId, String orgId) async {
    await _service.assignUserToRole(userId, roleId);
    await loadRolesAndPermissions(orgId);
  }

  Future<void> removeUserFromRole(
      String userId, String roleId, String orgId) async {
    await _service.removeUserFromRole(userId, roleId);
    await loadRolesAndPermissions(orgId);
  }
}
