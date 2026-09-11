class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String role; // ambulance app roles
  final String? ambulanceId;
  final String? hospitalName;

  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.ambulanceId,
    this.hospitalName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      role: json['role'] ?? '',
      ambulanceId: (json['ambulanceId'] ?? json['ambulance_id'])?.toString(),
      hospitalName: (json['hospitalName'] ?? json['hospital_name'])?.toString(),
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'dispatcher':
        return 'موظف بلاغات';
      case 'paramedic':
        return 'مسعف';
      case 'hospital':
        return 'مستشفى';
      case 'doctor':
        return 'طبيب';
      case 'nurse':
        return 'ممرض';
      case 'driver':
        return 'سائق';
      default:
        return role;
    }
  }
}
