import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/dao/product_dao.dart';
import 'menu_management_event.dart';
import 'menu_management_state.dart';

class MenuManagementBloc extends Bloc<MenuManagementEvent, MenuManagementState> {
  final ProductDao _productDao;

  MenuManagementBloc({required ProductDao productDao})
      : _productDao = productDao,
        super(MenuManagementInitial()) {
    on<LoadMenuManagement>(_onLoadMenuManagement);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<ToggleProductActive>(_onToggleProductActive);
    on<DeleteProduct>(_onDeleteProduct);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadMenuManagement(LoadMenuManagement event, Emitter<MenuManagementState> emit) async {
    emit(MenuManagementLoading());
    try {
      // Load all categories and products, including inactive ones for management
      final categories = await _productDao.getAllCategories(activeOnly: false);
      final products = await _productDao.getAllProducts(activeOnly: false);
      emit(MenuManagementLoaded(categories: categories, products: products));
    } catch (e) {
      emit(MenuManagementError('Gagal memuat data menu: $e'));
    }
  }

  Future<void> _onCreateCategory(CreateCategory event, Emitter<MenuManagementState> emit) async {
    try {
      await _productDao.insertCategory({
        'name': event.name,
        'sort_order': event.sortOrder,
        'is_active': 1,
      });
      emit(const MenuManagementActionSuccess('Kategori berhasil ditambahkan'));
      add(LoadMenuManagement()); // Reload data
    } catch (e) {
      emit(MenuManagementError('Gagal menambahkan kategori: $e'));
    }
  }

  Future<void> _onUpdateCategory(UpdateCategory event, Emitter<MenuManagementState> emit) async {
    try {
      await _productDao.updateCategory(event.id, {
        'name': event.name,
        'sort_order': event.sortOrder,
      });
      emit(const MenuManagementActionSuccess('Kategori berhasil diperbarui'));
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal memperbarui kategori: $e'));
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<MenuManagementState> emit) async {
    try {
      final hasProducts = await _productDao.hasProductsInCategory(event.id);
      if (hasProducts) {
        emit(const MenuManagementError('Kategori tidak dapat dihapus karena masih berisi produk. Kosongkan kategori terlebih dahulu.'));
        return;
      }
      
      await _productDao.deleteCategory(event.id);
      emit(const MenuManagementActionSuccess('Kategori berhasil dihapus'));
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal menghapus kategori: $e'));
    }
  }

  Future<void> _onCreateProduct(CreateProduct event, Emitter<MenuManagementState> emit) async {
    try {
      await _productDao.insertProduct(event.productData);
      emit(const MenuManagementActionSuccess('Produk berhasil ditambahkan'));
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal menambahkan produk: $e'));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<MenuManagementState> emit) async {
    try {
      await _productDao.updateProduct(event.id, event.productData);
      emit(const MenuManagementActionSuccess('Produk berhasil diperbarui'));
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal memperbarui produk: $e'));
    }
  }

  Future<void> _onToggleProductActive(ToggleProductActive event, Emitter<MenuManagementState> emit) async {
    try {
      await _productDao.toggleActive(event.id, event.isActive);
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal mengubah status produk: $e'));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<MenuManagementState> emit) async {
    try {
      final hasTransactions = await _productDao.hasTransactions(event.id);
      if (hasTransactions) {
        emit(const MenuManagementError('Produk tidak dapat dihapus karena sudah memiliki riwayat transaksi. Nonaktifkan saja.'));
        return;
      }
      
      await _productDao.deleteProduct(event.id);
      emit(const MenuManagementActionSuccess('Produk berhasil dihapus'));
      add(LoadMenuManagement());
    } catch (e) {
      emit(MenuManagementError('Gagal menghapus produk: $e'));
    }
  }
}
