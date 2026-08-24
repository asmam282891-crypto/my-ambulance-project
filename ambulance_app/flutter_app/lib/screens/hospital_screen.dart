import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transfer_request.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'attendance_scan_screen.dart';
import 'login_screen.dart';
import 'hospital_transfer_screen.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransferRequest> _incoming = [];
  List<TransferRequest> _sent = [];
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final all = await ApiService.getTransfers();
      final myHospital = AuthService.currentUser?.hospitalName;
      final incoming = all.where((t) => t.toHospital == myHospital).toList();
      final sent = all.where((t) => t.fromHospital == myHospital).toList();
      if (mounted) {
        setState(() {
          _incoming = incoming;
          _sent = sent;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر الاتصال بالسيرفر');
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  Future<void> _markReady(TransferRequest t) async {
    try {
      await ApiService.updateTransferStatus(t.id, 'accepted');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _openNewRequestForm() async {
    final myHospital = AuthService.currentUser?.hospitalName;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalTransferScreen(lockedFromHospital: myHospital),
      ),
    );
    _refresh();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'enroute': return Colors.purple;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(user?.hospitalName ?? 'المستشفى'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'الحالات الواردة'),
            Tab(text: 'طلباتي المرسلة'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'الحضور والانصراف',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScanScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'تسجيل الخروج'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequestForm,
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إرسال طلب تحويل'),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_incoming, isIncoming: true, emptyText: 'لا توجد حالات محوّلة لكم حاليًا'),
                _buildList(_sent, isIncoming: false, emptyText: 'ما أرسلتوا أي طلب تحويل بعد'),
              ],
            ),
    );
  }

  Widget _buildList(List<TransferRequest> list, {required bool isIncoming, required String emptyText}) {
    if (list.isEmpty) return Center(child: Text(emptyText));
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.patientName.isEmpty ? 'تحويل #${t.id}' : t.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Chip(
                        label: Text(t.statusLabel, style: const TextStyle(fontSize: 11)),
                        backgroundColor: _statusColor(t.status).withOpacity(0.15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(isIncoming ? 'من: ${t.fromHospital} (${t.fromPhone})' : 'إلى: ${t.toHospital}'),
                  if (t.clinicalCondition.isNotEmpty) Text('الحالة السريرية: ${t.clinicalCondition}'),
                  if (t.criticalCareNeed.isNotEmpty)
                    Text('الرعاية المطلوبة: ${t.criticalCareNeed.join("، ")}'),
                  if (t.equipment.isNotEmpty) Text('التجهيزات المطلوبة: ${t.equipment}'),
                  const SizedBox(height: 10),
                  if (isIncoming && t.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _markReady(t),
                        child: const Text('تأكيد الاستعداد لاستقبال المريض'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
