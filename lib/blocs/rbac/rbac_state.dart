import 'package:equatable/equatable.dart';
import '../../models/rbac_models.dart';

class RbacState extends Equatable {
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;
  final List<String> userPermissions;
  final bool isLoading;
  final String? userRole;
  final String? errorMessage;

  const RbacState({
    this.roles = const [],
    this.permissions = const [],
    this.userPermissions = const [],
    this.isLoading = false,
    this.userRole,
    this.errorMessage,
  });

  bool hasPermission(String code) {
    if (userRole != null) {
      final roleLower = userRole!.toLowerCase();
      if (roleLower == 'admin' ||
          roleLower == 'super_admin' ||
          roleLower == 'super admin' ||
          roleLower == 'administrator') {
        return true;
      }
    }
    return userPermissions.contains(code);
  }

  bool hasModuleAccess(String moduleCode) {
    if (userRole != null) {
      final roleLower = userRole!.toLowerCase();
      if (roleLower == 'admin' ||
          roleLower == 'super_admin' ||
          roleLower == 'super admin' ||
          roleLower == 'administrator') {
        return true;
      }
    }
    if (userPermissions.isNotEmpty) {
      return userPermissions.contains(moduleCode);
    }
    return true;
  }

  RbacState copyWith({
    List<RoleModel>? roles,
    List<PermissionModel>? permissions,
    List<String>? userPermissions,
    bool? isLoading,
    String? userRole,
    String? errorMessage,
  }) {
    return RbacState(
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      userPermissions: userPermissions ?? this.userPermissions,
      isLoading: isLoading ?? this.isLoading,
      userRole: userRole ?? this.userRole,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        roles,
        permissions,
        userPermissions,
        isLoading,
        userRole,
        errorMessage,
      ];
}
