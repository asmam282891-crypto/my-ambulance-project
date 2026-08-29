import 'package:latlong2/latlong.dart';

class TransferRequest {
  final String id;
  final String patientName;
  final String dobOrAge;
  final String sex;
  final String clinicalCondition;
  final List<String> criticalCareNeed;
  final String fromHospital;
  final String fromFocalPoint;
  final String fromPhone;
  final String toHospital;
  final String toFocalPoint;
  final String toPhone;
  final String referralAppropriate;
  final String inappropriateReason;
  final List<String> inappropriateCategory;
  final String criticalBedCommunicated;
  final String bedAvailabilityConfirmed;
  final String timeReferralRequest;
  final String timeCommunicationReceiving;
  final String timeDeparture;
  final String timeCommunicationAmbulance;
  final String timeFeedbackAmbulance;
  final String timeArrival;
  final String hr;
  final String rr;
  final String bp;
  final String temp;
  final String gcs;
  final String spo2;
  final String specialNotes;
  final String ambulanceType;
  final String journeyTracked;
  final String issuesDuringTransit;
  final String issuesDescription;
  final String equipment;
  final String conditionOnArrival;
  final String referralAccepted;
  final String notAcceptedReason;
  final String feedbackCommunicatedBack;
  final String completedByName;
  final String completedBySignature;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String status;
  final DateTime createdAt;

  TransferRequest({
    required this.id,
    required this.patientName,
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

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? json['patientName'] ?? '',
      dobOrAge: json['dob_or_age'] ?? json['dobOrAge'] ?? '',
      sex: json['sex'] ?? '',
      clinicalCondition: json['clinical_condition'] ?? json['clinicalCondition'] ?? '',
      criticalCareNeed: _splitList(json['critical_care_need'] ?? json['criticalCareNeed']),
      fromHospital: json['from_hospital'] ?? json['fromHospital'] ?? '',
      fromFocalPoint: json['from_focal_point'] ?? json['fromFocalPoint'] ?? '',
      fromPhone: json['from_phone'] ?? json['fromPhone'] ?? '',
      toHospital: json['to_hospital'] ?? json['toHospital'] ?? '',
      toFocalPoint: json['to_focal_point'] ?? json['toFocalPoint'] ?? '',
      toPhone: json['to_phone'] ?? json['toPhone'] ?? '',
      referralAppropriate: json['referral_appropriate'] ?? json['referralAppropriate'] ?? '',
      inappropriateReason: json['inappropriate_reason'] ?? json['inappropriateReason'] ?? '',
      inappropriateCategory: _splitList(json['inappropriate_category'] ?? json['inappropriateCategory']),
      criticalBedCommunicated: json['critical_bed_communicated'] ?? json['criticalBedCommunicated'] ?? '',
      bedAvailabilityConfirmed: json['bed_availability_confirmed'] ?? json['bedAvailabilityConfirmed'] ?? '',
      timeReferralRequest: json['time_referral_request'] ?? json['timeReferralRequest'] ?? '',
      timeCommunicationReceiving: json['time_communication_receiving'] ?? json['timeCommunicationReceiving'] ?? '',
      timeDeparture: json['time_departure'] ?? json['timeDeparture'] ?? '',
      timeCommunicationAmbulance: json['time_communication_ambulance'] ?? json['timeCommunicationAmbulance'] ?? '',
      timeFeedbackAmbulance: json['time_feedback_ambulance'] ?? json['timeFeedbackAmbulance'] ?? '',
      timeArrival: json['time_arrival'] ?? json['timeArrival'] ?? '',
      hr: json['hr'] ?? '',
      rr: json['rr'] ?? '',
      bp: json['bp'] ?? '',
      temp: json['temp'] ?? '',
      gcs: json['gcs'] ?? '',
      spo2: json['spo2'] ?? '',
      specialNotes: json['special_notes'] ?? json['specialNotes'] ?? '',
      ambulanceType: json['ambulance_type'] ?? json['ambulanceType'] ?? '',
      journeyTracked: json['journey_tracked'] ?? json['journeyTracked'] ?? '',
      issuesDuringTransit: json['issues_during_transit'] ?? json['issuesDuringTransit'] ?? '',
      issuesDescription: json['issues_description'] ?? json['issuesDescription'] ?? '',
      equipment: json['equipment'] ?? '',
      conditionOnArrival: json['condition_on_arrival'] ?? json['conditionOnArrival'] ?? '',
      referralAccepted: json['referral_accepted'] ?? json['referralAccepted'] ?? '',
      notAcceptedReason: json['not_accepted_reason'] ?? json['notAcceptedReason'] ?? '',
      feedbackCommunicatedBack: json['feedback_communicated_back'] ?? json['feedbackCommunicatedBack'] ?? '',
      completedByName: json['completed_by_name'] ?? json['completedByName'] ?? '',
      completedBySignature: json['completed_by_signature'] ?? json['completedBySignature'] ?? '',
      fromLat: (json['from_lat'] ?? json['fromLat'] ?? 0.0).toDouble(),
      fromLng: (json['from_lng'] ?? json['fromLng'] ?? 0.0).toDouble(),
      toLat: (json['to_lat'] ?? json['toLat'] ?? 0.0).toDouble(),
      toLng: (json['to_lng'] ?? json['toLng'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_name': patientName,
      'dob_or_age': dobOrAge,
      'sex': sex,
      'clinical_condition': clinicalCondition,
      'critical_care_need': criticalCareNeed,
      'from_hospital': fromHospital,
      'from_focal_point': fromFocalPoint,
      'from_phone': fromPhone,
      'to_hospital': toHospital,
      'to_focal_point': toFocalPoint,
      'to_phone': toPhone,
      'referral_appropriate': referralAppropriate,
      'inappropriate_reason': inappropriateReason,
      'inappropriate_category': inappropriateCategory,
      'critical_bed_communicated': criticalBedCommunicated,
      'bed_availability_confirmed': bedAvailabilityConfirmed,
      'time_referral_request': timeReferralRequest,
      'time_communication_receiving': timeCommunicationReceiving,
      'time_departure': timeDeparture,
      'time_communication_ambulance': timeCommunicationAmbulance,
      'time_feedback_ambulance': timeFeedbackAmbulance,
      'time_arrival': timeArrival,
      'hr': hr,
      'rr': rr,
      'bp': bp,
      'temp': temp,
      'gcs': gcs,
      'spo2': spo2,
      'special_notes': specialNotes,
      'ambulance_type': ambulanceType,
      'journey_tracked': journeyTracked,
      'issues_during_transit': issuesDuringTransit,
      'issues_description': issuesDescription,
      'equipment': equipment,
      'condition_on_arrival': conditionOnArrival,
      'referral_accepted': referralAccepted,
      'not_accepted_reason': notAcceptedReason,
      'feedback_communicated_back': feedbackCommunicatedBack,
      'completed_by_name': completedByName,
      'completed_by_signature': completedBySignature,
      'from_lat': fromLat,
      'from_lng': fromLng,
      'to_lat': toLat,
      'to_lng': toLng,
      'status': status,
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

  static List<String> _splitList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [v.toString()];
  }
}
