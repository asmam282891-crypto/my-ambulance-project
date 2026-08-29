class AmbulanceRequest {
  final String id;
  final String callerName;
  final String patientName;
  final String phone;
  final String caseType;
  final String severity; // low, medium, high, critical
  final String details;
  final double lat;
  final double lng;
  String status; // pending, accepted, enroute_to_scene, arrived_at_scene, transporting, completed
  String? assignedAmbulanceId;
  final DateTime createdAt;

  AmbulanceRequest({
    required this.id,
    this.callerName = '',
    required this.patientName,
    required this.phone,
    this.caseType = '',
    this.severity = '',
    required this.details,
    required this.lat,
    required this.lng,
    this.status = 'pending',
    this.assignedAmbulanceId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AmbulanceRequest.fromJson(Map<String, dynamic> json) {
    return AmbulanceRequest(
      id: json['id'].toString(),
      callerName: json['caller_name'] ?? json['callerName'] ?? '',
      patientName: json['patient_name'] ?? json['patientName'] ?? '',
      phone: json['phone'] ?? '',
      caseType: json['case_type'] ?? json['caseType'] ?? '',
      severity: json['severity'] ?? '',
      details: json['details'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      assignedAmbulanceId: (json['assigned_ambulance_id'] ?? json['assignedAmbulanceId'])?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caller_name': callerName,
      'patient_name': patientName,
      'phone': phone,
      'case_type': caseType,
      'severity': severity,
      'details': details,
      'lat': lat,
      'lng': lng,
      'status': status,
      if (assignedAmbulanceId != null) 'assigned_ambulance_id': assignedAmbulanceId,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
      case 'accepted':
        return 'تم القبول';
      case 'enroute_to_scene':
        return 'بالطريق للموقع';
      case 'arrived_at_scene':
        return 'وصل للموقع';
      case 'transporting':
        return 'ينقل المريض';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'low':
        return 'منخفضة';
      case 'medium':
        return 'متوسطة';
      case 'high':
        return 'عالية';
      case 'critical':
        return 'حرجة';
      default:
        return severity;
    }
  }
}
