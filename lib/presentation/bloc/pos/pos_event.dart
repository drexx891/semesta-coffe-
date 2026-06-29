import 'package:equatable/equatable.dart';
import '../../../domain/entities/hold_order.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/voucher.dart';

abstract class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class InitPos extends PosEvent {}

class AddToCart extends PosEvent {
  final CartItem item;
  const AddToCart(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdateCartItemQuantity extends PosEvent {
  final int index;
  final int delta;
  const UpdateCartItemQuantity(this.index, this.delta);
  @override
  List<Object?> get props => [index, delta];
}

class RemoveFromCart extends PosEvent {
  final int index;
  const RemoveFromCart(this.index);
  @override
  List<Object?> get props => [index];
}

class ClearCart extends PosEvent {}

class SetOrderType extends PosEvent {
  final String orderType;
  const SetOrderType(this.orderType);
  @override
  List<Object?> get props => [orderType];
}

class SetTableNumber extends PosEvent {
  final String? tableNumber;
  const SetTableNumber(this.tableNumber);
  @override
  List<Object?> get props => [tableNumber];
}

class SetCustomer extends PosEvent {
  final Customer? customer;
  const SetCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class SetCustomerName extends PosEvent {
  final String customerName;
  const SetCustomerName(this.customerName);
  @override
  List<Object?> get props => [customerName];
}

class ApplyDiscount extends PosEvent {
  final double percentage;
  final double nominal;
  const ApplyDiscount(this.percentage, this.nominal);
  @override
  List<Object?> get props => [percentage, nominal];
}

class ClearDiscount extends PosEvent {}

class ApplyVoucher extends PosEvent {
  final Voucher voucher;
  const ApplyVoucher(this.voucher);
  @override
  List<Object?> get props => [voucher];
}

class ClearVoucher extends PosEvent {}

class ProcessPayment extends PosEvent {
  final String paymentMethod;
  final double cashReceived;
  const ProcessPayment(this.paymentMethod, this.cashReceived);
  @override
  List<Object?> get props => [paymentMethod, cashReceived];
}

class SaveHoldOrder extends PosEvent {
  final String label;
  const SaveHoldOrder(this.label);
  @override
  List<Object?> get props => [label];
}

class LoadHoldOrder extends PosEvent {
  final HoldOrder holdOrder;
  const LoadHoldOrder(this.holdOrder);
  @override
  List<Object?> get props => [holdOrder];
}

class CheckShiftStatus extends PosEvent {}

class SyncCartState extends PosEvent {
  final String status;
  final String? paymentMethod;
  const SyncCartState({this.status = 'ordering', this.paymentMethod});
  @override
  List<Object?> get props => [status, paymentMethod];
}

class ResetPos extends PosEvent {}

class StartNewTransaction extends PosEvent {}
