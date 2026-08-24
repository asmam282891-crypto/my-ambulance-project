class Ambulance {
  final String id;
  final String plateNumber;
  final String driverName;
  String status; // available, busy, enroute, offline
  double lat;
  double lng;

  Ambulance({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    this.status = 'available',
    required this.lat,
    required this.lng,
  });

  factory Ambulance.fromJson(Map<String, dynamic> json) {
    return Ambulance(
      id: json['id'].toString(),
      plateNumber: json['plateNumber'] ?? '',
      driverName: json['driverName'] ?? '',
      status: json['status'] ?? 'available',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'available':
        return 'متاحة';
      case 'busy':
        return 'مشغولة';
      case 'enroute':
        return 'في الطريق';
      case 'offline':
        return 'خارج الخدمة';
      default:
        return status;
    }
  }
}
