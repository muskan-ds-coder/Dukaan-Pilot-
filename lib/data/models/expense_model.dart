import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.businessId,
    required super.category,
    required super.amountPaise,
    super.description,
    required super.date,
    required super.createdAt,
    super.syncStatus = 'PENDING',
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      businessId: entity.businessId,
      category: entity.category,
      amountPaise: entity.amountPaise,
      description: entity.description,
      date: entity.date,
      createdAt: entity.createdAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      category: map['category'] as String,
      amountPaise: map['amount_paise'] as int,
      description: map['description'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category': category,
      'amount_paise': amountPaise,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }
}
