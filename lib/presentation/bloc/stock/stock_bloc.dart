import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/dao/stock_dao.dart';
import 'stock_event.dart';
import 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockDao stockDao;

  StockBloc({required this.stockDao}) : super(StockInitial()) {
    on<LoadStock>(_onLoadStock);
    on<AddIngredient>(_onAddIngredient);
    on<UpdateIngredient>(_onUpdateIngredient);
    on<DeleteIngredient>(_onDeleteIngredient);
    on<AddStock>(_onAddStock);
    on<CorrectStock>(_onCorrectStock);
  }

  Future<void> _onLoadStock(LoadStock event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final ingredients = await stockDao.getAllIngredients();
      final criticalCount = await stockDao.countCriticalStock();
      emit(StockLoaded(ingredients: ingredients, criticalCount: criticalCount));
    } catch (e) {
      emit(StockError('Gagal memuat data stok: $e'));
    }
  }

  Future<void> _onAddIngredient(AddIngredient event, Emitter<StockState> emit) async {
    try {
      await stockDao.insertIngredient(event.ingredientData);
      emit(const StockActionSuccess('Bahan baku berhasil ditambahkan'));
      add(LoadStock());
    } catch (e) {
      emit(StockError('Gagal menambah bahan baku: $e'));
      add(LoadStock());
    }
  }

  Future<void> _onUpdateIngredient(UpdateIngredient event, Emitter<StockState> emit) async {
    try {
      await stockDao.updateIngredient(event.id, event.ingredientData);
      emit(const StockActionSuccess('Bahan baku berhasil diperbarui'));
      add(LoadStock());
    } catch (e) {
      emit(StockError('Gagal memperbarui bahan baku: $e'));
      add(LoadStock());
    }
  }

  Future<void> _onDeleteIngredient(DeleteIngredient event, Emitter<StockState> emit) async {
    try {
      // Assuming a delete method exists or we handle it. 
      // If StockDao doesn't have delete, we might need to soft delete or just skip.
      // We will implement delete in DAO if it doesn't exist.
      await stockDao.deleteIngredient(event.id);
      emit(const StockActionSuccess('Bahan baku berhasil dihapus'));
      add(LoadStock());
    } catch (e) {
      emit(StockError('Gagal menghapus bahan baku: $e'));
      add(LoadStock());
    }
  }

  Future<void> _onAddStock(AddStock event, Emitter<StockState> emit) async {
    try {
      await stockDao.addStock(
        ingredientId: event.ingredientId,
        quantity: event.quantity,
        userId: event.userId,
        invoiceNumber: event.invoiceNumber,
      );
      emit(const StockActionSuccess('Stok berhasil ditambahkan'));
      add(LoadStock());
    } catch (e) {
      emit(StockError('Gagal menambah stok: $e'));
      add(LoadStock());
    }
  }

  Future<void> _onCorrectStock(CorrectStock event, Emitter<StockState> emit) async {
    try {
      await stockDao.correctStock(
        ingredientId: event.ingredientId,
        newQuantity: event.newQuantity,
        reason: event.reason,
        userId: event.userId,
      );
      emit(const StockActionSuccess('Koreksi stok berhasil disimpan'));
      add(LoadStock());
    } catch (e) {
      emit(StockError('Gagal mengoreksi stok: $e'));
      add(LoadStock());
    }
  }
}
