import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'dispatcher_screen.dart';
import 'paramedic_screen.dart';
import 'hospital_screen.dart';
import 'staff_home_screen.dart';

// عدّل هذين الرابطين بروابط صفحاتكم الفعلية على فيسبوك وواتساب
const kFacebookUrl = 'https://facebook.com/YOUR_PAGE';
const kWhatsappUrl = 'https://wa.me/249XXXXXXXXX';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;

      final role = AuthService.currentUser!.role;
      Widget destination;
      switch (role) {
        case 'admin':
          destination = const AdminDashboardScreen();
          break;
        case 'dispatcher':
          destination = const DispatcherScreen();
          break;
        case 'paramedic':
          destination = const ParamedicScreen();
          break;
        case 'hospital':
          destination = const HospitalScreen();
          break;
        case 'doctor':
        case 'nurse':
        case 'employee':
          destination = const StaffHomeScreen();
          break;
        default:
          destination = const LoginScreen();
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F3),
      body: Stack(
        children: [
          // خلفية زخرفية: موجة حمراء وخط أفق بأسفل الشاشة
          Positioned.fill(
            child: CustomPaint(painter: _SkylinePainter()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        _buildBadge(),
                        const SizedBox(height: 18),
                        const Text(
                          'نظام الإسعاف القومي',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 24, height: 1.5, color: Colors.red[300]),
                            const SizedBox(width: 8),
                            const Text(
                              'ولاية البحر الأحمر',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 24, height: 1.5, color: Colors.red[300]),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              _buildField(
                                controller: _usernameCtrl,
                                label: 'اسم المستخدم',
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _passwordCtrl,
                                label: 'كلمة المرور',
                                icon: Icons.lock,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                onSubmit: (_) => _login(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade700, Colors.red.shade400],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: _loading ? null : _login,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('تسجيل الدخول',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('تواصل معنا', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                              icon: FaIcon(FontAwesomeIcons.facebook, color: const Color(0xFF1877F2), size: 22),
                              color: const Color(0xFF1877F2),
                              onTap: () => _openLink(kFacebookUrl),
                            ),
                            const SizedBox(width: 16),
                            _socialButton(
                              icon: FaIcon(FontAwesomeIcons.whatsapp, color: const Color(0xFF25D366), size: 22),
                              color: const Color(0xFF25D366),
                              onTap: () => _openLink(kWhatsappUrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.airport_shuttle, size: 62, color: Colors.red),
            Positioned(
              top: 14,
              child: Icon(Icons.add, size: 16, color: Colors.red.shade300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onFieldSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade300),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }

  Widget _socialButton({required Widget icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

/// يرسم موجة حمراء متدرّجة وخط أفق بسيط (مآذن/مباني) بأسفل الشاشة
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final waveHeight = size.height * 0.16;
    final baseY = size.height;

    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red.shade100, Colors.red.shade50],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, baseY - waveHeight, size.width, waveHeight));

    final wavePath = Path()
      ..moveTo(0, baseY - waveHeight * 0.4)
      ..quadraticBezierTo(size.width * 0.25, baseY - waveHeight, size.width * 0.5, baseY - waveHeight * 0.5)
      ..quadraticBezierTo(size.width * 0.75, baseY, size.width, baseY - waveHeight * 0.3)
      ..lineTo(size.width, baseY)
      ..lineTo(0, baseY)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // خط أفق بسيط (مباني ومئذنة) بأسفل الموجة
    final skylinePaint = Paint()..color = Colors.red.withOpacity(0.12);
    final skylineY = baseY - waveHeight * 0.22;
    double x = 0;
    final rnd = [0.5, 0.8, 0.4, 1.0, 0.6, 0.9, 0.45, 0.7, 0.55, 0.85];
    final buildingWidth = size.width / rnd.length;
    for (int i = 0; i < rnd.length; i++) {
      final h = waveHeight * 0.55 * rnd[i];
      canvas.drawRect(
        Rect.fromLTWH(x, skylineY - h, buildingWidth * 0.8, h),
        skylinePaint,
      );
      x += buildingWidth;
    }
    // مئذنة بسيطة بالمنتصف
    final minaretX = size.width * 0.5;
    canvas.drawRect(
      Rect.fromLTWH(minaretX - 3, skylineY - waveHeight * 0.9, 6, waveHeight * 0.9),
      skylinePaint,
    );
    canvas.drawCircle(Offset(minaretX, skylineY - waveHeight * 0.9), 8, skylinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
