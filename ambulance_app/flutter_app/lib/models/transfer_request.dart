class TransferRequest {
  final String id;

  // بيانات المريض
  final String patientName;
  final String dobOrAge;
  final String sex; // Male / Female
  final String clinicalCondition;
  final List<String> criticalCareNeed; // ICU, CCU, HDU, PICU, NICU, Maternity ICU, Maternity HDU

  // المنشأة المحوِّلة (من)
  final String fromHospital;
  final String fromFocalPoint;
  final String fromPhone;

  // المنشأة المستقبلة (إلى)
  final String toHospital;
  final String toFocalPoint;
  final String toPhone;

  // ملاءمة التحويل
  final String referralAppropriate; // Yes / No
  final String inappropriateReason;
  final List<String> inappropriateCategory;

  // التواصل بخصوص السرير
  final String criticalBedCommunicated; // Yes / No
  final String bedAvailabilityConfirmed; // Yes / No

  // الأوقات
  final String timeReferralRequest;
  final String timeCommunicationReceiving;
  final String timeDeparture;
  final String timeCommunicationAmbulance;
  final String timeFeedbackAmbulance;
  final String timeArrival;

  // العلامات الحيوية الحالية
  final String hr;
  final String rr;
  final String bp;
  final String temp;
  final String gcs;
  final String spo2;
  final String specialNotes;

  // تفاصيل النقل بالإسعاف
  final String ambulanceType; // BLS / ALS / ICU / Other
  final String journeyTracked; // Yes / No
  final String issuesDuringTransit; // Yes / No
  final String issuesDescription;
  final String equipment;

  // حالة الوصول والنتيجة
  final String conditionOnArrival; // Unchanged / Improved / Other
  final String referralAccepted; // Yes / No
  final String notAcceptedReason;
  final String feedbackCommunicatedBack; // Yes / No

  // تم التعبئة بواسطة
  final String completedByName;
  final String completedBySignature;

  // إحداثيات
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;

  String status; // pending, accepted, enroute, completed
  final DateTime createdAt;

  TransferRequest({
    required this.id,
    this.patientName = '',
    this.dobOrAge = '',
    this.sex = '',
    this.clinicalCondition = '',
    this.criticalCareNeed = const [],
    required this.fromHospital,
    this.fromFocalPoint = '',
    this.fromPhone = '',
    required this.toHospital,
    this.toFocalPoint = '',
    this.toPhone = '',
    this.referralAppropriate = '',
    this.inappropriateReason = '',
    this.inappropriateCategory = const [],
    this.criticalBedCommunicated = '',
    this.bedAvailabilityConfirmed = '',
    this.timeReferralRequest = '',
    this.timeCommunicationReceiving = '',
    this.timeDeparture = '',
    this.timeCommunicationAmbulance = '',
    this.timeFeedbackAmbulance = '',
    this.timeArrival = '',
    this.hr = '',
    this.rr = '',
    this.bp = '',
    this.temp = '',
    this.gcs = '',
    this.spo2 = '',
    this.specialNotes = '',
    this.ambulanceType = '',
    this.journeyTracked = '',
    this.issuesDuringTransit = '',
    this.issuesDescription = '',
    this.equipment = '',
    this.conditionOnArrival = '',
    this.referralAccepted = '',
    this.notAcceptedReason = '',
    this.feedbackCommunicatedBack = '',
    this.completedByName = '',
    this.completedBySignature = '',
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static List<String> _splitList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    final s = v.toString();
    if (s.isEmpty) return [];
    return s.split('|');
  }

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      id: json['id'].toString(),
      patientName: json['patientName'] ?? '',
      dobOrAge: json['dobOrAge'] ?? '',
      sex: json['sex'] ?? '',
      clinicalCondition: json['clinicalCondition'] ?? '',
      criticalCareNeed: _splitList(json['criticalCareNeed']),
      fromHospital: json['fromHospital'] ?? '',
      fromFocalPoint: json['fromFocalPoint'] ?? '',
      fromPhone: json['fromPhone'] ?? '',
      toHospital: json['toHospital'] ?? '',
      toFocalPoint: json['toFocalPoint'] ?? '',
      toPhone: json['toPhone'] ?? '',
      referralAppropriate: json['referralAppropriate'] ?? '',
      inappropriateReason: json['inappropriateReason'] ?? '',
      inappropriateCategory: _splitList(json['inappropriateCategory']),
      criticalBedCommunicated: json['criticalBedCommunicated'] ?? '',
      bedAvailabilityConfirmed: json['bedAvailabilityConfirmed'] ?? '',
      timeReferralRequest: json['timeReferralRequest'] ?? '',
      timeCommunicationReceiving: json['timeCommunicationReceiving'] ?? '',
      timeDeparture: json['timeDeparture'] ?? '',
      timeCommunicationAmbulance: json['timeCommunicationAmbulance'] ?? '',
      timeFeedbackAmbulance: json['timeFeedbackAmbulance'] ?? '',
      timeArrival: json['timeArrival'] ?? '',
      hr: json['hr'] ?? '',
      rr: json['rr'] ?? '',
      bp: json['bp'] ?? '',
      temp: json['temp'] ?? '',
      gcs: json['gcs'] ?? '',
      spo2: json['spo2'] ?? '',
      specialNotes: json['specialNotes'] ?? '',
      ambulanceType: json['ambulanceType'] ?? '',
      journeyTracked: json['journeyTracked'] ?? '',
      issuesDuringTransit: json['issuesDuringTransit'] ?? '',
      issuesDescription: json['issuesDescription'] ?? '',
      equipment: json['equipment'] ?? '',
      conditionOnArrival: json['conditionOnArrival'] ?? '',
      referralAccepted: json['referralAccepted'] ?? '',
      notAcceptedReason: json['notAcceptedReason'] ?? '',
      feedbackCommunicatedBack: json['feedbackCommunicatedBack'] ?? '',
      completedByName: json['completedByName'] ?? '',
      completedBySignature: json['completedBySignature'] ?? '',
      fromLat: (json['fromLat'] as num?)?.toDouble() ?? 19.6158,
      fromLng: (json['fromLng'] as num?)?.toDouble() ?? 37.2164,
      toLat: (json['toLat'] as num?)?.toDouble() ?? 19.6200,
      toLng: (json['toLng'] as num?)?.toDouble() ?? 37.2100,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientName': patientName,
      'dobOrAge': dobOrAge,
      'sex': sex,
      'clinicalCondition': clinicalCondition,
      'criticalCareNeed': criticalCareNeed.join('|'),
      'fromHospital': fromHospital,
      'fromFocalPoint': fromFocalPoint,
      'fromPhone': fromPhone,
      'toHospital': toHospital,
      'toFocalPoint': toFocalPoint,
      'toPhone': toPhone,
      'referralAppropriate': referralAppropriate,
      'inappropriateReason': inappropriateReason,
      'inappropriateCategory': inappropriateCategory.join('|'),
      'criticalBedCommunicated': criticalBedCommunicated,
      'bedAvailabilityConfirmed': bedAvailabilityConfirmed,
      'timeReferralRequest': timeReferralRequest,
      'timeCommunicationReceiving': timeCommunicationReceiving,
      'timeDeparture': timeDeparture,
      'timeCommunicationAmbulance': timeCommunicationAmbulance,
      'timeFeedbackAmbulance': timeFeedbackAmbulance,
      'timeArrival': timeArrival,
      'hr': hr,
      'rr': rr,
      'bp': bp,
      'temp': temp,
      'gcs': gcs,
      'spo2': spo2,
      'specialNotes': specialNotes,
      'ambulanceType': ambulanceType,
      'journeyTracked': journeyTracked,
      'issuesDuringTransit': issuesDuringTransit,
      'issuesDescription': issuesDescription,
      'equipment': equipment,
      'conditionOnArrival': conditionOnArrival,
      'referralAccepted': referralAccepted,
      'notAcceptedReason': notAcceptedReason,
      'feedbackCommunicatedBack': feedbackCommunicatedBack,
      'completedByName': completedByName,
      'completedBySignature': completedBySignature,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
      case 'accepted':
        return 'تم القبول';
      case 'enroute':
        return 'في الطريق';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }
}
