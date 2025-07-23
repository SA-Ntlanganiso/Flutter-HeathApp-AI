// lib/core/providers/auth_provider.dart
import 'package:agcare_plus/core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email == 'patient@example.com' && password == 'patient123') {
      return User.demo(role: UserRole.patient);
    }
    
    throw Exception('Invalid credentials');
  }

  Future<User> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      role: UserRole.patient,
      name: name,
    );
  }
}

class SecureStorage {
  static User? _currentUser;
  
  Future<void> saveUser(User user) async {
    _currentUser = user;
  }

  Future<User?> getUser() async {
    return _currentUser;
  }

  Future<void> clear() async {
    _currentUser = null;
  }
}

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier(this.ref) : super(null) {
    _initializeAuth();
  }
  
  final Ref ref;
  final _authRepository = AuthRepository();
  final _secureStorage = SecureStorage();

  Future<void> _initializeAuth() async {
    final user = await _secureStorage.getUser();
    if (user != null) {
      state = user;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await _authRepository.login(email: email, password: password);
      state = user;
      await _secureStorage.saveUser(user);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _authRepository.signup(
        email: email,
        password: password,
        name: name,
      );
      state = user;
      await _secureStorage.saveUser(user);
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _secureStorage.clear();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref);
});
