import 'package:equatable/equatable.dart';
import '../../../../domain/entities/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final String searchQuery;

  const CustomerLoaded({
    required this.customers,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [customers, searchQuery];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerActionSuccess extends CustomerState {
  final String message;

  const CustomerActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
