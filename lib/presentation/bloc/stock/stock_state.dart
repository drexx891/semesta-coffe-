import 'package:equatable/equatable.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<Map<String, dynamic>> ingredients;
  final int criticalCount;

  const StockLoaded({
    required this.ingredients,
    required this.criticalCount,
  });

  @override
  List<Object?> get props => [ingredients, criticalCount];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}

class StockActionSuccess extends StockState {
  final String message;

  const StockActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
