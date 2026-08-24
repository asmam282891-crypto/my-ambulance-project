class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      date: DateTime.parse(json['attendance_date'].toString()),
      checkIn: json['check_in'] == null ? null : DateTime.parse(json['check_in'].toString()),
      checkOut: json['check_out'] == null ? null : DateTime.parse(json['check_out'].toString()),
    );
  }
}
