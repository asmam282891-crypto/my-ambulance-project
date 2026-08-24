import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'supabase_config.dart';

/// يدير تسجيل الدخول عبر Supabase Auth، ويحمّل بيانات الدور (role)
/// من جدول profiles بعد نجاح الدخول.
class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static AppUser? _currentUser;
  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _client.auth.currentSession != null;

  static Future<void> login(String username, String password) async {
    final email = '$username${SupabaseConfig.emailSuffix}';
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      final uid = res.user?.id;
      if (uid == null) throw Exception('تسجيل الدخول رجع بدون معرّف مستخدم (uid فاضي) — حالة غير متوقعة');

      try {
        final profile = await _client.from('profiles').select().eq('id', uid).single();
        _currentUser = AppUser.fromJson(profile);
      } catch (e) {
        throw Exception('تسجيل الدخول بـ Supabase نجح، لكن ما لقينا صف بجدول profiles لهذا المستخدم (UID: $uid). '
            'تأكد إنك أضفت صف بـ profiles بنفس الـ id. التفاصيل التقنية: $e');
      }
    } on AuthException catch (e) {
      // مؤقتًا: نطلع الرسالة الحقيقية من Supabase بدل رسالة عامة، عشان نشخّص السبب الفعلي
      throw Exception('خطأ من Supabase: ${e.message} (كود: ${e.statusCode ?? "-"})');
    }
  }

  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // نتجاهل أي خطأ شبكة أثناء تسجيل الخروج
    }
    _currentUser = null;
  }

  /// يستخدم داخليًا لو انتهت الجلسة فجأة
  static void forceLogout() {
    _currentUser = null;
  }

  /// لو التطبيق أعيد فتحه وفيه جلسة محفوظة، نحاول نسترجع بيانات المستخدم
  static Future<void> restoreSessionIfNeeded() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || _currentUser != null) return;
    try {
      final profile = await _client.from('profiles').select().eq('id', uid).single();
      _currentUser = AppUser.fromJson(profile);
    } catch (_) {
      // الجلسة غير صالحة أو الملف الشخصي غير موجود
    }
  }
}
