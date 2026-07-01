class TimeSlot {
  final String id;
  final String fieldId;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final DateTime createdAt;

  TimeSlot({
    required this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.createdAt,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      fieldId: json['field_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isAvailable: json['is_available'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_id': fieldId,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }
}
