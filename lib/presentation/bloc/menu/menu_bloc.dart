import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/dao/product_dao.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final ProductDao _productDao;

  MenuBloc({required ProductDao productDao})
      : _productDao = productDao,
        super(MenuInitial()) {
    on<LoadMenu>(_onLoadMenu);
    on<SelectCategory>(_onSelectCategory);
    on<SearchMenu>(_onSearchMenu);
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final categories = await _productDao.getAllCategories();
      final products = await _productDao.getAllProducts();
      final stockAvailability = await _productDao.checkAllStockAvailability();

      emit(MenuLoaded(
        categories: categories,
        allProducts: products,
        filteredProducts: products,
        stockAvailability: stockAvailability,
      ));
    } catch (e) {
      emit(MenuError('Gagal memuat menu: ${e.toString()}'));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      final isSameCategory = currentState.selectedCategoryId == event.categoryId;
      
      // If tapping the same category, we clear it (toggle off)
      final newCategoryId = isSameCategory ? null : event.categoryId;

      final filtered = _filterProducts(
        currentState.allProducts,
        newCategoryId,
        currentState.searchQuery,
      );

      emit(currentState.copyWith(
        filteredProducts: filtered,
        selectedCategoryId: newCategoryId,
        clearCategoryId: isSameCategory,
      ));
    }
  }

  void _onSearchMenu(SearchMenu event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      
      final filtered = _filterProducts(
        currentState.allProducts,
        currentState.selectedCategoryId,
        event.query,
      );

      emit(currentState.copyWith(
        filteredProducts: filtered,
        searchQuery: event.query,
      ));
    }
  }

  List<Map<String, dynamic>> _filterProducts(
    List<Map<String, dynamic>> products,
    int? categoryId,
    String query,
  ) {
    var filtered = products;

    if (categoryId != null) {
      filtered = filtered.where((p) => p['category_id'] == categoryId).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((p) =>
          (p['name'] as String).toLowerCase().contains(query.toLowerCase())).toList();
    }

    return filtered;
  }
}
