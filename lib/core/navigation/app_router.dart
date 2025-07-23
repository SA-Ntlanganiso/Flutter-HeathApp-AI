import 'package:agcare_plus/features/ai/symptom_checker_screen.dart';
import 'package:agcare_plus/features/auth/login_screen.dart';
import 'package:agcare_plus/features/patient/home/patient_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings, WidgetRef ref) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) {
            final user = ref.read(authProvider);

            // Not logged in
            if (user == null) return const LoginScreen();

            // Only allow patients on mobile app
            return const PatientHomeScreen();
          },
        );

      case '/ai-assistant':
        return MaterialPageRoute(builder: (_) => const SymptomCheckerScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }
}