import 'package:equatable/equatable.dart';

/// Entity Category untuk grouping produk
class Category extends Equatable {
  final int? id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}
