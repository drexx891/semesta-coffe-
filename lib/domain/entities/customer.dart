import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final int loyaltyPoints;
  final DateTime? createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.loyaltyPoints = 0,
    this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      loyaltyPoints: map['loyalty_points'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'loyalty_points': loyaltyPoints,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    int? loyaltyPoints,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, loyaltyPoints, createdAt];
}
