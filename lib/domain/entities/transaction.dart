import 'package:equatable/equatable.dart';
import 'product.dart';

/// Entity Transaction — transaksi penjualan
class Transaction extends Equatable {
  final int? id;
  final String transactionNumber;
  final int shiftId;
  final int userId;
  final String orderType; // 'dine_in' | 'take_away'
  final String? tableNumber;
  final String? queueNumber;
  final double subtotal;
  final double discountAmount;
  final double discountPercentage;
  final String? discountReason;
  final double serviceChargeAmount;
  final double taxAmount;
  final double total;
  final String paymentMethod; // 'cash' | 'qris' | 'transfer' | 'edc' | 'voucher'
  final double cashReceived;
  final double cashChange;
  final String? voucherCode;
  final int? customerId;
  final String status; // 'completed' | 'void'
  final String orderStatus; // 'queued' | 'preparing' | 'ready' | 'served' | 'completed'
  final String? voidReason;
  final int? voidedBy;
  final DateTime? voidedAt;
  final DateTime createdAt;

  // Relasi
  final String? userName;
  final String? voidedByName;
  final String? customerName;
  final List<TransactionItem>? items;

  const Transaction({
    this.id,
    required this.transactionNumber,
    required this.shiftId,
    required this.userId,
    required this.orderType,
    this.tableNumber,
    this.queueNumber,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountPercentage = 0,
    this.discountReason,
    this.serviceChargeAmount = 0,
    this.taxAmount = 0,
    required this.total,
    required this.paymentMethod,
    this.cashReceived = 0,
    this.cashChange = 0,
    this.voucherCode,
    this.customerId,
    this.status = 'completed',
    this.orderStatus = 'completed',
    this.voidReason,
    this.voidedBy,
    this.voidedAt,
    required this.createdAt,
    this.userName,
    this.voidedByName,
    this.customerName,
    this.items,
  });

  bool get isVoid => status == 'void';
  bool get isCompleted => status == 'completed';
  bool get isDineIn => orderType == 'dine_in';
  bool get isTakeAway => orderType == 'take_away';
  bool get isCash => paymentMethod == 'cash';

  /// Cek apakah transaksi bisa di-void (hari yang sama)
  bool get canVoidToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day &&
        !isVoid;
  }

  /// Cek apakah transaksi kurang dari 24 jam
  bool get isWithin24Hours {
    return DateTime.now().difference(createdAt).inHours < 24 && !isVoid;
  }

  Transaction copyWith({
    int? id,
    String? transactionNumber,
    int? shiftId,
    int? userId,
    String? orderType,
    String? tableNumber,
    String? queueNumber,
    double? subtotal,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
    double? serviceChargeAmount,
    double? taxAmount,
    double? total,
    String? paymentMethod,
    double? cashReceived,
    double? cashChange,
    String? voucherCode,
    int? customerId,
    String? status,
    String? orderStatus,
    String? voidReason,
    int? voidedBy,
    DateTime? voidedAt,
    DateTime? createdAt,
    String? userName,
    String? voidedByName,
    String? customerName,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      shiftId: shiftId ?? this.shiftId,
      userId: userId ?? this.userId,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      queueNumber: queueNumber ?? this.queueNumber,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountReason: discountReason ?? this.discountReason,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      cashChange: cashChange ?? this.cashChange,
      voucherCode: voucherCode ?? this.voucherCode,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      orderStatus: orderStatus ?? this.orderStatus,
      voidReason: voidReason ?? this.voidReason,
      voidedBy: voidedBy ?? this.voidedBy,
      voidedAt: voidedAt ?? this.voidedAt,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      voidedByName: voidedByName ?? this.voidedByName,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, transactionNumber, status, total];
}

/// Entity TransactionItem — item dalam transaksi
class TransactionItem extends Equatable {
  final int? id;
  final int? transactionId;
  final int productId;
  final String productName;
  final String size;
  final String sugarLevel;
  final String iceLevel;
  final bool extraShot;
  final List<ToppingInfo>? toppings;
  final String? notes;
  final double unitPrice;
  final double modifierPrice;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    this.size = 'regular',
    this.sugarLevel = 'normal',
    this.iceLevel = 'normal',
    this.extraShot = false,
    this.toppings,
    this.notes,
    required this.unitPrice,
    this.modifierPrice = 0,
    required this.quantity,
    required this.subtotal,
  });

  /// Harga per item termasuk modifier
  double get pricePerItem => unitPrice + modifierPrice;

  /// String modifier untuk display
  String get modifierDisplay {
    final parts = <String>[];
    if (size == 'large') parts.add('Large');
    if (sugarLevel == 'less') parts.add('Less Sugar');
    if (sugarLevel == 'none') parts.add('No Sugar');
    if (iceLevel == 'less') parts.add('Less Ice');
    if (iceLevel == 'none') parts.add('No Ice');
    if (extraShot) parts.add('Extra Shot');
    if (toppings != null) {
      for (final t in toppings!) {
        parts.add(t.name);
      }
    }
    return parts.join(' | ');
  }

  bool get hasModifiers =>
      size != 'regular' ||
      sugarLevel != 'normal' ||
      iceLevel != 'normal' ||
      extraShot ||
      (toppings != null && toppings!.isNotEmpty);

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    String? size,
    String? sugarLevel,
    String? iceLevel,
    bool? extraShot,
    List<ToppingInfo>? toppings,
    String? notes,
    double? unitPrice,
    double? modifierPrice,
    int? quantity,
    double? subtotal,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
      extraShot: extraShot ?? this.extraShot,
      toppings: toppings ?? this.toppings,
      notes: notes ?? this.notes,
      unitPrice: unitPrice ?? this.unitPrice,
      modifierPrice: modifierPrice ?? this.modifierPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  List<Object?> get props => [id, productId, productName, quantity, subtotal];
}

/// Info topping sederhana untuk serialisasi JSON di transaction_items
class ToppingInfo extends Equatable {
  final int id;
  final String name;
  final double price;

  const ToppingInfo({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory ToppingInfo.fromJson(Map<String, dynamic> json) => ToppingInfo(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
  );

  factory ToppingInfo.fromTopping(Topping topping) => ToppingInfo(
    id: topping.id!,
    name: topping.name,
    price: topping.price,
  );

  @override
  List<Object?> get props => [id, name, price];
}
