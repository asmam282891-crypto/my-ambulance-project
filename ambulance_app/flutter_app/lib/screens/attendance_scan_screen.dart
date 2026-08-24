import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;

  Future<void> _handleCode(String value) async {
    if (_busy) return;
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final message = await AttendanceService.recordAttendance(user.id, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      if (message.contains('بنجاح')) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح باركود الحضور'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'تشغيل أو إيقاف الفلاش',
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'المستخدم: ${user?.fullName ?? ''}\nوجّه الكاميرا إلى باركود الإسعاف المركزي لتسجيل الحضور أو الانصراف',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.isNotEmpty
                        ? capture.barcodes.first
                        : null;
                    final value = barcode?.rawValue;
                    if (value != null && value.isNotEmpty) {
                      _handleCode(value);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (_busy)
                  const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
