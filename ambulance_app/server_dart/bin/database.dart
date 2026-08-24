// إعداد قاعدة بيانات SQLite لنظام الإسعاف المركزي
// البيانات تُحفظ بملف حقيقي على القرص: ambulance.db
// يعني تبقى محفوظة حتى لو أوقفت السيرفر أو أعدت تشغيل الجهاز.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Database openAppDatabase() {
  final db = sqlite3.open('ambulance.db');

  // جدول المستخدمين والصلاحيات
  // role: admin (مدير) / dispatcher (موظف بلاغات) / paramedic (مسعف) / hospital (مستشفى)
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      fullName TEXT NOT NULL,
      role TEXT NOT NULL,
      ambulanceId TEXT,
      hospitalName TEXT,
      createdAt TEXT NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS ambulances (
      id TEXT PRIMARY KEY,
      plateNumber TEXT NOT NULL,
      driverName TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'available',
      lat REAL NOT NULL,
      lng REAL NOT NULL
    );
  ''');

  // بلاغات المرضى — الحالة توسعت لتغطي دورة حياة المهمة كاملة:
  // pending -> accepted -> enroute_to_scene -> arrived_at_scene -> transporting -> completed
  db.execute('''
    CREATE TABLE IF NOT EXISTS requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      callerName TEXT,
      patientName TEXT NOT NULL,
      phone TEXT NOT NULL,
      caseType TEXT,
      severity TEXT,
      details TEXT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      assignedAmbulanceId TEXT,
      createdByUserId INTEGER,
      createdAt TEXT NOT NULL
    );
  ''');

  // جدول التحويلات بين المستشفيات — نفس حقول نموذج STEERING UNIT الورقي
  db.execute('''
    CREATE TABLE IF NOT EXISTS transfers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      -- بيانات المريض
      patientName TEXT,
      dobOrAge TEXT,
      sex TEXT,
      clinicalCondition TEXT,
      criticalCareNeed TEXT,

      -- المنشأة المحوِّلة (من)
      fromHospital TEXT NOT NULL,
      fromFocalPoint TEXT,
      fromPhone TEXT,

      -- المنشأة المستقبلة (إلى)
      toHospital TEXT NOT NULL,
      toFocalPoint TEXT,
      toPhone TEXT,

      -- ملاءمة التحويل
      referralAppropriate TEXT,
      inappropriateReason TEXT,
      inappropriateCategory TEXT,

      -- التواصل بخصوص السرير
      criticalBedCommunicated TEXT,
      bedAvailabilityConfirmed TEXT,

      -- الأوقات
      timeReferralRequest TEXT,
      timeCommunicationReceiving TEXT,
      timeDeparture TEXT,
      timeCommunicationAmbulance TEXT,
      timeFeedbackAmbulance TEXT,
      timeArrival TEXT,

      -- العلامات الحيوية الحالية
      hr TEXT,
      rr TEXT,
      bp TEXT,
      temp TEXT,
      gcs TEXT,
      spo2 TEXT,
      specialNotes TEXT,

      -- تفاصيل النقل بالإسعاف
      ambulanceType TEXT,
      journeyTracked TEXT,
      issuesDuringTransit TEXT,
      issuesDescription TEXT,
      equipment TEXT,

      -- حالة الوصول والنتيجة
      conditionOnArrival TEXT,
      referralAccepted TEXT,
      notAcceptedReason TEXT,
      feedbackCommunicatedBack TEXT,

      -- تم التعبئة بواسطة
      completedByName TEXT,
      completedBySignature TEXT,

      -- إحداثيات للخريطة
      fromLat REAL,
      fromLng REAL,
      toLat REAL,
      toLng REAL,

      assignedAmbulanceId TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      createdAt TEXT NOT NULL
    );
  ''');

  // بيانات إسعاف ابتدائية لو الجدول فاضي (أول تشغيل فقط)
  final ambCount = db.select('SELECT COUNT(*) as c FROM ambulances').first['c'] as int;
  if (ambCount == 0) {
    db.execute('''
      INSERT INTO ambulances (id, plateNumber, driverName, status, lat, lng) VALUES
      ('1', 'إسعاف - 101', 'أحمد سالم', 'available', 19.6158, 37.2164),
      ('2', 'إسعاف - 102', 'خالد الغامدي', 'available', 19.6200, 37.2100),
      ('3', 'إسعاف - 103', 'محمد العتيبي', 'available', 19.6100, 37.2200);
    ''');
  }

  // مستخدمين ابتدائيين لأول تشغيل — غيّر كلمات المرور فورًا بعد أول دخول!
  final userCount = db.select('SELECT COUNT(*) as c FROM users').first['c'] as int;
  if (userCount == 0) {
    final createdAt = DateTime.now().toIso8601String();
    db.execute('''
      INSERT INTO users (username, passwordHash, fullName, role, ambulanceId, hospitalName, createdAt) VALUES
      (?, ?, ?, ?, ?, ?, ?)
    ''', ['admin', hashPassword('Ps@Admin26'), 'مدير النظام', 'admin', null, null, createdAt]);

    db.execute('''
      INSERT INTO users (username, passwordHash, fullName, role, ambulanceId, hospitalName, createdAt) VALUES
      (?, ?, ?, ?, ?, ?, ?)
    ''', ['dispatcher', hashPassword('Ps@Dispatch26'), 'موظف البلاغات', 'dispatcher', null, null, createdAt]);

    db.execute('''
      INSERT INTO users (username, passwordHash, fullName, role, ambulanceId, hospitalName, createdAt) VALUES
      (?, ?, ?, ?, ?, ?, ?)
    ''', ['paramedic1', hashPassword('Ps@Medic26'), 'أحمد سالم', 'paramedic', '1', null, createdAt]);

    db.execute('''
      INSERT INTO users (username, passwordHash, fullName, role, ambulanceId, hospitalName, createdAt) VALUES
      (?, ?, ?, ?, ?, ?, ?)
    ''', ['hospital1', hashPassword('Ps@Hospital26'), 'استقبال مستشفى بورتسودان التعليمي', 'hospital', null, 'مستشفى بورتسودان التعليمي', createdAt]);
  }

  return db;
}
