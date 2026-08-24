import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ambulance_request.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'attendance_scan_screen.dart';
import 'login_screen.dart';
import 'hospital_transfer_screen.dart';

const kSeverityOptions = {
  'low': 'منخفضة',
  'medium': 'متوسطة',
  'high': 'عالية',
  'critical': 'حرجة',
};

class DispatcherScreen extends StatefulWidget {
  const DispatcherScreen({super.key});

  @override
  State<DispatcherScreen> createState() => _DispatcherScreenState();
}

class _DispatcherScreenState extends State<DispatcherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('موظف بلاغات - ${user?.fullName ?? ""}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'بلاغ جديد'), Tab(text: 'البلاغات'), Tab(text: 'تحويل مستشفى')],
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
      body: TabBarView(
        controller: _tabController,
        children: const [_NewRequestForm(), _RequestsList(), _TransferTab()],
      ),
    );
  }
}

class _NewRequestForm extends StatefulWidget {
  const _NewRequestForm();

  @override
  State<_NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<_NewRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _callerNameCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _caseTypeCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String? _severity;

  LatLng _selectedLocation = const LatLng(19.6158, 37.2164);
  final MapController _mapController = MapController();
  bool _loadingLocation = false;
  bool _submitting = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
      _mapController.move(_selectedLocation, 15);
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final request = AmbulanceRequest(
        id: '',
        callerName: _callerNameCtrl.text.trim(),
        patientName: _patientNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        caseType: _caseTypeCtrl.text.trim(),
        severity: _severity ?? '',
        details: _detailsCtrl.text.trim(),
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
      );
      await ApiService.createRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ بنجاح')),
      );
      _formKey.currentState!.reset();
      _callerNameCtrl.clear();
      _patientNameCtrl.clear();
      _phoneCtrl.clear();
      _caseTypeCtrl.clear();
      _detailsCtrl.clear();
      setState(() => _severity = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _callerNameCtrl.dispose();
    _patientNameCtrl.dispose();
    _phoneCtrl.dispose();
    _caseTypeCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _callerNameCtrl,
            decoration: const InputDecoration(labelText: 'اسم المتصل', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _patientNameCtrl,
            decoration: const InputDecoration(labelText: 'اسم المريض (إن وجد)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _caseTypeCtrl,
            decoration: const InputDecoration(labelText: 'نوع الحالة (حادث، إغماء، ولادة...)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            decoration: const InputDecoration(labelText: 'درجة الخطورة', border: OutlineInputBorder()),
            items: kSeverityOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _severity = v),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _detailsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'ملاحظات إضافية', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('موقع الحالة', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadingLocation ? null : _getCurrentLocation,
                icon: _loadingLocation
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('موقعي الحالي'),
              ),
            ],
          ),
          const Text('اضغط مطولًا على الخريطة لتحديد الموقع', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 13,
                  onLongPress: (tapPosition, point) => setState(() => _selectedLocation = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ambulance_app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40, height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_submitting ? 'جاري الإرسال...' : 'إرسال البلاغ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _RequestsList extends StatefulWidget {
  const _RequestsList();

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  List<AmbulanceRequest> _requests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final list = await ApiService.getRequests();
      if (mounted) setState(() { _requests = list; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر الاتصال بالسيرفر');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'enroute_to_scene':
      case 'transporting': return Colors.purple;
      case 'arrived_at_scene': return Colors.teal;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text(_error!));
    if (_requests.isEmpty) return const Center(child: Text('لا توجد بلاغات بعد'));
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i];
          return Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: _statusColor(r.status)),
              title: Text('${r.patientName.isEmpty ? r.callerName : r.patientName} - ${r.caseType}'),
              subtitle: Text('المتصل: ${r.callerName} | ${r.phone}'),
              trailing: Chip(
                label: Text(r.statusLabel, style: const TextStyle(fontSize: 11)),
                backgroundColor: _statusColor(r.status).withOpacity(0.15),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransferTab extends StatelessWidget {
  const _TransferTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'لتنسيق نقل مريض بين مستشفيين',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('نموذج تحويل جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HospitalTransferScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
