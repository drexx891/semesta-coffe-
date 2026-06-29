import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/database/dao/customer_dao.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerDao customerDao;
  String _currentQuery = '';

  CustomerBloc({required this.customerDao}) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      _currentQuery = '';
      final customers = await customerDao.getAll();
      emit(CustomerLoaded(customers: customers, searchQuery: _currentQuery));
    } catch (e) {
      emit(CustomerError('Gagal memuat pelanggan: $e'));
    }
  }

  Future<void> _onSearchCustomers(SearchCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      _currentQuery = event.query;
      if (_currentQuery.isEmpty) {
        final customers = await customerDao.getAll();
        emit(CustomerLoaded(customers: customers, searchQuery: _currentQuery));
      } else {
        final customers = await customerDao.search(_currentQuery);
        emit(CustomerLoaded(customers: customers, searchQuery: _currentQuery));
      }
    } catch (e) {
      emit(CustomerError('Gagal mencari pelanggan: $e'));
    }
  }

  Future<void> _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      await customerDao.insert(event.customer);
      emit(const CustomerActionSuccess('Pelanggan berhasil ditambahkan'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    } catch (e) {
      emit(CustomerError('Gagal menambah pelanggan: $e'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    }
  }

  Future<void> _onUpdateCustomer(UpdateCustomer event, Emitter<CustomerState> emit) async {
    try {
      await customerDao.update(event.customer);
      emit(const CustomerActionSuccess('Data pelanggan berhasil diperbarui'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    } catch (e) {
      emit(CustomerError('Gagal memperbarui pelanggan: $e'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    }
  }

  Future<void> _onDeleteCustomer(DeleteCustomer event, Emitter<CustomerState> emit) async {
    try {
      await customerDao.delete(event.id);
      emit(const CustomerActionSuccess('Pelanggan berhasil dihapus'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    } catch (e) {
      emit(CustomerError('Gagal menghapus pelanggan: $e'));
      add(_currentQuery.isEmpty ? LoadCustomers() : SearchCustomers(_currentQuery));
    }
  }
}
