import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/rbac/rbac_cubit.dart';
import '../blocs/rbac/rbac_state.dart';

class PermissionGuard extends StatelessWidget {
  final String permissionCode;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.permissionCode,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacCubit, RbacState>(
      builder: (context, state) {
        if (state.hasPermission(permissionCode)) {
          return child;
        }
        return fallback;
      },
    );
  }
}
