/// Authenticated user linked to a store
class AppUser {
  final String id;
  final String businessId;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.businessId,
    required this.email,
    this.displayName,
    this.role = 'OWNER',
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? businessId,
    String? email,
    String? displayName,
    String? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
