/// Daily and monthly operating business expense
class Expense {
  final String id;
  final String businessId;
  final String category;
  final int amountPaise;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final String syncStatus;

  const Expense({
    required this.id,
    required this.businessId,
    required this.category,
    required this.amountPaise,
    this.description,
    required this.date,
    required this.createdAt,
    this.syncStatus = 'PENDING',
  });

  Expense copyWith({
    String? id,
    String? businessId,
    String? category,
    int? amountPaise,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return Expense(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      category: category ?? this.category,
      amountPaise: amountPaise ?? this.amountPaise,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
