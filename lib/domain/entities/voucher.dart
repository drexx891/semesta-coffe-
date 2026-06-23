import 'package:equatable/equatable.dart';

class Voucher extends Equatable {
  final int? id;
  final String code;
  final double discountPercentage;
  final double discountNominal;
  final double minPurchase;
  final double maxDiscount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;

  const Voucher({
    this.id,
    required this.code,
    required this.discountPercentage,
    required this.discountNominal,
    required this.minPurchase,
    required this.maxDiscount,
    required this.validFrom,
    required this.validUntil,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    required this.createdAt,
  });

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
           usedCount < usageLimit &&
           now.isAfter(validFrom) &&
           now.isBefore(validUntil);
  }

  double calculateDiscount(double subtotal) {
    if (!isValid || subtotal < minPurchase) return 0.0;
    
    double discount = discountNominal;
    if (discountPercentage > 0) {
      discount += subtotal * (discountPercentage / 100);
    }
    
    if (maxDiscount > 0 && discount > maxDiscount) {
      discount = maxDiscount;
    }
    
    return discount;
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int?,
      code: json['code'] as String,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      discountNominal: (json['discount_nominal'] as num?)?.toDouble() ?? 0.0,
      minPurchase: (json['min_purchase'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble() ?? 0.0,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      usageLimit: json['usage_limit'] as int? ?? 999999,
      usedCount: json['used_count'] as int? ?? 0,
      isActive: (json['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_percentage': discountPercentage,
      'discount_nominal': discountNominal,
      'min_purchase': minPurchase,
      'max_discount': maxDiscount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, code, discountPercentage, discountNominal, minPurchase, 
    maxDiscount, validFrom, validUntil, usageLimit, usedCount, isActive, createdAt
  ];
}
