import 'package:flutter/foundation.dart';
import '../models/rbac_models.dart';
import '../services/rbac_service.dart';

class RbacProvider extends ChangeNotifier {
  final RbacService _service = RbacService();

  List<RoleModel> _roles = [];
  List<PermissionModel> _permissions = [];
  List<String> _userPermissions = [];
  bool _isLoading = false;
  String? _userRole;

  List<RoleModel> get roles => _roles;
  List<PermissionModel> get permissions => _permissions;
  List<String> get userPermissions => _userPermissions;
  bool get isLoading => _isLoading;
  String? get userRole => _userRole;

  void setUserRole(String? role) {
    _userRole = role;
    notifyListeners();
  }

  Future<void> loadUserPermissions(String userId) async {
    _userPermissions = await _service.fetchUserPermissions(userId);
    notifyListeners();
  }

  Future<void> loadRolesAndPermissions(String orgId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _permissions = await _service.fetchPermissions();
      _roles = await _service.fetchRoles(orgId);
    } catch (e) {
      debugPrint('Error in loadRolesAndPermissions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasPermission(String code) {
    if (_userRole != null) {
      final roleLower = _userRole!.toLowerCase();
      if (roleLower == 'admin' ||
          roleLower == 'super_admin' ||
          roleLower == 'super admin' ||
          roleLower == 'administrator') {
        return true;
      }
    }
    return _userPermissions.contains(code);
  }

  bool hasModuleAccess(String moduleCode) {
    if (_userRole != null) {
      final roleLower = _userRole!.toLowerCase();
      if (roleLower == 'admin' ||
          roleLower == 'super_admin' ||
          roleLower == 'super admin' ||
          roleLower == 'administrator') {
        return true;
      }
    }
    // If permissions have been loaded for the user, check exact code
    if (_userPermissions.isNotEmpty) {
      return _userPermissions.contains(moduleCode);
    }
    // Fallback: allow access for legacy users so nothing breaks unexpectedly
    return true;
  }

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
