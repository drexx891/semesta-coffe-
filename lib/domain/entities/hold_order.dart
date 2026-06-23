import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'transaction.dart';

/// Entity HoldOrder — pesanan yang ditahan sementara
class HoldOrder extends Equatable {
  final int? id;
  final String label;
  final String orderType; // 'dine_in' | 'take_away'
  final String? tableNumber;
  final List<CartItem> items;
  final int userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Relasi
  final String? userName;

  const HoldOrder({
    this.id,
    required this.label,
    required this.orderType,
    this.tableNumber,
    required this.items,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    this.userName,
  });

  /// Check apakah hold order sudah expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Sisa waktu sebelum expired
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Total items di hold order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total harga kasar (tanpa diskon/pajak)
  double get estimatedTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  HoldOrder copyWith({
    int? id,
    String? label,
    String? orderType,
    String? tableNumber,
    List<CartItem>? items,
    int? userId,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? userName,
  }) {
    return HoldOrder(
      id: id ?? this.id,
      label: label ?? this.label,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [id, label, orderType, createdAt];
}

/// CartItem — item di keranjang belanja (digunakan di POS dan HoldOrder)
class CartItem extends Equatable {
  final String cartItemId; // UUID unik per item di keranjang
  final int productId;
  final String productName;
  final String? productImagePath;
  final String size;
  final String sugarLevel;
  final String iceLevel;
  final bool extraShot;
  final List<ToppingInfo> selectedToppings;
  final String? notes;
  final double basePrice; // Harga dasar sesuai ukuran
  final double modifierPrice; // Total harga modifier
  final int quantity;

  const CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    this.productImagePath,
    this.size = 'regular',
    this.sugarLevel = 'normal',
    this.iceLevel = 'normal',
    this.extraShot = false,
    this.selectedToppings = const [],
    this.notes,
    required this.basePrice,
    this.modifierPrice = 0,
    this.quantity = 1,
  });

  /// Harga per unit (base + modifier)
  double get unitPrice => basePrice + modifierPrice;

  /// Subtotal = unitPrice × quantity
  double get subtotal => unitPrice * quantity;

  /// String modifier untuk display
  String get modifierDisplay {
    final parts = <String>[];
    if (size == 'large') parts.add('Large');
    if (sugarLevel == 'less') parts.add('Less Sugar');
    if (sugarLevel == 'none') parts.add('No Sugar');
    if (iceLevel == 'less') parts.add('Less Ice');
    if (iceLevel == 'none') parts.add('No Ice');
    if (extraShot) parts.add('Extra Shot');
    for (final t in selectedToppings) {
      parts.add(t.name);
    }
    return parts.join(' · ');
  }

  bool get hasModifiers =>
      size != 'regular' ||
      sugarLevel != 'normal' ||
      iceLevel != 'normal' ||
      extraShot ||
      selectedToppings.isNotEmpty;

  /// Serialisasi ke JSON untuk penyimpanan hold order
  Map<String, dynamic> toJson() => {
    'cartItemId': cartItemId,
    'productId': productId,
    'productName': productName,
    'productImagePath': productImagePath,
    'size': size,
    'sugarLevel': sugarLevel,
    'iceLevel': iceLevel,
    'extraShot': extraShot,
    'selectedToppings': selectedToppings.map((t) => t.toJson()).toList(),
    'notes': notes,
    'basePrice': basePrice,
    'modifierPrice': modifierPrice,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    cartItemId: json['cartItemId'] as String,
    productId: json['productId'] as int,
    productName: json['productName'] as String,
    productImagePath: json['productImagePath'] as String?,
    size: json['size'] as String? ?? 'regular',
    sugarLevel: json['sugarLevel'] as String? ?? 'normal',
    iceLevel: json['iceLevel'] as String? ?? 'normal',
    extraShot: json['extraShot'] as bool? ?? false,
    selectedToppings: (json['selectedToppings'] as List<dynamic>?)
        ?.map((t) => ToppingInfo.fromJson(t as Map<String, dynamic>))
        .toList() ?? [],
    notes: json['notes'] as String?,
    basePrice: (json['basePrice'] as num).toDouble(),
    modifierPrice: (json['modifierPrice'] as num?)?.toDouble() ?? 0,
    quantity: json['quantity'] as int? ?? 1,
  );

  /// Encode list of CartItems to JSON string
  static String encodeList(List<CartItem> items) {
    return jsonEncode(items.map((i) => i.toJson()).toList());
  }

  /// Decode JSON string to list of CartItems
  static List<CartItem> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  CartItem copyWith({
    String? cartItemId,
    int? productId,
    String? productName,
    String? productImagePath,
    String? size,
    String? sugarLevel,
    String? iceLevel,
    bool? extraShot,
    List<ToppingInfo>? selectedToppings,
    String? notes,
    double? basePrice,
    double? modifierPrice,
    int? quantity,
  }) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImagePath: productImagePath ?? this.productImagePath,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
      extraShot: extraShot ?? this.extraShot,
      selectedToppings: selectedToppings ?? this.selectedToppings,
      notes: notes ?? this.notes,
      basePrice: basePrice ?? this.basePrice,
      modifierPrice: modifierPrice ?? this.modifierPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [cartItemId, productId, size, sugarLevel, iceLevel, extraShot, quantity];
}
