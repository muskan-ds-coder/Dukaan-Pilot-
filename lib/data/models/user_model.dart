import '../../domain/entities/user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.businessId,
    required super.email,
    super.displayName,
    super.role = 'OWNER',
    required super.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      role: (map['role'] as String?) ?? 'OWNER',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'email': email,
      'display_name': displayName,
      'role': role,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
