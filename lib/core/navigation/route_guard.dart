import 'package:agcare_plus/core/models/user_model.dart';
import 'package:agcare_plus/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles role-based access control for navigation
class RoleGuard {
  /// Checks if current user has required role
  static bool canAccess({
    required WidgetRef ref,
    required UserRole requiredRole,
    List<UserRole>? anyOfRoles,
  }) {
    final user = ref.read(authProvider);
    if (user == null) return false;
    
    if (anyOfRoles != null) {
      return anyOfRoles.contains(user.role);
    }
    
    return user.role == requiredRole;
  }

  /// Returns appropriate screen based on role access
  static Widget guardedRoute({
    required WidgetRef ref,
    required UserRole requiredRole,
    List<UserRole>? anyOfRoles,
    required Widget authorizedScreen,
    Widget? unauthorizedScreen,
  }) {
    return canAccess(
      ref: ref,
      requiredRole: requiredRole,
      anyOfRoles: anyOfRoles,
    ) 
      ? authorizedScreen
      : unauthorizedScreen ?? const Scaffold(body: Center(child: Text('Access Denied')));
  }
}