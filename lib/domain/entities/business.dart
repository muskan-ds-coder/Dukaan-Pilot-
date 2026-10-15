/// Represents a business/store in DukaanPilot AI
class Business {
  final String id;
  final String name;
  final String ownerName;
  final String category;
  final String? phone;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  const Business({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.category,
    this.phone,
    this.currency = 'INR',
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'PENDING',
  });

  Business copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? category,
    String? phone,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
