import 'package:equatable/equatable.dart';

/// Entity StoreSettings — pengaturan toko
class StoreSettings extends Equatable {
  final int? id;
  final String storeName;
  final String? storeLogoPath;
  final String storeAddress;
  final String storePhone;
  final String storeNpwp;
  final String receiptFooter;
  final double taxPercentage;
  final double serviceChargePercentage;
  final bool taxEnabled;
  final bool serviceChargeEnabled;
  final double maxCashierDiscount;
  final int sessionTimeoutMinutes;
  final int holdOrderTimeoutMinutes;
  final String? qrisImagePath;
  final String printerPaperSize; // '58mm' | '80mm'
  final int receiptCopies;
  final String dailyBackupTime;
  final String? receiptPrinterAddress;
  final String? baristaPrinterAddress;
  final DateTime updatedAt;

  const StoreSettings({
    this.id,
    this.storeName = 'Smesta Coffee',
    this.storeLogoPath,
    this.storeAddress = '',
    this.storePhone = '',
    this.storeNpwp = '',
    this.receiptFooter = 'Terima kasih telah berkunjung!',
    this.taxPercentage = 11.0,
    this.serviceChargePercentage = 5.0,
    this.taxEnabled = true,
    this.serviceChargeEnabled = true,
    this.maxCashierDiscount = 20.0,
    this.sessionTimeoutMinutes = 15,
    this.holdOrderTimeoutMinutes = 120,
    this.qrisImagePath,
    this.printerPaperSize = '58mm',
    this.receiptCopies = 1,
    this.dailyBackupTime = '02:00',
    this.receiptPrinterAddress,
    this.baristaPrinterAddress,
    required this.updatedAt,
  });

  /// Lebar karakter struk berdasarkan ukuran kertas
  int get receiptCharWidth => printerPaperSize == '80mm' ? 48 : 32;

  /// Tax rate sebagai desimal (0.11)
  double get taxRate => taxPercentage / 100;

  /// Service charge rate sebagai desimal (0.05)
  double get serviceChargeRate => serviceChargePercentage / 100;

  /// Max cashier discount sebagai desimal (0.20)
  double get maxCashierDiscountRate => maxCashierDiscount / 100;

  StoreSettings copyWith({
    int? id,
    String? storeName,
    String? storeLogoPath,
    String? storeAddress,
    String? storePhone,
    String? storeNpwp,
    String? receiptFooter,
    double? taxPercentage,
    double? serviceChargePercentage,
    bool? taxEnabled,
    bool? serviceChargeEnabled,
    double? maxCashierDiscount,
    int? sessionTimeoutMinutes,
    int? holdOrderTimeoutMinutes,
    String? qrisImagePath,
    String? printerPaperSize,
    int? receiptCopies,
    String? dailyBackupTime,
    String? receiptPrinterAddress,
    String? baristaPrinterAddress,
    DateTime? updatedAt,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeLogoPath: storeLogoPath ?? this.storeLogoPath,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeNpwp: storeNpwp ?? this.storeNpwp,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      serviceChargePercentage: serviceChargePercentage ?? this.serviceChargePercentage,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      maxCashierDiscount: maxCashierDiscount ?? this.maxCashierDiscount,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      holdOrderTimeoutMinutes: holdOrderTimeoutMinutes ?? this.holdOrderTimeoutMinutes,
      qrisImagePath: qrisImagePath ?? this.qrisImagePath,
      printerPaperSize: printerPaperSize ?? this.printerPaperSize,
      receiptCopies: receiptCopies ?? this.receiptCopies,
      dailyBackupTime: dailyBackupTime ?? this.dailyBackupTime,
      receiptPrinterAddress: receiptPrinterAddress ?? this.receiptPrinterAddress,
      baristaPrinterAddress: baristaPrinterAddress ?? this.baristaPrinterAddress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, storeName, taxPercentage, serviceChargePercentage];
}
