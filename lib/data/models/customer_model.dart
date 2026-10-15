import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.openingBalancePaise = 0,
    super.currentBalancePaise = 0,
    required super.createdAt,
    required super.updatedAt,
    super.isActive = true,
    super.syncStatus = 'PENDING',
  });

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      openingBalancePaise: entity.openingBalancePaise,
      currentBalancePaise: entity.currentBalancePaise,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      syncStatus: entity.syncStatus,
    );
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      openingBalancePaise: (map['opening_balance_paise'] as int?) ?? 0,
      currentBalancePaise: (map['current_balance_paise'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'opening_balance_paise': openingBalancePaise,
      'current_balance_paise': currentBalancePaise,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
    };
  }
}
