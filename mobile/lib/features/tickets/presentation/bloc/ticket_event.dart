import 'package:equatable/equatable.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();
  @override
  List<Object?> get props => [];
}

class FetchTicketsEvent extends TicketEvent {
  final bool forceRefresh;
  const FetchTicketsEvent({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class CreateTicketEvent extends TicketEvent {
  final String title;
  final String description;
  final String category;
  final String urgency;
  final double lat;
  final double lon;
  final String locationName;
  final String customerName;
  final String customerPhone;
  final String? photo;

  const CreateTicketEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.customerName,
    required this.customerPhone,
    this.photo,
  });

  @override
  List<Object?> get props => [title, description, category, urgency, lat, lon];
}

class AssignTicketEvent extends TicketEvent {
  final String ticketId;
  final String technicianId;
  final String technicianName;

  const AssignTicketEvent({
    required this.ticketId,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  List<Object?> get props => [ticketId, technicianId, technicianName];
}

class UpdateTicketStatusEvent extends TicketEvent {
  final String ticketId;
  final String status;

  const UpdateTicketStatusEvent({
    required this.ticketId,
    required this.status,
  });

  @override
  List<Object?> get props => [ticketId, status];
}

class CompleteJobEvent extends TicketEvent {
  final String ticketId;
  final List<Map<String, dynamic>> parts;
  final String? beforeImage;
  final String? afterImage;
  final String? signature;

  const CompleteJobEvent({
    required this.ticketId,
    required this.parts,
    this.beforeImage,
    this.afterImage,
    this.signature,
  });

  @override
  List<Object?> get props => [ticketId, parts, beforeImage, afterImage, signature];
}
