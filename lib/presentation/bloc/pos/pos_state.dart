import 'package:equatable/equatable.dart';
import '../../../../domain/entities/hold_order.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/entities/voucher.dart';

enum PaymentStatus { idle, processing, success, error }

class PosState extends Equatable {
  final List<CartItem> cartItems;
  final String orderType;
  final String? tableNumber;
  final String? customerNameInput;
  final Customer? selectedCustomer;
  final Voucher? selectedVoucher;
  final double discountPercentage;
  final double discountNominal;
  final double taxPercentage;
  final double serviceChargePercentage;
  final bool taxEnabled;
  final bool serviceChargeEnabled;
  final double maxCashierDiscount;
  final int? activeShiftId;
  final int activeHoldOrders;
  final PaymentStatus paymentStatus;
  final String? errorMessage;
  final String? lastQueueNumber;
  final String? lastTransactionNumber;
  final int? lastTransactionId;

  const PosState({
    this.cartItems = const [],
    this.orderType = 'dine_in',
    this.tableNumber,
    this.customerNameInput,
    this.selectedCustomer,
    this.selectedVoucher,
    this.discountPercentage = 0,
    this.discountNominal = 0,
    this.taxPercentage = 11.0,
    this.serviceChargePercentage = 5.0,
    this.taxEnabled = true,
    this.serviceChargeEnabled = true,
    this.maxCashierDiscount = 20.0,
    this.activeShiftId,
    this.activeHoldOrders = 0,
    this.paymentStatus = PaymentStatus.idle,
    this.errorMessage,
    this.lastQueueNumber,
    this.lastTransactionNumber,
    this.lastTransactionId,
  });

  bool get isShiftOpen => activeShiftId != null;

  double get subtotal => cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (selectedVoucher != null) {
      return selectedVoucher!.calculateDiscount(subtotal);
    }
    if (discountPercentage > 0) {
      return subtotal * (discountPercentage / 100);
    }
    return discountNominal;
  }

  double get afterDiscount => subtotal - discountAmount;

  double get serviceChargeAmount =>
      serviceChargeEnabled ? afterDiscount * (serviceChargePercentage / 100) : 0;

  double get taxAmount =>
      taxEnabled ? (afterDiscount + serviceChargeAmount) * (taxPercentage / 100) : 0;

  double get total => afterDiscount + serviceChargeAmount + taxAmount;

  PosState copyWith({
    List<CartItem>? cartItems,
    String? orderType,
    String? tableNumber,
    String? customerNameInput,
    Customer? selectedCustomer,
    Voucher? selectedVoucher,
    double? discountPercentage,
    double? discountNominal,
    double? taxPercentage,
    double? serviceChargePercentage,
    bool? taxEnabled,
    bool? serviceChargeEnabled,
    double? maxCashierDiscount,
    int? activeShiftId,
    int? activeHoldOrders,
    PaymentStatus? paymentStatus,
    String? errorMessage,
    String? lastQueueNumber,
    String? lastTransactionNumber,
    int? lastTransactionId,
    bool clearCustomer = false,
    bool clearVoucher = false,
    bool clearActiveShiftId = false,
  }) {
    return PosState(
      cartItems: cartItems ?? this.cartItems,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      customerNameInput: clearCustomer ? null : (customerNameInput ?? this.customerNameInput),
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      selectedVoucher: clearVoucher ? null : (selectedVoucher ?? this.selectedVoucher),
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountNominal: discountNominal ?? this.discountNominal,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      serviceChargePercentage: serviceChargePercentage ?? this.serviceChargePercentage,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      maxCashierDiscount: maxCashierDiscount ?? this.maxCashierDiscount,
      activeShiftId: clearActiveShiftId ? null : (activeShiftId ?? this.activeShiftId),
      activeHoldOrders: activeHoldOrders ?? this.activeHoldOrders,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      lastQueueNumber: lastQueueNumber ?? this.lastQueueNumber,
      lastTransactionNumber: lastTransactionNumber ?? this.lastTransactionNumber,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
    );
  }

  @override
  List<Object?> get props => [
        cartItems,
        orderType,
        tableNumber,
        customerNameInput,
        selectedCustomer,
        selectedVoucher,
        discountPercentage,
        discountNominal,
        taxPercentage,
        serviceChargePercentage,
        taxEnabled,
        serviceChargeEnabled,
        maxCashierDiscount,
        activeShiftId,
        activeHoldOrders,
        paymentStatus,
        errorMessage,
        lastQueueNumber,
        lastTransactionNumber,
        lastTransactionId,
      ];
}
