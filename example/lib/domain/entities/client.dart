class Client {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
