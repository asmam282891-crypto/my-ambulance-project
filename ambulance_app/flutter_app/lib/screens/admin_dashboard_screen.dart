import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ambulance_request.dart';
import '../models/transfer_request.dart';
import '../models/ambulance.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'attendance_scan_screen.dart';
import '../services/attendance_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  List<AmbulanceRequest> _requests = [];
  List<TransferRequest> _transfers = [];
  List<Ambulance> _ambulances = [];
  List<AppUser> _users = [];
  List<AttendanceRecord> _todayAttendance = [];
  String? _error;
  String? _attendanceError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        ApiService.getRequests(),
        ApiService.getTransfers(),
        ApiService.getAmbulances(),
        ApiService.getUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _requests = results[0] as List<AmbulanceRequest>;
        _transfers = results[1] as List<TransferRequest>;
        _ambulances = results[2] as List<Ambulance>;
        _users = results[3] as List<AppUser>;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'تعذر الاتصال بـ Supabase. تأكد من صحة الإعدادات بملف supabase_config.dart');
      }
    }

    try {
      final attendanceList = await ApiService.getAttendanceForDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _todayAttendance = attendanceList;
        _attendanceError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _attendanceError = 'تعذر تحميل جدول attendance في Supabase: $e');
      }
    }
  }

  // ---------------- إجراءات البلاغات ----------------

  Future<void> _assignAmbulance(AmbulanceRequest req) async {
    final available = _ambulances.where((a) => a.status == 'available').toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد إسعافات متاحة حاليًا')),
      );
      return;
    }
    final selected = await showDialog<Ambulance>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر عربة الإسعاف (الأقرب أفضل)'),
        children: available
            .map((a) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, a),
                  child: Text('${a.plateNumber} - ${a.driverName}'),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;

    try {
      await ApiService.updateRequestStatus(req.id, 'accepted', ambulanceId: selected.id);
      await ApiService.updateAmbulanceStatus(selected.id, 'busy');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _advanceTransferStatus(TransferRequest t) async {
    final next = {
      'pending': 'accepted',
      'accepted': 'enroute',
      'enroute': 'completed',
    }[t.status];
    if (next == null) return;
    try {
      await ApiService.updateTransferStatus(t.id, next);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _toggleAmbulanceOffline(Ambulance a) async {
    final newStatus = a.status == 'offline' ? 'available' : 'offline';
    try {
      await ApiService.updateAmbulanceStatus(a.id, newStatus);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _deleteAmbulance(Ambulance a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${a.plateNumber}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteAmbulance(a.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _addAmbulanceDialog() async {
    final plateCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة سيارة إسعاف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'رقم اللوحة')),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'اسم السائق')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (result != true) return;
    if (plateCtrl.text.trim().isEmpty || driverCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.createAmbulance(plateCtrl.text.trim(), driverCtrl.text.trim());
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  // ---------------- إجراءات المستخدمين ----------------

  Future<void> _addUserDialog() async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController();
    String role = 'doctor';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة مستخدم جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
                TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'الوظيفة'),
                  items: const [
                    DropdownMenuItem(value: 'doctor', child: Text('طبيب')),
                    DropdownMenuItem(value: 'nurse', child: Text('ممرض / ممرضة')),
                    DropdownMenuItem(value: 'paramedic', child: Text('مسعف')),
                    DropdownMenuItem(value: 'employee', child: Text('موظف')),
                    DropdownMenuItem(value: 'dispatcher', child: Text('موظف بلاغات')),
                    DropdownMenuItem(value: 'hospital', child: Text('مستشفى')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'doctor'),
                ),
                if (role == 'hospital')
                  TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: 'اسم المستشفى')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكملي الاسم واسم المستخدم وكلمة المرور')));
      return;
    }

    try {
      await ApiService.createUser(
        username: usernameCtrl.text.trim(),
        password: passwordCtrl.text,
        fullName: nameCtrl.text.trim(),
        role: role,
        hospitalName: hospitalCtrl.text.trim().isEmpty ? null : hospitalCtrl.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء المستخدم بنجاح')));
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء المستخدم: $e')));
    }
  }

  Future<void> _showSharedQr() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('باركود الحضور والانصراف الموحد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: AttendanceService.sharedQrValue, size: 240),
            const SizedBox(height: 12),
            const Text('هذا هو الباركود الذي يمسحه جميع الموظفين. يمكن عرضه على شاشة أو طباعته.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showTransferDetails(TransferRequest t) {
    Widget row(String label, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text('نموذج التحويل التفصيلي', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            row('المريض', t.patientName),
            row('العمر / تاريخ الميلاد', t.dobOrAge),
            row('الجنس', t.sex),
            row('الحالة السريرية', t.clinicalCondition),
            row('الرعاية الحرجة المطلوبة', t.criticalCareNeed.join('، ')),
            const Divider(),
            row('من', '${t.fromHospital} (${t.fromFocalPoint} - ${t.fromPhone})'),
            row('إلى', '${t.toHospital} (${t.toFocalPoint} - ${t.toPhone})'),
            const Divider(),
            row('التحويل مناسب؟', t.referralAppropriate),
            row('سبب عدم الملاءمة', t.inappropriateReason),
            row('تصنيف السبب', t.inappropriateCategory.join('، ')),
            row('تم إبلاغ حاجة سرير حرج؟', t.criticalBedCommunicated),
            row('تم تأكيد توفر السرير؟', t.bedAvailabilityConfirmed),
            const Divider(),
            row('وقت طلب التحويل', t.timeReferralRequest),
            row('وقت التواصل مع المستقبلة', t.timeCommunicationReceiving),
            row('وقت المغادرة', t.timeDeparture),
            row('وقت التواصل مع الإسعاف', t.timeCommunicationAmbulance),
            row('وقت رد الإسعاف', t.timeFeedbackAmbulance),
            row('وقت الوصول', t.timeArrival),
            const Divider(),
            row('HR', t.hr),
            row('RR', t.rr),
            row('BP', t.bp),
            row('Temp', t.temp),
            row('GCS', t.gcs),
            row('SPO2', t.spo2),
            row('ملاحظات خاصة', t.specialNotes),
            const Divider(),
            row('نوع الإسعاف', t.ambulanceType),
            row('التجهيزات', t.equipment),
            row('تم تتبع الرحلة؟', t.journeyTracked),
            row('مشاكل أثناء النقل؟', t.issuesDuringTransit),
            row('وصف المشكلة', t.issuesDescription),
            const Divider(),
            row('حالة الوصول', t.conditionOnArrival),
            row('تم قبول التحويل؟', t.referralAccepted),
            row('سبب عدم القبول', t.notAcceptedReason),
            row('تم إبلاغ المنشأة المحوِّلة؟', t.feedbackCommunicatedBack),
            const Divider(),
            row('عُبّئ بواسطة', t.completedByName),
            row('التوقيع', t.completedBySignature),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted':
      case 'available': return Colors.blue;
      case 'enroute':
      case 'enroute_to_scene':
      case 'transporting':
      case 'busy': return Colors.purple;
      case 'arrived_at_scene': return Colors.teal;
      case 'completed': return Colors.green;
      case 'offline': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المدير - ${user?.fullName ?? ""}'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'البلاغات'),
            Tab(text: 'التحويلات'),
            Tab(text: 'الأسطول'),
            Tab(text: 'المستخدمون'),
            Tab(text: 'الحضور'),
            Tab(text: 'التقارير'),
            Tab(text: 'خريطة عامة'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'حضور وانصراف',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScanScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildTransfersTab(),
                _buildFleetTab(),
                _buildUsersTab(),
                _buildAttendanceTab(),
                _buildReportsTab(),
                _buildMapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) return const Center(child: Text('لا توجد بلاغات حاليًا'));
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
              title: Text(r.patientName.isEmpty ? (r.callerName.isEmpty ? 'بلاغ #${r.id}' : r.callerName) : r.patientName),
              subtitle: Text('${r.details}\nالهاتف: ${r.phone}'),
              isThreeLine: true,
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(r.statusLabel, style: const TextStyle(fontSize: 11)),
                    backgroundColor: _statusColor(r.status).withOpacity(0.15),
                  ),
                  const SizedBox(height: 4),
                  if (r.status == 'pending')
                    TextButton(
                      onPressed: () => _assignAmbulance(r),
                      child: const Text('توزيع على إسعاف'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransfersTab() {
    if (_transfers.isEmpty) return const Center(child: Text('لا توجد طلبات تحويل حاليًا'));
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _transfers.length,
        itemBuilder: (context, i) {
          final t = _transfers[i];
          return Card(
            child: ListTile(
              leading: Icon(Icons.sync_alt, color: _statusColor(t.status)),
              title: Text('${t.fromHospital} ← ${t.toHospital}'),
              subtitle: Text(
                '${t.patientName.isEmpty ? "" : "المريض: ${t.patientName}\n"}التجهيزات: ${t.equipment}',
              ),
              isThreeLine: t.patientName.isNotEmpty,
              onTap: () => _showTransferDetails(t),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(t.statusLabel, style: const TextStyle(fontSize: 11)),
                    backgroundColor: _statusColor(t.status).withOpacity(0.15),
                  ),
                  const SizedBox(height: 4),
                  if (t.status != 'completed')
                    TextButton(
                      onPressed: () => _advanceTransferStatus(t),
                      child: Text(
                        t.status == 'pending' ? 'قبول' : t.status == 'accepted' ? 'بدء التحرك' : 'إتمام',
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

  Widget _buildFleetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة سيارة إسعاف'),
              onPressed: _addAmbulanceDialog,
            ),
          ),
        ),
        Expanded(
          child: _ambulances.isEmpty
              ? const Center(child: Text('لا توجد بيانات أسطول'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _ambulances.length,
                    itemBuilder: (context, i) {
                      final a = _ambulances[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.airport_shuttle, color: _statusColor(a.status)),
                          title: Text(a.plateNumber),
                          subtitle: Text('السائق: ${a.driverName}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(a.statusLabel, style: const TextStyle(fontSize: 11)),
                                backgroundColor: _statusColor(a.status).withOpacity(0.15),
                              ),
                              if (a.status == 'available' || a.status == 'offline')
                                IconButton(
                                  icon: Icon(a.status == 'offline' ? Icons.play_circle : Icons.pause_circle),
                                  onPressed: () => _toggleAmbulanceOffline(a),
                                  tooltip: a.status == 'offline' ? 'تفعيل' : 'إخراج من الخدمة',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAmbulance(a),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('إضافة مستخدم'),
                onPressed: _addUserDialog,
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('باركود الحضور'),
                onPressed: _showSharedQr,
              )),
            ],
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمون'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _users.length,
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(u.fullName),
                          subtitle: Text('${u.username} - ${u.roleLabel}'
                              '${u.hospitalName != null && u.hospitalName!.isNotEmpty ? " (${u.hospitalName})" : ""}'),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final todayLabel = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final usersById = {for (final u in _users) u.id: u};

    return Column(
      children: [
        if (_attendanceError != null)
          Container(
            width: double.infinity,
            color: Colors.orange[50],
            padding: const EdgeInsets.all(8),
            child: Text(_attendanceError!, style: const TextStyle(color: Colors.orange)),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text('حضور وانصراف اليوم: $todayLabel', style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
              IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'مسح الباركود', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScanScreen()))),
            ],
          ),
        ),
        Expanded(
          child: _todayAttendance.isEmpty
              ? const Center(child: Text('لا توجد سجلات حضور اليوم'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _todayAttendance.length,
                    itemBuilder: (context, i) {
                      final a = _todayAttendance[i];
                      final u = usersById[a.userId];
                      String fmt(DateTime? d) => d == null ? '—' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                      return Card(
                        child: ListTile(
                          leading: Icon(a.checkOut == null ? Icons.login : Icons.check_circle, color: a.checkOut == null ? Colors.orange : Colors.green),
                          title: Text(u?.fullName ?? a.userId),
                          subtitle: Text('${u?.roleLabel ?? ''}\nالحضور: ${fmt(a.checkIn)}    الانصراف: ${fmt(a.checkOut)}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    Widget statCard(String label, dynamic value, IconData icon, Color color) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final completedRequests = _requests.where((r) => r.status == 'completed').length;
    final completedTransfers = _transfers.where((t) => t.status == 'completed').length;

    final ambulancesByStatus = <String, int>{};
    for (final a in _ambulances) {
      ambulancesByStatus[a.status] = (ambulancesByStatus[a.status] ?? 0) + 1;
    }

    final requestsBySeverity = <String, int>{};
    for (final r in _requests) {
      if (r.severity.isEmpty) continue;
      requestsBySeverity[r.severity] = (requestsBySeverity[r.severity] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          statCard('إجمالي البلاغات', _requests.length, Icons.warning, Colors.orange),
          statCard('البلاغات المكتملة', completedRequests, Icons.check_circle, Colors.green),
          statCard('إجمالي التحويلات', _transfers.length, Icons.sync_alt, Colors.blue),
          statCard('التحويلات المكتملة', completedTransfers, Icons.check_circle, Colors.green),
          statCard('حضور اليوم', _todayAttendance.where((a) => a.checkIn != null).length, Icons.how_to_reg, Colors.green),
          statCard('غياب اليوم', 0, Icons.person_off, Colors.red),
          const SizedBox(height: 16),
          const Text('توزيع حالة الأسطول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...ambulancesByStatus.entries.map((e) => ListTile(
                leading: Icon(Icons.airport_shuttle, color: _statusColor(e.key)),
                title: Text(e.key),
                trailing: Text('${e.value}'),
              )),
          const SizedBox(height: 16),
          const Text('البلاغات حسب درجة الخطورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...requestsBySeverity.entries.map((e) => ListTile(
                leading: const Icon(Icons.priority_high),
                title: Text(e.key),
                trailing: Text('${e.value}'),
              )),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    final markers = <Marker>[];
    for (final a in _ambulances) {
      markers.add(Marker(
        point: LatLng(a.lat, a.lng),
        width: 34, height: 34,
        child: Icon(Icons.airport_shuttle, color: _statusColor(a.status), size: 30),
      ));
    }
    for (final r in _requests.where((r) => r.status != 'completed')) {
      markers.add(Marker(
        point: LatLng(r.lat, r.lng),
        width: 34, height: 34,
        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 30),
      ));
    }
    final center = markers.isNotEmpty ? markers.first.point : const LatLng(19.6158, 37.2164);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ambulance_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
