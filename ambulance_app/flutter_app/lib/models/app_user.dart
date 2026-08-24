class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String role; // admin, dispatcher, paramedic, hospital
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
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      ambulanceId: json['ambulanceId']?.toString(),
      hospitalName: json['hospitalName']?.toString(),
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
        return 'ممرض / ممرضة';
      case 'employee':
        return 'موظف';
      default:
        return role;
    }
  }
}
