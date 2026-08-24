import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/transfer_request.dart';
import '../services/api_service.dart';

// قائمة مستشفيات بورتسودان بإحداثيات تقريبية - عدّلها حسب الدقة الفعلية لو احتجت
const Map<String, LatLng> kHospitals = {
  'مستشفى بورتسودان التعليمي': LatLng(19.6158, 37.2164),
  'مستشفى الميناء': LatLng(19.6200, 37.2100),
  'مستشفى الشرطة': LatLng(19.6100, 37.2200),
  'مستشفى الولاية': LatLng(19.6050, 37.2250),
  'مستشفى الأمل': LatLng(19.6250, 37.2050),
};

const kCriticalCareOptions = ['ICU', 'CCU', 'HDU', 'PICU', 'NICU', 'Maternity ICU', 'Maternity HDU'];
const kInappropriateCategoryOptions = [
  'يمكن معالجتها بالمنشأة المحوّلة',
  'التحويل ينقصه توثيق',
  'وصل المريض متأخرًا',
  'ليست التخصص الصحيح',
  'أخرى',
];

class HospitalTransferScreen extends StatefulWidget {
  /// لو انفتحت الشاشة من حساب مستشفى، نثبّت اسم المستشفى المحوِّلة تلقائيًا
  /// ونمنع تغييره (المستشفى يرسل الطلب باسم نفسه فقط).
  final String? lockedFromHospital;

  const HospitalTransferScreen({super.key, this.lockedFromHospital});

  @override
  State<HospitalTransferScreen> createState() => _HospitalTransferScreenState();
}

class _HospitalTransferScreenState extends State<HospitalTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  // بيانات المريض
  final _patientNameCtrl = TextEditingController();
  final _dobOrAgeCtrl = TextEditingController();
  String? _sex;
  final _clinicalConditionCtrl = TextEditingController();
  final Set<String> _criticalCareNeed = {};

  // المنشآت
  String? _fromHospital;
  final _fromFocalPointCtrl = TextEditingController();
  final _fromPhoneCtrl = TextEditingController();
  String? _toHospital;
  final _toFocalPointCtrl = TextEditingController();
  final _toPhoneCtrl = TextEditingController();

  // ملاءمة التحويل
  String? _referralAppropriate;
  final _inappropriateReasonCtrl = TextEditingController();
  final Set<String> _inappropriateCategory = {};

  // التواصل
  String? _criticalBedCommunicated;
  String? _bedAvailabilityConfirmed;

  // الأوقات
  final _timeReferralRequestCtrl = TextEditingController();
  final _timeCommunicationReceivingCtrl = TextEditingController();
  final _timeDepartureCtrl = TextEditingController();
  final _timeCommunicationAmbulanceCtrl = TextEditingController();
  final _timeFeedbackAmbulanceCtrl = TextEditingController();
  final _timeArrivalCtrl = TextEditingController();

  // العلامات الحيوية
  final _hrCtrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _gcsCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _specialNotesCtrl = TextEditingController();

  // النقل
  String? _ambulanceType;
  String? _journeyTracked;
  String? _issuesDuringTransit;
  final _issuesDescriptionCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();

  // النتيجة
  String? _conditionOnArrival;
  String? _referralAccepted;
  final _notAcceptedReasonCtrl = TextEditingController();
  String? _feedbackCommunicatedBack;

  // تم التعبئة بواسطة
  final _completedByNameCtrl = TextEditingController();
  final _completedBySignatureCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.lockedFromHospital != null) {
      _fromHospital = widget.lockedFromHospital;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _patientNameCtrl, _dobOrAgeCtrl, _clinicalConditionCtrl,
      _fromFocalPointCtrl, _fromPhoneCtrl, _toFocalPointCtrl, _toPhoneCtrl,
      _inappropriateReasonCtrl,
      _timeReferralRequestCtrl, _timeCommunicationReceivingCtrl, _timeDepartureCtrl,
      _timeCommunicationAmbulanceCtrl, _timeFeedbackAmbulanceCtrl, _timeArrivalCtrl,
      _hrCtrl, _rrCtrl, _bpCtrl, _tempCtrl, _gcsCtrl, _spo2Ctrl, _specialNotesCtrl,
      _issuesDescriptionCtrl, _equipmentCtrl, _notAcceptedReasonCtrl,
      _completedByNameCtrl, _completedBySignatureCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromHospital == null || _toHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المنشأة المحوِّلة والمستقبلة')),
      );
      return;
    }
    if (_fromHospital == _toHospital) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار مستشفيين مختلفين')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final fromPos = kHospitals[_fromHospital]!;
      final toPos = kHospitals[_toHospital]!;

      final transfer = TransferRequest(
        id: '',
        patientName: _patientNameCtrl.text.trim(),
        dobOrAge: _dobOrAgeCtrl.text.trim(),
        sex: _sex ?? '',
        clinicalCondition: _clinicalConditionCtrl.text.trim(),
        criticalCareNeed: _criticalCareNeed.toList(),
        fromHospital: _fromHospital!,
        fromFocalPoint: _fromFocalPointCtrl.text.trim(),
        fromPhone: _fromPhoneCtrl.text.trim(),
        toHospital: _toHospital!,
        toFocalPoint: _toFocalPointCtrl.text.trim(),
        toPhone: _toPhoneCtrl.text.trim(),
        referralAppropriate: _referralAppropriate ?? '',
        inappropriateReason: _inappropriateReasonCtrl.text.trim(),
        inappropriateCategory: _inappropriateCategory.toList(),
        criticalBedCommunicated: _criticalBedCommunicated ?? '',
        bedAvailabilityConfirmed: _bedAvailabilityConfirmed ?? '',
        timeReferralRequest: _timeReferralRequestCtrl.text.trim(),
        timeCommunicationReceiving: _timeCommunicationReceivingCtrl.text.trim(),
        timeDeparture: _timeDepartureCtrl.text.trim(),
        timeCommunicationAmbulance: _timeCommunicationAmbulanceCtrl.text.trim(),
        timeFeedbackAmbulance: _timeFeedbackAmbulanceCtrl.text.trim(),
        timeArrival: _timeArrivalCtrl.text.trim(),
        hr: _hrCtrl.text.trim(),
        rr: _rrCtrl.text.trim(),
        bp: _bpCtrl.text.trim(),
        temp: _tempCtrl.text.trim(),
        gcs: _gcsCtrl.text.trim(),
        spo2: _spo2Ctrl.text.trim(),
        specialNotes: _specialNotesCtrl.text.trim(),
        ambulanceType: _ambulanceType ?? '',
        journeyTracked: _journeyTracked ?? '',
        issuesDuringTransit: _issuesDuringTransit ?? '',
        issuesDescription: _issuesDescriptionCtrl.text.trim(),
        equipment: _equipmentCtrl.text.trim(),
        conditionOnArrival: _conditionOnArrival ?? '',
        referralAccepted: _referralAccepted ?? '',
        notAcceptedReason: _notAcceptedReasonCtrl.text.trim(),
        feedbackCommunicatedBack: _feedbackCommunicatedBack ?? '',
        completedByName: _completedByNameCtrl.text.trim(),
        completedBySignature: _completedBySignatureCtrl.text.trim(),
        fromLat: fromPos.latitude,
        fromLng: fromPos.longitude,
        toLat: toPos.latitude,
        toLng: toPos.longitude,
      );

      await ApiService.createTransfer(transfer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال نموذج التحويل بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الطلب: تأكد أن السيرفر شغّال ($e)')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
      );

  Widget _yesNoRow(String label, String? value, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        ChoiceChip(
          label: const Text('نعم'),
          selected: value == 'Yes',
          onSelected: (_) => onChanged('Yes'),
        ),
        const SizedBox(width: 6),
        ChoiceChip(
          label: const Text('لا'),
          selected: value == 'No',
          onSelected: (_) => onChanged('No'),
        ),
      ],
    );
  }

  Widget _timeField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        readOnly: true,
        onTap: () async {
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (t != null) ctrl.text = t.format(context);
        },
      ),
    );
  }

  Widget _vitalField(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: TextInputType.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromPos = _fromHospital != null ? kHospitals[_fromHospital] : null;
    final toPos = _toHospital != null ? kHospitals[_toHospital] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نموذج تحويل مريض (Steering Unit)'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ---------- بيانات المريض ----------
            _sectionTitle('بيانات المريض'),
            TextFormField(
              controller: _patientNameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المريض', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobOrAgeCtrl,
                    decoration: const InputDecoration(labelText: 'تاريخ الميلاد / العمر', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('ذكر')),
                      DropdownMenuItem(value: 'Female', child: Text('أنثى')),
                    ],
                    onChanged: (v) => setState(() => _sex = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _clinicalConditionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'الحالة السريرية / التشخيص', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            const Text('نوع الرعاية الحرجة المطلوبة', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 6,
              children: kCriticalCareOptions.map((opt) {
                final selected = _criticalCareNeed.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _criticalCareNeed.add(opt);
                    } else {
                      _criticalCareNeed.remove(opt);
                    }
                  }),
                );
              }).toList(),
            ),

            const Divider(height: 30),

            // ---------- المنشآت ----------
            _sectionTitle('المنشأة المحوِّلة (من)'),
            DropdownButtonFormField<String>(
              initialValue: _fromHospital,
              decoration: const InputDecoration(labelText: 'اسم المنشأة', border: OutlineInputBorder()),
              items: kHospitals.keys.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: widget.lockedFromHospital != null
                  ? null
                  : (v) => setState(() => _fromHospital = v),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fromFocalPointCtrl,
              decoration: const InputDecoration(labelText: 'نقطة الاتصال (Focal point)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fromPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            ),

            _sectionTitle('المنشأة المستقبلة (إلى)'),
            DropdownButtonFormField<String>(
              initialValue: _toHospital,
              decoration: const InputDecoration(labelText: 'اسم المنشأة', border: OutlineInputBorder()),
              items: kHospitals.keys.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (v) => setState(() => _toHospital = v),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _toFocalPointCtrl,
              decoration: const InputDecoration(labelText: 'نقطة الاتصال (Focal point)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _toPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            ),

            const Divider(height: 30),

            // ---------- ملاءمة التحويل ----------
            _sectionTitle('هل هذا التحويل مناسب لمستوى الرعاية بالمنشأة المستقبلة؟'),
            _yesNoRow('الملاءمة', _referralAppropriate, (v) => setState(() => _referralAppropriate = v)),
            if (_referralAppropriate == 'No') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _inappropriateReasonCtrl,
                decoration: const InputDecoration(labelText: 'السبب', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: kInappropriateCategoryOptions.map((opt) {
                  final selected = _inappropriateCategory.contains(opt);
                  return FilterChip(
                    label: Text(opt, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _inappropriateCategory.add(opt);
                      } else {
                        _inappropriateCategory.remove(opt);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],

            const Divider(height: 30),

            // ---------- التواصل ----------
            _sectionTitle('التواصل بخصوص السرير الحرج'),
            _yesNoRow('المنشأة المحوِّلة أبلغت عن الحاجة لسرير حرج؟', _criticalBedCommunicated,
                (v) => setState(() => _criticalBedCommunicated = v)),
            const SizedBox(height: 8),
            _yesNoRow('المنشأة المستقبلة أكّدت توفر السرير؟', _bedAvailabilityConfirmed,
                (v) => setState(() => _bedAvailabilityConfirmed = v)),

            const Divider(height: 30),

            // ---------- الأوقات ----------
            _sectionTitle('الأوقات (اضغط لتحديد الوقت)'),
            _timeField('وقت طلب التحويل من المنشأة المحوِّلة', _timeReferralRequestCtrl),
            _timeField('وقت التواصل مع المنشأة المستقبلة', _timeCommunicationReceivingCtrl),
            _timeField('وقت المغادرة (من المنشأة المحوِّلة)', _timeDepartureCtrl),
            _timeField('وقت التواصل مع خدمات الإسعاف', _timeCommunicationAmbulanceCtrl),
            _timeField('وقت الرد من خدمات الإسعاف', _timeFeedbackAmbulanceCtrl),
            _timeField('وقت الوصول (إلى المنشأة المستقبلة)', _timeArrivalCtrl),

            const Divider(height: 30),

            // ---------- العلامات الحيوية ----------
            _sectionTitle('حالة المريض الحالية والعلامات الحيوية'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _vitalField('HR', _hrCtrl),
                _vitalField('RR', _rrCtrl),
                _vitalField('BP', _bpCtrl),
                _vitalField('Temp', _tempCtrl),
                _vitalField('GCS', _gcsCtrl),
                _vitalField('SPO2', _spo2Ctrl),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _specialNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات خاصة / تحديات / إجراءات للمتابعة',
                border: OutlineInputBorder(),
              ),
            ),

            const Divider(height: 30),

            // ---------- النقل ----------
            _sectionTitle('تفاصيل النقل بالإسعاف'),
            DropdownButtonFormField<String>(
              initialValue: _ambulanceType,
              decoration: const InputDecoration(labelText: 'نوع سيارة الإسعاف', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'BLS', child: Text('BLS')),
                DropdownMenuItem(value: 'ALS', child: Text('ALS')),
                DropdownMenuItem(value: 'ICU', child: Text('ICU')),
                DropdownMenuItem(value: 'Other', child: Text('أخرى')),
              ],
              onChanged: (v) => setState(() => _ambulanceType = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _equipmentCtrl,
              decoration: const InputDecoration(
                labelText: 'التجهيزات المطلوبة (أكسجين، جهاز تنفس...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _yesNoRow('تم تتبع الرحلة؟', _journeyTracked, (v) => setState(() => _journeyTracked = v)),
            const SizedBox(height: 8),
            _yesNoRow('حدثت أي مشاكل أثناء النقل؟', _issuesDuringTransit,
                (v) => setState(() => _issuesDuringTransit = v)),
            if (_issuesDuringTransit == 'Yes') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _issuesDescriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف المشكلة', border: OutlineInputBorder()),
              ),
            ],

            const Divider(height: 30),

            // ---------- النتيجة ----------
            _sectionTitle('حالة المريض عند الوصول والنتيجة'),
            DropdownButtonFormField<String>(
              initialValue: _conditionOnArrival,
              decoration: const InputDecoration(labelText: 'حالة المريض عند الوصول', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Unchanged', child: Text('بدون تغيير (كما بالتحويل)')),
                DropdownMenuItem(value: 'Improved', child: Text('تحسّنت')),
                DropdownMenuItem(value: 'Other', child: Text('أخرى')),
              ],
              onChanged: (v) => setState(() => _conditionOnArrival = v),
            ),
            const SizedBox(height: 10),
            _yesNoRow('تم قبول التحويل؟', _referralAccepted, (v) => setState(() => _referralAccepted = v)),
            if (_referralAccepted == 'No') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _notAcceptedReasonCtrl,
                decoration: const InputDecoration(labelText: 'السبب', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 8),
            _yesNoRow('تم إبلاغ المنشأة المحوِّلة بالنتيجة؟', _feedbackCommunicatedBack,
                (v) => setState(() => _feedbackCommunicatedBack = v)),

            const Divider(height: 30),

            // ---------- تم التعبئة بواسطة ----------
            _sectionTitle('تم التعبئة بواسطة'),
            TextFormField(
              controller: _completedByNameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _completedBySignatureCtrl,
              decoration: const InputDecoration(labelText: 'التوقيع (اكتب الاسم كتوقيع)', border: OutlineInputBorder()),
            ),

            // ---------- الخريطة ----------
            if (fromPos != null && toPos != null) ...[
              const Divider(height: 30),
              _sectionTitle('مسار التحويل'),
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (fromPos.latitude + toPos.latitude) / 2,
                        (fromPos.longitude + toPos.longitude) / 2,
                      ),
                      initialZoom: 11,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ambulance_app',
                      ),
                      PolylineLayer(polylines: [
                        Polyline(points: [fromPos, toPos], strokeWidth: 4, color: Colors.red[900]!),
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                          point: fromPos,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.local_hospital, color: Colors.blue, size: 32),
                        ),
                        Marker(
                          point: toPos,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.local_hospital, color: Colors.red, size: 32),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('إرسال نموذج التحويل'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
