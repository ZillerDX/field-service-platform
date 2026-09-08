import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket_entity.dart';

abstract class TicketState extends Equatable {
  const TicketState();
  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketLoaded extends TicketState {
  final List<TicketEntity> tickets;
  final bool isOffline;

  const TicketLoaded({required this.tickets, this.isOffline = false});

  @override
  List<Object?> get props => [tickets, isOffline];
}

class TicketActionSuccess extends TicketState {
  final String message;
  const TicketActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TicketOperationFailure extends TicketState {
  final String error;
  const TicketOperationFailure(this.error);
  @override
  List<Object?> get props => [error];
}
