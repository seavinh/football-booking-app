class Booking {
  final String id;
  final String userId;
  final String fieldId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime createdAt;
  final String? fieldName;
  final String? fieldAddress;

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.fieldName,
    this.fieldAddress,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      fieldId: json['field_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      fieldName: json['football_fields']?['name'],
      fieldAddress: json['football_fields']?['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'field_id': fieldId,
      'booking_date': bookingDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
    };
  }
}
