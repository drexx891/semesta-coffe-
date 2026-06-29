import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/database/dao/voucher_dao.dart';
import 'voucher_event.dart';
import 'voucher_state.dart';

class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  final VoucherDao voucherDao;

  VoucherBloc({required this.voucherDao}) : super(VoucherInitial()) {
    on<LoadVouchers>(_onLoadVouchers);
    on<AddVoucher>(_onAddVoucher);
    on<UpdateVoucher>(_onUpdateVoucher);
    on<DeleteVoucher>(_onDeleteVoucher);
  }

  Future<void> _onLoadVouchers(LoadVouchers event, Emitter<VoucherState> emit) async {
    emit(VoucherLoading());
    try {
      final vouchers = await voucherDao.getAllVouchers();
      emit(VoucherLoaded(vouchers: vouchers));
    } catch (e) {
      emit(VoucherError('Gagal memuat daftar voucher: $e'));
    }
  }

  Future<void> _onAddVoucher(AddVoucher event, Emitter<VoucherState> emit) async {
    try {
      await voucherDao.insertVoucher(event.voucher);
      emit(const VoucherActionSuccess('Voucher berhasil ditambahkan'));
      add(LoadVouchers());
    } catch (e) {
      emit(VoucherError('Gagal menambah voucher: $e'));
      add(LoadVouchers());
    }
  }

  Future<void> _onUpdateVoucher(UpdateVoucher event, Emitter<VoucherState> emit) async {
    try {
      await voucherDao.updateVoucher(event.voucher);
      emit(const VoucherActionSuccess('Data voucher berhasil diperbarui'));
      add(LoadVouchers());
    } catch (e) {
      emit(VoucherError('Gagal memperbarui voucher: $e'));
      add(LoadVouchers());
    }
  }

  Future<void> _onDeleteVoucher(DeleteVoucher event, Emitter<VoucherState> emit) async {
    try {
      await voucherDao.deleteVoucher(event.id);
      emit(const VoucherActionSuccess('Voucher berhasil dihapus'));
      add(LoadVouchers());
    } catch (e) {
      emit(VoucherError('Gagal menghapus voucher: $e'));
      add(LoadVouchers());
    }
  }
}
