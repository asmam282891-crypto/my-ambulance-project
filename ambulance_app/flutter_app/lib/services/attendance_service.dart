import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AttendanceService {
  static const String sharedQrValue = 'CENTRAL_AMBULANCE_ATTENDANCE';
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> recordAttendance(String userId, String qrData) async {
    if (qrData.trim() != sharedQrValue) {
      throw Exception('هذا الباركود غير مصرح به للحضور والانصراف');
    }

    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final existing = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .eq('attendance_date', today)
        .maybeSingle();

    if (existing == null) {
      await _client.from('attendance').insert({
        'user_id': userId,
        'attendance_date': today,
        'check_in': now.toIso8601String(),
      });
      return 'تم تسجيل الحضور بنجاح';
    }

    if (existing['check_out'] == null) {
      await _client
          .from('attendance')
          .update({'check_out': now.toIso8601String()})
          .eq('id', existing['id']);
      return 'تم تسجيل الانصراف بنجاح';
    }

    return 'تم تسجيل الحضور والانصراف لهذا اليوم بالفعل';
  }
}
