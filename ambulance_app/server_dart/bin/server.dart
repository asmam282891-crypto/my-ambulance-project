// سيرفر نظام الإسعاف المركزي - Dart + SQLite + تسجيل دخول وصلاحيات
//
// طريقة التشغيل:
//   dart pub get
//   dart run bin/server.dart
//
// المستخدمين الابتدائيين (غيّر كلمات المرور فورًا من لوحة تحكم المدير):
//   admin      / Ps@Admin26      → مدير النظام (صلاحيات كاملة)
//   dispatcher / Ps@Dispatch26   → موظف بلاغات
//   paramedic1 / Ps@Medic26      → مسعف (مربوط بسيارة إسعاف رقم 1)
//   hospital1  / Ps@Hospital26   → مستشفى بورتسودان التعليمي

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

late Database db;

// جلسات الدخول محفوظة بالذاكرة: token -> بيانات المستخدم
// (لو أعدت تشغيل السيرفر، الكل يحتاج يسجل دخول من جديد - هذا طبيعي وآمن)
final Map<String, Map<String, dynamic>> sessions = {};

// ---------------- أدوات مساعدة ----------------

Response jsonResponse(dynamic data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  );
}

Future<Map<String, dynamic>> readJsonBody(Request request) async {
  final body = await request.readAsString();
  if (body.isEmpty) return {};
  return jsonDecode(body) as Map<String, dynamic>;
}

Map<String, dynamic> rowToMap(Row row) => row.map((k, v) => MapEntry(k, v));

Map<String, dynamic> userPublic(Map<String, dynamic> u) => {
      'id': u['id'],
      'username': u['username'],
      'fullName': u['fullName'],
      'role': u['role'],
      'ambulanceId': u['ambulanceId'],
      'hospitalName': u['hospitalName'],
    };

String generateToken() {
  final rand = Random.secure();
  final bytes = List<int>.generate(24, (_) => rand.nextInt(256));
  return base64Url.encode(bytes);
}

/// يتحقق من صلاحية الدخول، ولو تحديد أدوار مسموحة، يتحقق إن المستخدم منها.
/// يرجّع بيانات المستخدم لو كل شي تمام، أو Response خطأ لو لأ.
Object authenticate(Request request, {List<String>? allowedRoles}) {
  final authHeader = request.headers['Authorization'] ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResponse({'error': 'يجب تسجيل الدخول'}, status: 401);
  }
  final token = authHeader.substring(7);
  final user = sessions[token];
  if (user == null) {
    return jsonResponse({'error': 'الجلسة منتهية، سجّل الدخول من جديد'}, status: 401);
  }
  if (allowedRoles != null && !allowedRoles.contains(user['role'])) {
    return jsonResponse({'error': 'ليست لديك صلاحية لهذا الإجراء'}, status: 403);
  }
  return user;
}

Middleware corsHeaders() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: headers);
    };
  };
}

void main() async {
  db = openAppDatabase();
  final router = Router();

  // ==================== تسجيل الدخول ====================

  router.post('/login', (Request req) async {
    final b = await readJsonBody(req);
    final username = b['username'];
    final password = b['password'];
    if (username == null || password == null) {
      return jsonResponse({'error': 'أدخل اسم المستخدم وكلمة المرور'}, status: 400);
    }
    final rows = db.select('SELECT * FROM users WHERE username = ?', [username]);
    if (rows.isEmpty) {
      return jsonResponse({'error': 'اسم المستخدم غير صحيح'}, status: 401);
    }
    final user = rowToMap(rows.first);
    if (user['passwordHash'] != hashPassword(password)) {
      return jsonResponse({'error': 'كلمة المرور غير صحيحة'}, status: 401);
    }
    final token = generateToken();
    sessions[token] = user;
    return jsonResponse({'token': token, 'user': userPublic(user)});
  });

  router.post('/logout', (Request req) async {
    final authHeader = req.headers['Authorization'] ?? '';
    if (authHeader.startsWith('Bearer ')) {
      sessions.remove(authHeader.substring(7));
    }
    return jsonResponse({'ok': true});
  });

  // ==================== إدارة المستخدمين (المدير فقط) ====================

  router.get('/users', (Request req) {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;
    final rows = db.select('SELECT * FROM users ORDER BY id');
    return jsonResponse(rows.map((r) => userPublic(rowToMap(r))).toList());
  });

  router.post('/users', (Request req) async {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;

    final b = await readJsonBody(req);
    if (b['username'] == null || b['password'] == null || b['fullName'] == null || b['role'] == null) {
      return jsonResponse({'error': 'بيانات ناقصة'}, status: 400);
    }
    try {
      final createdAt = DateTime.now().toIso8601String();
      db.execute('''
        INSERT INTO users (username, passwordHash, fullName, role, ambulanceId, hospitalName, createdAt)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        b['username'],
        hashPassword(b['password']),
        b['fullName'],
        b['role'],
        b['ambulanceId'],
        b['hospitalName'],
        createdAt,
      ]);
      final id = db.lastInsertRowId;
      final row = db.select('SELECT * FROM users WHERE id = ?', [id]).first;
      return jsonResponse(userPublic(rowToMap(row)), status: 201);
    } on SqliteException {
      return jsonResponse({'error': 'اسم المستخدم موجود مسبقًا'}, status: 409);
    }
  });

  router.delete('/users/<id>', (Request req, String id) async {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;

    final exists = db.select('SELECT id FROM users WHERE id = ?', [id]);
    if (exists.isEmpty) return jsonResponse({'error': 'المستخدم غير موجود'}, status: 404);
    db.execute('DELETE FROM users WHERE id = ?', [id]);
    return jsonResponse({'ok': true});
  });

  // ==================== Ambulance Requests (بلاغات المرضى) ====================

  router.get('/requests', (Request req) {
    final auth = authenticate(req);
    if (auth is Response) return auth;
    final rows = db.select('SELECT * FROM requests ORDER BY id DESC');
    return jsonResponse(rows.map(rowToMap).toList());
  });

  router.post('/requests', (Request req) async {
    final auth = authenticate(req, allowedRoles: ['admin', 'dispatcher']);
    if (auth is Response) return auth;
    final user = auth as Map<String, dynamic>;

    final b = await readJsonBody(req);
    if (b['patientName'] == null || b['phone'] == null || b['lat'] == null || b['lng'] == null) {
      return jsonResponse({'error': 'بيانات ناقصة'}, status: 400);
    }
    final createdAt = DateTime.now().toIso8601String();
    db.execute('''
      INSERT INTO requests
        (callerName, patientName, phone, caseType, severity, details, lat, lng, status, assignedAmbulanceId, createdByUserId, createdAt)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NULL, ?, ?)
    ''', [
      b['callerName'] ?? '',
      b['patientName'],
      b['phone'],
      b['caseType'] ?? '',
      b['severity'] ?? '',
      b['details'] ?? '',
      b['lat'],
      b['lng'],
      user['id'],
      createdAt,
    ]);

    final id = db.lastInsertRowId;
    final row = db.select('SELECT * FROM requests WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row), status: 201);
  });

  router.patch('/requests/<id>', (Request req, String id) async {
    final auth = authenticate(req, allowedRoles: ['admin', 'dispatcher', 'paramedic']);
    if (auth is Response) return auth;

    final exists = db.select('SELECT id FROM requests WHERE id = ?', [id]);
    if (exists.isEmpty) return jsonResponse({'error': 'البلاغ غير موجود'}, status: 404);

    final b = await readJsonBody(req);
    if (b.containsKey('status')) {
      db.execute('UPDATE requests SET status = ? WHERE id = ?', [b['status'], id]);
    }
    if (b.containsKey('assignedAmbulanceId')) {
      db.execute('UPDATE requests SET assignedAmbulanceId = ? WHERE id = ?',
          [b['assignedAmbulanceId'], id]);
    }
    final row = db.select('SELECT * FROM requests WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row));
  });

  // ==================== Transfer Requests (تحويلات المستشفيات) ====================

  const transferFields = [
    'patientName', 'dobOrAge', 'sex', 'clinicalCondition', 'criticalCareNeed',
    'fromHospital', 'fromFocalPoint', 'fromPhone',
    'toHospital', 'toFocalPoint', 'toPhone',
    'referralAppropriate', 'inappropriateReason', 'inappropriateCategory',
    'criticalBedCommunicated', 'bedAvailabilityConfirmed',
    'timeReferralRequest', 'timeCommunicationReceiving', 'timeDeparture',
    'timeCommunicationAmbulance', 'timeFeedbackAmbulance', 'timeArrival',
    'hr', 'rr', 'bp', 'temp', 'gcs', 'spo2', 'specialNotes',
    'ambulanceType', 'journeyTracked', 'issuesDuringTransit', 'issuesDescription', 'equipment',
    'conditionOnArrival', 'referralAccepted', 'notAcceptedReason', 'feedbackCommunicatedBack',
    'completedByName', 'completedBySignature',
    'fromLat', 'fromLng', 'toLat', 'toLng',
  ];

  router.get('/transfers', (Request req) {
    final auth = authenticate(req);
    if (auth is Response) return auth;
    final rows = db.select('SELECT * FROM transfers ORDER BY id DESC');
    return jsonResponse(rows.map(rowToMap).toList());
  });

  router.post('/transfers', (Request req) async {
    final auth = authenticate(req, allowedRoles: ['admin', 'dispatcher', 'hospital']);
    if (auth is Response) return auth;

    final b = await readJsonBody(req);
    if (b['fromHospital'] == null || b['toHospital'] == null) {
      return jsonResponse({'error': 'بيانات ناقصة'}, status: 400);
    }
    final createdAt = DateTime.now().toIso8601String();

    final columns = [...transferFields, 'status', 'createdAt'];
    final placeholders = List.filled(columns.length, '?').join(', ');
    final values = [
      ...transferFields.map((f) => b[f]),
      'pending',
      createdAt,
    ];

    db.execute(
      'INSERT INTO transfers (${columns.join(', ')}) VALUES ($placeholders)',
      values,
    );

    final id = db.lastInsertRowId;
    final row = db.select('SELECT * FROM transfers WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row), status: 201);
  });

  router.patch('/transfers/<id>', (Request req, String id) async {
    final auth = authenticate(req, allowedRoles: ['admin', 'dispatcher', 'paramedic', 'hospital']);
    if (auth is Response) return auth;

    final exists = db.select('SELECT id FROM transfers WHERE id = ?', [id]);
    if (exists.isEmpty) return jsonResponse({'error': 'طلب التحويل غير موجود'}, status: 404);

    final b = await readJsonBody(req);
    if (b.containsKey('status')) {
      db.execute('UPDATE transfers SET status = ? WHERE id = ?', [b['status'], id]);
    }
    if (b.containsKey('assignedAmbulanceId')) {
      db.execute('UPDATE transfers SET assignedAmbulanceId = ? WHERE id = ?',
          [b['assignedAmbulanceId'], id]);
    }
    final row = db.select('SELECT * FROM transfers WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row));
  });

  // ==================== Ambulances (أسطول الإسعاف) ====================

  router.get('/ambulances', (Request req) {
    final auth = authenticate(req);
    if (auth is Response) return auth;
    final rows = db.select('SELECT * FROM ambulances');
    return jsonResponse(rows.map(rowToMap).toList());
  });

  router.post('/ambulances', (Request req) async {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;

    final b = await readJsonBody(req);
    if (b['plateNumber'] == null || b['driverName'] == null) {
      return jsonResponse({'error': 'بيانات ناقصة'}, status: 400);
    }
    final id = b['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    db.execute('''
      INSERT INTO ambulances (id, plateNumber, driverName, status, lat, lng)
      VALUES (?, ?, ?, 'available', ?, ?)
    ''', [id, b['plateNumber'], b['driverName'], b['lat'] ?? 19.6158, b['lng'] ?? 37.2164]);

    final row = db.select('SELECT * FROM ambulances WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row), status: 201);
  });

  router.patch('/ambulances/<id>', (Request req, String id) async {
    final auth = authenticate(req, allowedRoles: ['admin', 'paramedic']);
    if (auth is Response) return auth;

    final exists = db.select('SELECT id FROM ambulances WHERE id = ?', [id]);
    if (exists.isEmpty) return jsonResponse({'error': 'الإسعاف غير موجود'}, status: 404);

    final b = await readJsonBody(req);
    if (b.containsKey('status')) {
      db.execute('UPDATE ambulances SET status = ? WHERE id = ?', [b['status'], id]);
    }
    if (b.containsKey('lat')) {
      db.execute('UPDATE ambulances SET lat = ? WHERE id = ?', [b['lat'], id]);
    }
    if (b.containsKey('lng')) {
      db.execute('UPDATE ambulances SET lng = ? WHERE id = ?', [b['lng'], id]);
    }
    if (b.containsKey('plateNumber')) {
      db.execute('UPDATE ambulances SET plateNumber = ? WHERE id = ?', [b['plateNumber'], id]);
    }
    if (b.containsKey('driverName')) {
      db.execute('UPDATE ambulances SET driverName = ? WHERE id = ?', [b['driverName'], id]);
    }
    final row = db.select('SELECT * FROM ambulances WHERE id = ?', [id]).first;
    return jsonResponse(rowToMap(row));
  });

  router.delete('/ambulances/<id>', (Request req, String id) async {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;

    final exists = db.select('SELECT id FROM ambulances WHERE id = ?', [id]);
    if (exists.isEmpty) return jsonResponse({'error': 'الإسعاف غير موجود'}, status: 404);
    db.execute('DELETE FROM ambulances WHERE id = ?', [id]);
    return jsonResponse({'ok': true});
  });

  // ==================== إحصائيات وتقارير ====================

  router.get('/stats', (Request req) {
    final auth = authenticate(req, allowedRoles: ['admin']);
    if (auth is Response) return auth;

    final totalRequests = db.select('SELECT COUNT(*) as c FROM requests').first['c'];
    final completedRequests =
        db.select("SELECT COUNT(*) as c FROM requests WHERE status = 'completed'").first['c'];
    final totalTransfers = db.select('SELECT COUNT(*) as c FROM transfers').first['c'];
    final completedTransfers =
        db.select("SELECT COUNT(*) as c FROM transfers WHERE status = 'completed'").first['c'];
    final ambulancesByStatus = db
        .select('SELECT status, COUNT(*) as c FROM ambulances GROUP BY status')
        .map((r) => {'status': r['status'], 'count': r['c']})
        .toList();
    final requestsBySeverity = db
        .select("SELECT severity, COUNT(*) as c FROM requests WHERE severity IS NOT NULL AND severity != '' GROUP BY severity")
        .map((r) => {'severity': r['severity'], 'count': r['c']})
        .toList();

    return jsonResponse({
      'totalRequests': totalRequests,
      'completedRequests': completedRequests,
      'totalTransfers': totalTransfers,
      'completedTransfers': completedTransfers,
      'ambulancesByStatus': ambulancesByStatus,
      'requestsBySeverity': requestsBySeverity,
    });
  });

  // ==================== تشغيل السيرفر ====================

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 3000);
  print('✅ سيرفر الإسعاف المركزي (Dart + SQLite + صلاحيات) يعمل على http://localhost:${server.port}');
  print('📦 قاعدة البيانات محفوظة في ملف: ambulance.db');
  print('👤 مستخدمو الدخول الابتدائيون: admin/Ps@Admin26, dispatcher/Ps@Dispatch26, paramedic1/Ps@Medic26, hospital1/Ps@Hospital26');
}
