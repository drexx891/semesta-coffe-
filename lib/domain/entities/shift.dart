import 'package:equatable/equatable.dart';

/// Entity Shift — shift kasir
class Shift extends Equatable {
  final int? id;
  final int userId;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? cashDifference;
  final String status; // 'open' | 'closed'
  final DateTime openedAt;
  final DateTime? closedAt;
  final ShiftSummary? summary;

  // Relasi
  final String? userName;

  const Shift({
    this.id,
    required this.userId,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.cashDifference,
    this.status = 'open',
    required this.openedAt,
    this.closedAt,
    this.summary,
    this.userName,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  /// Cek apakah selisih kas positif (over) atau negatif (short)
  bool get isCashOver => (cashDifference ?? 0) > 0;
  bool get isCashShort => (cashDifference ?? 0) < 0;

  Shift copyWith({
    int? id,
    int? userId,
    double? openingCash,
    double? closingCash,
    double? expectedCash,
    double? cashDifference,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    ShiftSummary? summary,
    String? userName,
  }) {
    return Shift(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      cashDifference: cashDifference ?? this.cashDifference,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      summary: summary ?? this.summary,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [id, userId, status, openedAt];
}

/// Ringkasan shift untuk penutupan
class ShiftSummary extends Equatable {
  final int totalTransactions;
  final int totalVoidTransactions;
  final double totalSales;
  final double totalCashSales;
  final double totalQrisSales;
  final double totalTransferSales;
  final double totalEdcSales;
  final double totalVoucherSales;
  final double totalDiscount;
  final double totalServiceCharge;
  final double totalTax;

  const ShiftSummary({
    this.totalTransactions = 0,
    this.totalVoidTransactions = 0,
    this.totalSales = 0,
    this.totalCashSales = 0,
    this.totalQrisSales = 0,
    this.totalTransferSales = 0,
    this.totalEdcSales = 0,
    this.totalVoucherSales = 0,
    this.totalDiscount = 0,
    this.totalServiceCharge = 0,
    this.totalTax = 0,
  });

  Map<String, dynamic> toJson() => {
    'totalTransactions': totalTransactions,
    'totalVoidTransactions': totalVoidTransactions,
    'totalSales': totalSales,
    'totalCashSales': totalCashSales,
    'totalQrisSales': totalQrisSales,
    'totalTransferSales': totalTransferSales,
    'totalEdcSales': totalEdcSales,
    'totalVoucherSales': totalVoucherSales,
    'totalDiscount': totalDiscount,
    'totalServiceCharge': totalServiceCharge,
    'totalTax': totalTax,
  };

  factory ShiftSummary.fromJson(Map<String, dynamic> json) => ShiftSummary(
    totalTransactions: json['totalTransactions'] as int? ?? 0,
    totalVoidTransactions: json['totalVoidTransactions'] as int? ?? 0,
    totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
    totalCashSales: (json['totalCashSales'] as num?)?.toDouble() ?? 0,
    totalQrisSales: (json['totalQrisSales'] as num?)?.toDouble() ?? 0,
    totalTransferSales: (json['totalTransferSales'] as num?)?.toDouble() ?? 0,
    totalEdcSales: (json['totalEdcSales'] as num?)?.toDouble() ?? 0,
    totalVoucherSales: (json['totalVoucherSales'] as num?)?.toDouble() ?? 0,
    totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
    totalServiceCharge: (json['totalServiceCharge'] as num?)?.toDouble() ?? 0,
    totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [totalTransactions, totalSales, totalCashSales];
}
