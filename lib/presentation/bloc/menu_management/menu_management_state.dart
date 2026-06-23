import 'package:equatable/equatable.dart';

abstract class MenuManagementState extends Equatable {
  const MenuManagementState();

  @override
  List<Object?> get props => [];
}

class MenuManagementInitial extends MenuManagementState {}

class MenuManagementLoading extends MenuManagementState {}

class MenuManagementLoaded extends MenuManagementState {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;

  const MenuManagementLoaded({
    required this.categories,
    required this.products,
  });

  @override
  List<Object?> get props => [categories, products];
}

class MenuManagementError extends MenuManagementState {
  final String message;

  const MenuManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class MenuManagementActionSuccess extends MenuManagementState {
  final String message;

  const MenuManagementActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
