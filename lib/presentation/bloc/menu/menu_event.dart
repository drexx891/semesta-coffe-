import 'package:equatable/equatable.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenu extends MenuEvent {}

class SelectCategory extends MenuEvent {
  final int? categoryId;
  const SelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SearchMenu extends MenuEvent {
  final String query;
  const SearchMenu(this.query);

  @override
  List<Object?> get props => [query];
}
