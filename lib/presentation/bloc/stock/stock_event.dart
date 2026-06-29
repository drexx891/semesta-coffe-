import 'package:equatable/equatable.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class LoadStock extends StockEvent {}

class AddIngredient extends StockEvent {
  final Map<String, dynamic> ingredientData;

  const AddIngredient(this.ingredientData);

  @override
  List<Object?> get props => [ingredientData];
}

class UpdateIngredient extends StockEvent {
  final int id;
  final Map<String, dynamic> ingredientData;

  const UpdateIngredient(this.id, this.ingredientData);

  @override
  List<Object?> get props => [id, ingredientData];
}

class DeleteIngredient extends StockEvent {
  final int id;

  const DeleteIngredient(this.id);

  @override
  List<Object?> get props => [id];
}

class AddStock extends StockEvent {
  final int ingredientId;
  final double quantity;
  final int userId;
  final String? invoiceNumber;

  const AddStock({
    required this.ingredientId,
    required this.quantity,
    required this.userId,
    this.invoiceNumber,
  });

  @override
  List<Object?> get props => [ingredientId, quantity, userId, invoiceNumber];
}

class CorrectStock extends StockEvent {
  final int ingredientId;
  final double newQuantity;
  final String reason;
  final int userId;

  const CorrectStock({
    required this.ingredientId,
    required this.newQuantity,
    required this.reason,
    required this.userId,
  });

  @override
  List<Object?> get props => [ingredientId, newQuantity, reason, userId];
}
