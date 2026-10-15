/// Customer entity for retail business and credit/udhaar tracking
class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int openingBalancePaise;
  final int currentBalancePaise; // Positive = Customer owes store (Udhaar)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String syncStatus;

  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.openingBalancePaise = 0,
    this.currentBalancePaise = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.syncStatus = 'PENDING',
  });

  bool get hasOutstandingCredit => currentBalancePaise > 0;

  Customer copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? openingBalancePaise,
    int? currentBalancePaise,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? syncStatus,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
