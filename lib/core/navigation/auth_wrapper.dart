// lib/core/navigation/auth_wrapper.dart
import 'package:agcare_plus/features/auth/login_screen.dart';
import 'package:agcare_plus/features/patient/home/patient_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final authState = ref.watch(authProvider);
      return authState == null ? const LoginScreen() : const PatientHomeScreen();
    } catch (e) {
      debugPrint('AuthWrapper error: $e');
      return const Scaffold(
        body: Center(child: Text('Authentication error. Please restart the app.')),
      );
    }
  }
}