import 'package:equatable/equatable.dart';

abstract class MenuManagementEvent extends Equatable {
  const MenuManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuManagement extends MenuManagementEvent {}

class CreateCategory extends MenuManagementEvent {
  final String name;
  final int sortOrder;

  const CreateCategory({required this.name, required this.sortOrder});

  @override
  List<Object?> get props => [name, sortOrder];
}

class UpdateCategory extends MenuManagementEvent {
  final int id;
  final String name;
  final int sortOrder;

  const UpdateCategory({required this.id, required this.name, required this.sortOrder});

  @override
  List<Object?> get props => [id, name, sortOrder];
}

class CreateProduct extends MenuManagementEvent {
  final Map<String, dynamic> productData;

  const CreateProduct(this.productData);

  @override
  List<Object?> get props => [productData];
}

class UpdateProduct extends MenuManagementEvent {
  final int id;
  final Map<String, dynamic> productData;

  const UpdateProduct(this.id, this.productData);

  @override
  List<Object?> get props => [id, productData];
}

class ToggleProductActive extends MenuManagementEvent {
  final int id;
  final bool isActive;

  const ToggleProductActive(this.id, this.isActive);

  @override
  List<Object?> get props => [id, isActive];
}

class DeleteProduct extends MenuManagementEvent {
  final int id;

  const DeleteProduct(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteCategory extends MenuManagementEvent {
  final int id;

  const DeleteCategory(this.id);

  @override
  List<Object?> get props => [id];
}
