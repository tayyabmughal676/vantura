enum TransactionType { income, expense, asset, liability }

class LedgerEntry {
  final int? id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? reference;
  final int? relatedInvoiceId;
  final int? relatedClientId;
  final DateTime createdAt;

  LedgerEntry({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    DateTime? date,
    this.reference,
    this.relatedInvoiceId,
    this.relatedClientId,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'reference': reference,
      'relatedInvoiceId': relatedInvoiceId,
      'relatedClientId': relatedClientId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: map['category'],
      date: DateTime.parse(map['date']),
      reference: map['reference'],
      relatedInvoiceId: map['relatedInvoiceId'],
      relatedClientId: map['relatedClientId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  LedgerEntry copyWith({
    int? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? reference,
    int? relatedInvoiceId,
    int? relatedClientId,
    DateTime? createdAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      relatedInvoiceId: relatedInvoiceId ?? this.relatedInvoiceId,
      relatedClientId: relatedClientId ?? this.relatedClientId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
