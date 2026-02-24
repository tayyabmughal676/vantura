class InventoryItem {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final int lowStockThreshold;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.lowStockThreshold = 5,
    required this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      quantity: map['quantity'],
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    int? lowStockThreshold,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
