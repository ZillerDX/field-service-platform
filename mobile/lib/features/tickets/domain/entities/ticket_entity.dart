import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String urgency;
  final String status;
  final String customerName;
  final String customerPhone;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? assignedToId;
  final String? assignedToName;
  final String? assignedToPhone;
  final List<Map<String, dynamic>> partsUsed;
  final String? beforeImage;
  final String? afterImage;
  final String? customerSignature;
  final DateTime createdAt;

  const TicketEntity({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.assignedToId,
    this.assignedToName,
    this.assignedToPhone,
    this.partsUsed = const [],
    this.beforeImage,
    this.afterImage,
    this.customerSignature,
    required this.createdAt,
  });

  factory TicketEntity.fromJson(Map<String, dynamic> json) {
    String assignedName;
    String? assignedId;
    String? assignedPhone;

    if (json['assignedTo'] is Map) {
      final a = json['assignedTo'] as Map<String, dynamic>;
      assignedId = a['_id']?.toString() ?? a['id']?.toString();
      assignedName = a['name']?.toString() ?? '';
      assignedPhone = a['phone']?.toString();
    } else {
      assignedName = json['assignedTo']?.toString() ?? '';
    }

    double lat = 13.7563;
    double lon = 100.5018;
    if (json['location'] != null && json['location']['coordinates'] is List) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        lon = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lon = (json['longitude'] as num).toDouble();
    }

    List<Map<String, dynamic>> parts = [];
    if (json['partsUsed'] is List) {
      parts = (json['partsUsed'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return TicketEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      ticketNumber: json['ticketNumber'] ?? 'TKT-PENDING',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      urgency: json['urgency'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      customerName: json['customerName'] ?? 'สมชาย สถิตย์วงศ์',
      customerPhone: json['customerPhone'] ?? '089-123-4567',
      locationName: json['locationName'] ?? 'จุดเกิดเหตุหลัก',
      latitude: lat,
      longitude: lon,
      assignedToId: assignedId,
      assignedToName: assignedName.isNotEmpty ? assignedName : null,
      assignedToPhone: assignedPhone,
      partsUsed: parts,
      beforeImage: json['beforeImage'],
      afterImage: json['afterImage'],
      customerSignature: json['customerSignature'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'title': title,
      'description': description,
      'category': category,
      'urgency': urgency,
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'assignedTo': assignedToName,
      'partsUsed': partsUsed,
      'beforeImage': beforeImage,
      'afterImage': afterImage,
      'customerSignature': customerSignature,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TicketEntity copyWith({
    String? status,
    String? assignedToId,
    String? assignedToName,
    List<Map<String, dynamic>>? partsUsed,
    String? beforeImage,
    String? afterImage,
    String? customerSignature,
  }) {
    return TicketEntity(
      id: id,
      ticketNumber: ticketNumber,
      title: title,
      description: description,
      category: category,
      urgency: urgency,
      status: status ?? this.status,
      customerName: customerName,
      customerPhone: customerPhone,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToPhone: assignedToPhone,
      partsUsed: partsUsed ?? this.partsUsed,
      beforeImage: beforeImage ?? this.beforeImage,
      afterImage: afterImage ?? this.afterImage,
      customerSignature: customerSignature ?? this.customerSignature,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticketNumber,
        title,
        status,
        urgency,
        category,
        assignedToName,
        partsUsed,
        beforeImage,
        afterImage,
        customerSignature,
      ];
}
