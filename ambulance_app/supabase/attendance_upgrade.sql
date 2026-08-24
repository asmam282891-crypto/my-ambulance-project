-- شغّل هذا الملف مرة واحدة بعد إنشاء جدول attendance الحالي.

-- منع وجود أكثر من سجل لنفس المستخدم في نفس اليوم.
create unique index if not exists attendance_user_date_unique
on public.attendance (user_id, attendance_date);

-- حماية سجلات الحضور.
alter table public.attendance enable row level security;

drop policy if exists attendance_select on public.attendance;
drop policy if exists attendance_insert on public.attendance;
drop policy if exists attendance_update on public.attendance;

create policy attendance_select on public.attendance
for select to authenticated
using (
  auth.uid() = user_id
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy attendance_insert on public.attendance
for insert to authenticated
with check (auth.uid() = user_id);

create policy attendance_update on public.attendance
for update to authenticated
using (
  auth.uid() = user_id
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  auth.uid() = user_id
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);
