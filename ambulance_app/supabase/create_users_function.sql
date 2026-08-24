-- إنشاء مستخدم كامل: Supabase Auth + profiles
-- شغّل هذا الملف مرة واحدة في Supabase SQL Editor.

create or replace function public.create_staff_user(
  p_username text,
  p_password text,
  p_full_name text,
  p_role text,
  p_ambulance_id text default null,
  p_hospital_name text default null
) returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  new_user_id uuid := gen_random_uuid();
  encrypted_pw text := crypt(p_password, gen_salt('bf'));
  user_email text := lower(trim(p_username)) || '@ambulance.local';
begin
  if auth.uid() is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    raise exception 'غير مصرح: المدير فقط يستطيع إنشاء المستخدمين';
  end if;

  if trim(p_username) = '' or trim(p_password) = '' or trim(p_full_name) = '' then
    raise exception 'الاسم واسم المستخدم وكلمة المرور مطلوبة';
  end if;

  if p_role not in ('admin','dispatcher','paramedic','hospital','doctor','nurse','employee') then
    raise exception 'الدور غير مسموح';
  end if;

  if exists (select 1 from auth.users where email = user_email) then
    raise exception 'اسم المستخدم موجود بالفعل';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000', new_user_id, 'authenticated', 'authenticated',
    user_email, encrypted_pw,
    now(), '{"provider":"email","providers":["email"]}', '{}',
    now(), now()
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), new_user_id, new_user_id::text,
    jsonb_build_object('sub', new_user_id::text, 'email', user_email),
    'email', now(), now(), now()
  );

  insert into public.profiles (id, username, "fullName", role, "ambulanceId", "hospitalName")
  values (new_user_id, lower(trim(p_username)), trim(p_full_name), p_role, p_ambulance_id, p_hospital_name);

  return new_user_id;
end;
$$;

grant execute on function public.create_staff_user(text, text, text, text, text, text) to authenticated;
