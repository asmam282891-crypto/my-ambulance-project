import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ambulance_request.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'attendance_scan_screen.dart';
import 'login_screen.dart';

class ParamedicScreen extends StatefulWidget {
  const ParamedicScreen({super.key});

  @override
  State<ParamedicScreen> createState() => _ParamedicScreenState();
}

class _ParamedicScreenState extends State<ParamedicScreen> {
  List<AmbulanceRequest> _myTasks = [];
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final all = await ApiService.getRequests();
      final myAmbulanceId = AuthService.currentUser?.ambulanceId;
      final mine = all
          .where((r) => r.assignedAmbulanceId == myAmbulanceId && r.status != 'completed')
          .toList();
      if (mounted) setState(() { _myTasks = mine; _error = null; });
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

  Future<void> _advance(AmbulanceRequest task) async {
    const nextStatus = {
      'pending': 'accepted',
      'accepted': 'enroute_to_scene',
      'enroute_to_scene': 'arrived_at_scene',
      'arrived_at_scene': 'transporting',
      'transporting': 'completed',
    };
    final next = nextStatus[task.status];
    if (next == null) return;
    try {
      await ApiService.updateRequestStatus(task.id, next);
      final myAmbulanceId = AuthService.currentUser?.ambulanceId;
      if (myAmbulanceId != null) {
        await ApiService.updateAmbulanceStatus(
            myAmbulanceId, next == 'completed' ? 'available' : 'busy');
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  String _buttonLabel(String status) {
    switch (status) {
      case 'pending': return 'قبول المهمة';
      case 'accepted': return 'بالطريق للموقع';
      case 'enroute_to_scene': return 'وصلت للموقع';
      case 'arrived_at_scene': return 'نقل المريض';
      case 'transporting': return 'إنهاء المهمة';
      default: return '';
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('مسعف - ${user?.fullName ?? ""}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'الحضور والانصراف',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScanScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _myTasks.isEmpty
              ? const Center(child: Text('لا توجد مهام مخصصة لك حاليًا'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _myTasks.length,
                    itemBuilder: (context, i) {
                      final t = _myTasks[i];
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
                                      t.patientName.isEmpty ? 'بلاغ #${t.id}' : t.patientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  if (t.severity.isNotEmpty)
                                    Chip(
                                      label: Text(t.severityLabel, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      backgroundColor: _severityColor(t.severity),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (t.caseType.isNotEmpty) Text('نوع الحالة: ${t.caseType}'),
                              Text('الهاتف: ${t.phone}'),
                              if (t.details.isNotEmpty) Text('تفاصيل: ${t.details}'),
                              Text('الحالة: ${t.statusLabel}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 160,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(t.lat, t.lng),
                                      initialZoom: 14,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.ambulance_app',
                                      ),
                                      MarkerLayer(markers: [
                                        Marker(
                                          point: LatLng(t.lat, t.lng),
                                          width: 36, height: 36,
                                          child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _advance(t),
                                  child: Text(_buttonLabel(t.status)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
