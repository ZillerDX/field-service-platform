import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String name;
  final String role; // 'admin', 'technician', 'customer'
  final String? email;
  final String? phone;

  const UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.email,
    this.phone,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'customer',
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [id, username, name, role, email, phone];
}
