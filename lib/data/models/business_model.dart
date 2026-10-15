import '../../domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    required super.id,
    required super.name,
    required super.ownerName,
    required super.category,
    super.phone,
    super.currency = 'INR',
    required super.createdAt,
    required super.updatedAt,
    super.syncStatus = 'PENDING',
  });

  factory BusinessModel.fromEntity(Business entity) {
    return BusinessModel(
      id: entity.id,
      name: entity.name,
      ownerName: entity.ownerName,
      category: entity.category,
      phone: entity.phone,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerName: map['owner_name'] as String,
      category: map['category'] as String,
      phone: map['phone'] as String?,
      currency: (map['currency'] as String?) ?? 'INR',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'category': category,
      'phone': phone,
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }
}
