import 'package:equatable/equatable.dart';
import '../../../../domain/entities/voucher.dart';

abstract class VoucherEvent extends Equatable {
  const VoucherEvent();

  @override
  List<Object?> get props => [];
}

class LoadVouchers extends VoucherEvent {}

class AddVoucher extends VoucherEvent {
  final Voucher voucher;

  const AddVoucher(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class UpdateVoucher extends VoucherEvent {
  final Voucher voucher;

  const UpdateVoucher(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class DeleteVoucher extends VoucherEvent {
  final int id;

  const DeleteVoucher(this.id);

  @override
  List<Object?> get props => [id];
}
