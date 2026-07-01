class UserProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
    };
  }
}
