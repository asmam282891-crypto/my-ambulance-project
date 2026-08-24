import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ambulance_request.dart';
import '../models/transfer_request.dart';
import '../models/ambulance.dart';
import '../models/app_user.dart';
import '../models/staff_member.dart';
import '../models/attendance_record.dart';
import 'auth_service.dart';

/// كل عمليات القراءة والكتابة تصير مباشرة مع Supabase
/// (بدون الحاجة لسيرفر Dart منفصل - Supabase هو السحابة الجاهزة).
class ApiService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ---------------- Ambulance Requests (بلاغات المرضى) ----------------

  static Future<List<AmbulanceRequest>> getRequests() async {
    final data = await _client.from('requests').select().order('id', ascending: false);
    return (data as List).map((e) => AmbulanceRequest.fromJson(e)).toList();
  }

  static Future<AmbulanceRequest> createRequest(AmbulanceRequest req) async {
    final payload = req.toJson();
    payload['createdByUserId'] = AuthService.currentUser?.id;
    final data = await _client.from('requests').insert(payload).select().single();
    return AmbulanceRequest.fromJson(data);
  }

  static Future<void> updateRequestStatus(
      String id, String status, {String? ambulanceId}) async {
    final updates = <String, dynamic>{'status': status};
    if (ambulanceId != null) updates['assignedAmbulanceId'] = ambulanceId;
    await _client.from('requests').update(updates).eq('id', int.parse(id));
  }

  // ---------------- Transfer Requests (تحويلات المستشفيات) ----------------

  static Future<List<TransferRequest>> getTransfers() async {
    final data = await _client.from('transfers').select().order('id', ascending: false);
    return (data as List).map((e) => TransferRequest.fromJson(e)).toList();
  }

  static Future<TransferRequest> createTransfer(TransferRequest t) async {
    final data = await _client.from('transfers').insert(t.toJson()).select().single();
    return TransferRequest.fromJson(data);
  }

  static Future<void> updateTransferStatus(String id, String status, {String? ambulanceId}) async {
    final updates = <String, dynamic>{'status': status};
    if (ambulanceId != null) updates['assignedAmbulanceId'] = ambulanceId;
    await _client.from('transfers').update(updates).eq('id', int.parse(id));
  }

  // ---------------- Ambulances (أسطول الإسعاف) ----------------

  static Future<List<Ambulance>> getAmbulances() async {
    final data = await _client.from('ambulances').select();
    return (data as List).map((e) => Ambulance.fromJson(e)).toList();
  }

  static Future<void> createAmbulance(String plateNumber, String driverName) async {
    await _client.from('ambulances').insert({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'plateNumber': plateNumber,
      'driverName': driverName,
      'status': 'available',
      'lat': 19.6158,
      'lng': 37.2164,
    });
  }

  static Future<void> updateAmbulanceStatus(String id, String status) async {
    await _client.from('ambulances').update({'status': status}).eq('id', id);
  }

  static Future<void> deleteAmbulance(String id) async {
    await _client.from('ambulances').delete().eq('id', id);
  }

  // ---------------- Users (المستخدمون) ----------------

  static Future<List<AppUser>> getUsers() async {
    final data = await _client.from('profiles').select().order('created_at');
    return (data as List).map((e) => AppUser.fromJson(e)).toList();
  }

  /// ينشئ حساب دخول + صف profiles عن طريق دالة Supabase الآمنة الموجودة في create_users_function.sql
  static Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? ambulanceId,
    String? hospitalName,
  }) async {
    await _client.rpc('create_staff_user', params: {
      'p_username': username,
      'p_password': password,
      'p_full_name': fullName,
      'p_role': role,
      'p_ambulance_id': ambulanceId,
      'p_hospital_name': hospitalName,
    });
  }

  // ---------------- Attendance (الحضور والانصراف) ----------------

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final data = await _client
        .from('attendance')
        .select()
        .eq('attendance_date', _dateOnly(date))
        .order('check_in');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

}
