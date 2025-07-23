enum UserRole {
  patient,
}

class User {
  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    this.role = UserRole.patient, // Default to patient
    this.name,
    this.profileImageUrl,
  });

  // Fixed demo factory constructor with required role parameter
  factory User.demo({required UserRole role}) {
    return User(
      id: 'demo-user-id',
      email: 'patient@example.com',
      role: role, // Use the provided role parameter
      name: 'Demo Patient',
      profileImageUrl: 'https://randomuser.me/api/portraits/women/42.jpg',
    );
  }
}