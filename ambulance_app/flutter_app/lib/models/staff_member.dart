class StaffMember {
  final String id;
  final String fullName;
  final String jobTitle;
  final bool active;

  StaffMember({
    required this.id,
    required this.fullName,
    required this.jobTitle,
    this.active = true,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'].toString(),
      fullName: json['fullName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      active: json['active'] ?? true,
    );
  }
}

/// قائمة مسميات وظيفية شائعة تُعرض بالنموذج مع خيار "أخرى" للكتابة الحرة
const kJobTitleOptions = [
  'طبيب',
  'ممرض/ممرضة',
  'مسعف',
  'سكرتارية',
  'محاسب / متحصل مالي',
  'تقنية معلومات',
  'مهندس معدات طبية',
  'صيدلاني/صيدلانية',
  'أخرى',
];
