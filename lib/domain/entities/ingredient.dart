import 'package:equatable/equatable.dart';

/// Entity Ingredient (bahan baku)
class Ingredient extends Equatable {
  final int? id;
  final String name;
  final String category; // 'Biji Kopi', 'Susu & Dairy', 'Sirup', 'Packaging', 'Lainnya'
  final String unit; // 'gram', 'ml', 'pcs', 'liter', 'kg'
  final double currentStock;
  final double minStock;
  final double costPerUnit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ingredient({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.currentStock = 0,
    this.minStock = 0,
    this.costPerUnit = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Status stok berdasarkan warna indikator
  StockStatus get stockStatus {
    if (currentStock <= minStock) {
      return StockStatus.critical; // 🔴
    } else if (currentStock <= minStock * 2) {
      return StockStatus.warning; // 🟡
    }
    return StockStatus.safe; // 🟢
  }

  /// Check apakah stok cukup untuk jumlah tertentu
  bool hasEnoughStock(double requiredQuantity) {
    return currentStock >= requiredQuantity;
  }

  Ingredient copyWith({
    int? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minStock,
    double? costPerUnit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, category, unit, currentStock, minStock];
}

/// Enum status stok
enum StockStatus {
  critical, // 🔴 Di bawah minimum
  warning,  // 🟡 Mendekati minimum (< 2× minimum)
  safe;     // 🟢 Aman

  String get displayName {
    switch (this) {
      case StockStatus.critical:
        return 'Kritis';
      case StockStatus.warning:
        return 'Menipis';
      case StockStatus.safe:
        return 'Aman';
    }
  }
}

/// Entity Recipe — hubungan produk → bahan baku
class Recipe extends Equatable {
  final int? id;
  final int productId;
  final int ingredientId;
  final String size; // 'regular' | 'large'
  final double quantity;

  // Relasi
  final String? ingredientName;
  final String? ingredientUnit;

  const Recipe({
    this.id,
    required this.productId,
    required this.ingredientId,
    this.size = 'regular',
    required this.quantity,
    this.ingredientName,
    this.ingredientUnit,
  });

  Recipe copyWith({
    int? id,
    int? productId,
    int? ingredientId,
    String? size,
    double? quantity,
    String? ingredientName,
    String? ingredientUnit,
  }) {
    return Recipe(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      ingredientId: ingredientId ?? this.ingredientId,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientUnit: ingredientUnit ?? this.ingredientUnit,
    );
  }

  @override
  List<Object?> get props => [id, productId, ingredientId, size, quantity];
}

/// Entity ModifierRecipe — resep modifier (Extra Shot, Topping) → bahan baku
class ModifierRecipe extends Equatable {
  final int? id;
  final String modifierType; // 'extra_shot' | 'topping'
  final int? modifierRefId; // topping_id (null for extra_shot)
  final int ingredientId;
  final double quantity;

  // Relasi
  final String? ingredientName;
  final String? ingredientUnit;

  const ModifierRecipe({
    this.id,
    required this.modifierType,
    this.modifierRefId,
    required this.ingredientId,
    required this.quantity,
    this.ingredientName,
    this.ingredientUnit,
  });

  @override
  List<Object?> get props => [id, modifierType, modifierRefId, ingredientId, quantity];
}

/// Entity StockMovement — log pergerakan stok
class StockMovement extends Equatable {
  final int? id;
  final int ingredientId;
  final String movementType; // 'in' | 'out' | 'correction'
  final double quantity;
  final double stockBefore;
  final double stockAfter;
  final String? reference;
  final String? reason;
  final String? invoiceNumber;
  final String? supplier;
  final int userId;
  final DateTime createdAt;

  // Relasi
  final String? ingredientName;
  final String? userName;

  const StockMovement({
    this.id,
    required this.ingredientId,
    required this.movementType,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.reference,
    this.reason,
    this.invoiceNumber,
    this.supplier,
    required this.userId,
    required this.createdAt,
    this.ingredientName,
    this.userName,
  });

  @override
  List<Object?> get props => [id, ingredientId, movementType, quantity, createdAt];
}
