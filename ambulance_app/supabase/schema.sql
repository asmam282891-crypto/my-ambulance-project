-- ============================================================
-- سكيما قاعدة بيانات "نظام الإسعاف القومي" لـ Supabase
-- انسخ هذا الملف كامل والصقه بـ SQL Editor داخل مشروع Supabase
-- (من القائمة الجانبية: SQL Editor → New query → الصق → Run)
-- ============================================================

-- ---------------- جدول الملفات الشخصية (المستخدمون وصلاحياتهم) ----------------
-- id مرتبط تلقائيًا بجدول auth.users الخاص بـ Supabase
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  "fullName" text not null,
  role text not null check (role in ('admin','dispatcher','paramedic','hospital')),
  "ambulanceId" text,
  "hospitalName" text,
  created_at timestamptz not null default now()
);

-- ---------------- جدول أسطول الإسعاف ----------------
create table ambulances (
  id text primary key,
  "plateNumber" text not null,
  "driverName" text not null,
  status text not null default 'available',
  lat double precision not null,
  lng double precision not null
);

-- ---------------- جدول البلاغات الطارئة ----------------
create table requests (
  id bigint generated always as identity primary key,
  "callerName" text,
  "patientName" text not null,
  phone text not null,
  "caseType" text,
  severity text,
  details text,
  lat double precision not null,
  lng double precision not null,
  status text not null default 'pending',
  "assignedAmbulanceId" text,
  "createdByUserId" uuid references profiles(id),
  "createdAt" timestamptz not null default now()
);

-- ---------------- جدول تحويلات المستشفيات (نموذج STEERING UNIT) ----------------
create table transfers (
  id bigint generated always as identity primary key,

  "patientName" text,
  "dobOrAge" text,
  sex text,
  "clinicalCondition" text,
  "criticalCareNeed" text,

  "fromHospital" text not null,
  "fromFocalPoint" text,
  "fromPhone" text,

  "toHospital" text not null,
  "toFocalPoint" text,
  "toPhone" text,

  "referralAppropriate" text,
  "inappropriateReason" text,
  "inappropriateCategory" text,

  "criticalBedCommunicated" text,
  "bedAvailabilityConfirmed" text,

  "timeReferralRequest" text,
  "timeCommunicationReceiving" text,
  "timeDeparture" text,
  "timeCommunicationAmbulance" text,
  "timeFeedbackAmbulance" text,
  "timeArrival" text,

  hr text, rr text, bp text, temp text, gcs text, spo2 text,
  "specialNotes" text,

  "ambulanceType" text,
  "journeyTracked" text,
  "issuesDuringTransit" text,
  "issuesDescription" text,
  equipment text,

  "conditionOnArrival" text,
  "referralAccepted" text,
  "notAcceptedReason" text,
  "feedbackCommunicatedBack" text,

  "completedByName" text,
  "completedBySignature" text,

  "fromLat" double precision,
  "fromLng" double precision,
  "toLat" double precision,
  "toLng" double precision,

  "assignedAmbulanceId" text,
  status text not null default 'pending',
  "createdAt" timestamptz not null default now()
);

-- ---------------- دالة مساعدة: ترجع دور المستخدم الحالي ----------------
create or replace function auth_role() returns text as $$
  select role from profiles where id = auth.uid();
$$ language sql stable security definer;

-- ============================================================
-- تفعيل الحماية على مستوى الصفوف (RLS) + السياسات
-- ============================================================

alter table profiles enable row level security;
alter table ambulances enable row level security;
alter table requests enable row level security;
alter table transfers enable row level security;

-- profiles: أي مستخدم مسجّل دخول يشوف كل الملفات (لعرض القوائم)
create policy "profiles_select" on profiles for select
  using (auth.uid() is not null);

-- ambulances: القراءة للجميع، الإضافة/الحذف للمدير فقط، التحديث للمدير والمسعف
create policy "ambulances_select" on ambulances for select
  using (auth.uid() is not null);
create policy "ambulances_insert" on ambulances for insert
  with check (auth_role() = 'admin');
create policy "ambulances_update" on ambulances for update
  using (auth_role() in ('admin','paramedic'));
create policy "ambulances_delete" on ambulances for delete
  using (auth_role() = 'admin');

-- requests: القراءة للجميع، الإضافة للمدير والموظف، التحديث للمدير/الموظف/المسعف
create policy "requests_select" on requests for select
  using (auth.uid() is not null);
create policy "requests_insert" on requests for insert
  with check (auth_role() in ('admin','dispatcher'));
create policy "requests_update" on requests for update
  using (auth_role() in ('admin','dispatcher','paramedic'));

-- transfers: القراءة للجميع، الإضافة للمدير/الموظف/المستشفى، التحديث للمدير/الموظف/المسعف/المستشفى
create policy "transfers_select" on transfers for select
  using (auth.uid() is not null);
create policy "transfers_insert" on transfers for insert
  with check (auth_role() in ('admin','dispatcher','hospital'));
create policy "transfers_update" on transfers for update
  using (auth_role() in ('admin','dispatcher','paramedic','hospital'));

-- ============================================================
-- بيانات أسطول ابتدائية (اختياري - عدّلها أو احذفها براحتك)
-- ============================================================
insert into ambulances (id, "plateNumber", "driverName", status, lat, lng) values
  ('1', 'إسعاف - 101', 'أحمد سالم', 'available', 19.6158, 37.2164),
  ('2', 'إسعاف - 102', 'خالد الغامدي', 'available', 19.6200, 37.2100),
  ('3', 'إسعاف - 103', 'محمد العتيبي', 'available', 19.6100, 37.2200);
