import 'package:equatable/equatable.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> filteredProducts;
  final Map<int, bool> stockAvailability;
  final int? selectedCategoryId;
  final String searchQuery;

  const MenuLoaded({
    required this.categories,
    required this.allProducts,
    required this.filteredProducts,
    required this.stockAvailability,
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  MenuLoaded copyWith({
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? allProducts,
    List<Map<String, dynamic>>? filteredProducts,
    Map<int, bool>? stockAvailability,
    int? selectedCategoryId,
    bool clearCategoryId = false,
    String? searchQuery,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      stockAvailability: stockAvailability ?? this.stockAvailability,
      selectedCategoryId: clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        allProducts,
        filteredProducts,
        stockAvailability,
        selectedCategoryId,
        searchQuery,
      ];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}
