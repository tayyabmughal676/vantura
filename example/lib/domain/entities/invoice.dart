enum InvoiceStatus { draft, sent, paid, overdue, cancelled, accepted, rejected }

enum InvoiceType { invoice, quote }

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
    );
  }

  InvoiceItem copyWith({
    String? description,
    int? quantity,
    double? unitPrice,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? clientId;
  final String clientName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String? notes;
  final InvoiceType type;
  final DateTime createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.clientId,
    required this.clientName,
    required this.items,
    required this.subtotal,
    this.taxRate = 0.0,
    DateTime? dueDate,
    this.notes,
    this.type = InvoiceType.invoice,
    InvoiceStatus? status,
    DateTime? issueDate,
    DateTime? createdAt,
  }) : status =
           status ??
           (type == InvoiceType.quote
               ? InvoiceStatus.draft
               : InvoiceStatus.draft),
       issueDate = issueDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30)),
       createdAt = createdAt ?? DateTime.now(),
       taxAmount = subtotal * taxRate,
       total = subtotal + (subtotal * taxRate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'clientName': clientName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'status': status.name,
      'type': type.name,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      items: (map['items'] as List<dynamic>)
          .map((item) => InvoiceItem.fromMap(item))
          .toList(),
      subtotal: map['subtotal'],
      taxRate: map['taxRate'],
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      type: InvoiceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvoiceType.invoice,
      ),
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? clientId,
    String? clientName,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxRate,
    InvoiceStatus? status,
    InvoiceType? type,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      type: type ?? this.type,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
