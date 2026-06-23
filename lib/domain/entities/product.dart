import 'package:equatable/equatable.dart';

/// Entity Product (produk menu)
class Product extends Equatable {
  final int? id;
  final int categoryId;
  final String name;
  final String description;
  final String? imagePath;
  final double priceRegular;
  final double? priceLarge;
  final bool hasLargeSize;
  final bool hasSugarLevel;
  final bool hasIceLevel;
  final bool hasExtraShot;
  final double extraShotPrice;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi (diisi saat dibutuhkan)
  final String? categoryName;
  final List<Topping>? availableToppings;
  final bool? hasRecipe;
  final bool? isStockAvailable; // null jika tidak dicek

  const Product({
    this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.imagePath,
    required this.priceRegular,
    this.priceLarge,
    this.hasLargeSize = false,
    this.hasSugarLevel = false,
    this.hasIceLevel = false,
    this.hasExtraShot = false,
    this.extraShotPrice = 0,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.availableToppings,
    this.hasRecipe,
    this.isStockAvailable,
  });

  /// Mendapatkan harga berdasarkan ukuran
  double getPrice(String size) {
    if (size == 'large' && hasLargeSize && priceLarge != null) {
      return priceLarge!;
    }
    return priceRegular;
  }

  /// Check apakah produk memiliki modifier
  bool get hasModifiers => hasSugarLevel || hasIceLevel || hasExtraShot || hasLargeSize;

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    String? imagePath,
    double? priceRegular,
    double? priceLarge,
    bool? hasLargeSize,
    bool? hasSugarLevel,
    bool? hasIceLevel,
    bool? hasExtraShot,
    double? extraShotPrice,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    List<Topping>? availableToppings,
    bool? hasRecipe,
    bool? isStockAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      priceRegular: priceRegular ?? this.priceRegular,
      priceLarge: priceLarge ?? this.priceLarge,
      hasLargeSize: hasLargeSize ?? this.hasLargeSize,
      hasSugarLevel: hasSugarLevel ?? this.hasSugarLevel,
      hasIceLevel: hasIceLevel ?? this.hasIceLevel,
      hasExtraShot: hasExtraShot ?? this.hasExtraShot,
      extraShotPrice: extraShotPrice ?? this.extraShotPrice,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      availableToppings: availableToppings ?? this.availableToppings,
      hasRecipe: hasRecipe ?? this.hasRecipe,
      isStockAvailable: isStockAvailable ?? this.isStockAvailable,
    );
  }

  @override
  List<Object?> get props => [id, name, categoryId, priceRegular, isActive];
}

/// Entity Topping
class Topping extends Equatable {
  final int? id;
  final String name;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  const Topping({
    this.id,
    required this.name,
    required this.price,
    this.isActive = true,
    required this.createdAt,
  });

  Topping copyWith({
    int? id,
    String? name,
    double? price,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Topping(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, price, isActive];
}

/// Entity Modifier — representasi modifier yang dipilih untuk item di keranjang
class ProductModifier extends Equatable {
  final String size; // 'regular' | 'large'
  final String sugarLevel; // 'normal' | 'less' | 'none'
  final String iceLevel; // 'normal' | 'less' | 'none'
  final bool extraShot;
  final List<Topping> selectedToppings;

  const ProductModifier({
    this.size = 'regular',
    this.sugarLevel = 'normal',
    this.iceLevel = 'normal',
    this.extraShot = false,
    this.selectedToppings = const [],
  });

  /// Hitung total harga modifier
  double calculateModifierPrice(Product product) {
    double total = 0;

    // Perbedaan harga ukuran Large
    if (size == 'large' && product.hasLargeSize && product.priceLarge != null) {
      total += product.priceLarge! - product.priceRegular;
    }

    // Extra shot
    if (extraShot) {
      total += product.extraShotPrice;
    }

    // Topping
    for (final topping in selectedToppings) {
      total += topping.price;
    }

    return total;
  }

  /// String deskripsi modifier untuk display di keranjang
  String get displayText {
    final parts = <String>[];

    if (size == 'large') parts.add('Large');
    if (sugarLevel == 'less') parts.add('Less Sugar');
    if (sugarLevel == 'none') parts.add('No Sugar');
    if (iceLevel == 'less') parts.add('Less Ice');
    if (iceLevel == 'none') parts.add('No Ice');
    if (extraShot) parts.add('Extra Shot');
    for (final topping in selectedToppings) {
      parts.add(topping.name);
    }

    return parts.join(' | ');
  }

  ProductModifier copyWith({
    String? size,
    String? sugarLevel,
    String? iceLevel,
    bool? extraShot,
    List<Topping>? selectedToppings,
  }) {
    return ProductModifier(
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
      extraShot: extraShot ?? this.extraShot,
      selectedToppings: selectedToppings ?? this.selectedToppings,
    );
  }

  @override
  List<Object?> get props => [size, sugarLevel, iceLevel, extraShot, selectedToppings];
}
