-- M2: clinician link. Clinicians create a clinic and patients; a patient's
-- phone redeems a one-time access code; programs are published as new
-- versions with an audit entry; the starter exercises become a shared library.

-- ---------------------------------------------------------------- columns

alter table public.clinics add column phone text;
alter table public.clinicians add column phone text;

-- slug: the app's own exercise id, so bundled tutorials match server rows.
-- default_dose: the prescription the program builder starts from.
alter table public.exercises
  add column slug text unique,
  add column move_label_en text,
  add column move_label_hi text,
  add column release_label_en text,
  add column release_label_hi text,
  add column default_dose jsonb;

-- The same fields as the app's Prescription, so no tempo string is parsed.
alter table public.program_items
  add column duration_seconds int check (duration_seconds > 0),
  add column per_side boolean not null default false,
  add column move_seconds int not null default 2 check (move_seconds >= 0),
  add column release_seconds int not null default 2 check (release_seconds >= 0),
  add constraint program_items_reps_or_duration check ((reps is null) <> (duration_seconds is null));

alter table public.patients add column access_code_expires_at timestamptz;

-- ---------------------------------------------------------------- code helpers

-- 8 characters from an alphabet without look-alikes (no 0/O, 1/I/L).
create function private.new_access_code()
returns text
language plpgsql volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % length(alphabet)) + 1, 1);
  end loop;
  return code;
end
$$;

-- Codes are compared as hashes; spaces, dashes and case do not matter.
create function private.access_code_hash(p_code text)
returns text
language sql immutable
set search_path = ''
as $$
  select encode(extensions.digest(upper(regexp_replace(p_code, '[^A-Za-z0-9]', '', 'g')), 'sha256'), 'hex')
$$;

create function private.is_anonymous()
returns boolean
language sql stable
set search_path = ''
as $$
  select coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
$$;

revoke execute on function private.new_access_code() from public, anon;
revoke execute on function private.access_code_hash(text) from public, anon;
revoke execute on function private.is_anonymous() from public, anon;

-- ---------------------------------------------------------------- clinician RPCs

-- First sign-in of a clinician: creates their clinic with them as admin.
create function public.create_clinic(p_clinic_name text, p_full_name text, p_phone text default null)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_clinic uuid;
begin
  if v_uid is null or private.is_anonymous() then
    raise exception 'Sign in with a clinician account first.';
  end if;
  if exists (select 1 from public.clinicians where id = v_uid) then
    raise exception 'This account already belongs to a clinic.';
  end if;
  if exists (select 1 from public.patients where auth_user_id = v_uid) then
    raise exception 'Patient accounts cannot create a clinic.';
  end if;
  if coalesce(trim(p_clinic_name), '') = '' or coalesce(trim(p_full_name), '') = '' then
    raise exception 'Clinic name and your name are required.';
  end if;

  insert into public.clinics (name, phone)
  values (trim(p_clinic_name), nullif(trim(p_phone), ''))
  returning id into v_clinic;

  insert into public.clinicians (id, clinic_id, full_name, role, phone)
  values (v_uid, v_clinic, trim(p_full_name), 'admin', nullif(trim(p_phone), ''));

  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id)
  values (v_clinic, v_uid, 'create', 'clinic', v_clinic);
  return v_clinic;
end
$$;

-- Adds a patient and returns their access code. Only the hash is stored, so
-- the code is shown once; reset_patient_code issues a new one.
create function public.create_patient(p_display_name text, p_language text default 'en')
returns table (patient_id uuid, access_code text)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_clinic uuid := private.current_clinic_id();
  v_code text;
  v_id uuid;
begin
  if v_clinic is null then
    raise exception 'Only clinicians can add patients.';
  end if;
  if coalesce(trim(p_display_name), '') = '' then
    raise exception 'Patient name is required.';
  end if;

  loop
    v_code := private.new_access_code();
    exit when not exists (
      select 1 from public.patients p where p.access_code_hash = private.access_code_hash(v_code)
    );
  end loop;

  insert into public.patients (clinic_id, clinician_id, display_name, language, access_code_hash, access_code_expires_at)
  values (v_clinic, auth.uid(), trim(p_display_name), coalesce(p_language, 'en'),
          private.access_code_hash(v_code), now() + interval '30 days')
  returning id into v_id;

  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id)
  values (v_clinic, auth.uid(), 'create', 'patient', v_id);
  return query select v_id, v_code;
end
$$;

-- New code for a new phone; the old phone loses access.
create function public.reset_patient_code(p_patient_id uuid)
returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_code text;
begin
  if not private.patient_in_my_clinic(p_patient_id) then
    raise exception 'Patient not found in your clinic.';
  end if;

  loop
    v_code := private.new_access_code();
    exit when not exists (
      select 1 from public.patients p where p.access_code_hash = private.access_code_hash(v_code)
    );
  end loop;

  update public.patients
  set access_code_hash = private.access_code_hash(v_code),
      access_code_expires_at = now() + interval '30 days',
      auth_user_id = null
  where id = p_patient_id;

  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id)
  values (private.current_clinic_id(), auth.uid(), 'reset_code', 'patient', p_patient_id);
  return v_code;
end
$$;

-- Saves a program as the patient's next version, with its items, in one step.
-- p_items: [{exercise_id, sets, reps, hold_seconds, rest_seconds, duration_seconds,
--            per_side, move_seconds, release_seconds, days_of_week, notes}, ...]
create function public.publish_program(p_patient_id uuid, p_items jsonb, p_notes text default null)
returns table (program_id uuid, version int)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_clinic uuid := private.current_clinic_id();
  v_version int;
  v_program uuid;
begin
  if not private.patient_in_my_clinic(p_patient_id) then
    raise exception 'Patient not found in your clinic.';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A program needs at least one exercise.';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) i
    where not exists (
      select 1 from public.exercises e
      where e.id = (i ->> 'exercise_id')::uuid and (e.clinic_id is null or e.clinic_id = v_clinic)
    )
  ) then
    raise exception 'Unknown exercise in the program.';
  end if;

  select coalesce(max(p.version), 0) + 1 into v_version
  from public.programs p where p.patient_id = p_patient_id;

  insert into public.programs (patient_id, version, starts_on, clinician_notes, created_by)
  values (p_patient_id, v_version, current_date, nullif(trim(p_notes), ''), auth.uid())
  returning id into v_program;

  insert into public.program_items (
    program_id, exercise_id, position, sets, reps, hold_seconds, rest_seconds,
    duration_seconds, per_side, move_seconds, release_seconds, days_of_week, notes)
  select v_program,
         (i ->> 'exercise_id')::uuid,
         ord::int,
         (i ->> 'sets')::int,
         (i ->> 'reps')::int,
         coalesce((i ->> 'hold_seconds')::int, 0),
         coalesce((i ->> 'rest_seconds')::int, 30),
         (i ->> 'duration_seconds')::int,
         coalesce((i ->> 'per_side')::boolean, false),
         coalesce((i ->> 'move_seconds')::int, 2),
         coalesce((i ->> 'release_seconds')::int, 2),
         coalesce(array(select d::int from jsonb_array_elements_text(i -> 'days_of_week') d), '{1,2,3,4,5,6,7}'),
         nullif(trim(i ->> 'notes'), '')
  from jsonb_array_elements(p_items) with ordinality as t(i, ord);

  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id, details)
  values (v_clinic, auth.uid(), 'publish', 'program', v_program,
          jsonb_build_object('patient_id', p_patient_id, 'version', v_version, 'items', jsonb_array_length(p_items)));
  return query select v_program, v_version;
end
$$;

-- ---------------------------------------------------------------- patient RPCs

-- The patient's phone (signed in anonymously) links itself to the patient
-- record. Codes are single use and expire after 30 days.
create function public.redeem_access_code(p_code text)
returns table (patient_id uuid, display_name text, language text)
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_patient public.patients;
begin
  if v_uid is null then
    raise exception 'Sign in first.';
  end if;
  if exists (select 1 from public.clinicians where id = v_uid) then
    raise exception 'Clinician accounts cannot link to a patient.';
  end if;

  select * into v_patient from public.patients p
  where p.access_code_hash = private.access_code_hash(p_code)
    and p.access_code_expires_at > now()
  for update;
  if not found then
    raise exception 'This code is not valid or has expired. Ask your physio for a new one.';
  end if;

  -- A phone follows one patient at a time.
  update public.patients p set auth_user_id = null
  where p.auth_user_id = v_uid and p.id <> v_patient.id;

  update public.patients p
  set auth_user_id = v_uid, access_code_hash = null, access_code_expires_at = null,
      consent_at = coalesce(p.consent_at, now())
  where p.id = v_patient.id;

  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id)
  values (v_patient.clinic_id, v_uid, 'link_device', 'patient', v_patient.id);
  return query select v_patient.id, v_patient.display_name, v_patient.language;
end
$$;

-- Who to call: shown on the safety screen.
create function public.my_care_team()
returns table (clinic_name text, clinic_phone text, clinician_name text, clinician_phone text)
language sql stable security definer
set search_path = ''
as $$
  select c.name, c.phone, cl.full_name, cl.phone
  from public.patients p
  join public.clinics c on c.id = p.clinic_id
  left join public.clinicians cl on cl.id = p.clinician_id
  where p.id = private.current_patient_id()
$$;

-- A patient can erase their record and everything logged under it.
create function public.delete_my_data()
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_patient public.patients;
begin
  select * into v_patient from public.patients p where p.auth_user_id = auth.uid();
  if not found then
    return;
  end if;
  delete from public.patients p where p.id = v_patient.id;
  insert into public.audit_events (clinic_id, actor_id, action, entity, entity_id)
  values (v_patient.clinic_id, auth.uid(), 'delete_by_patient', 'patient', v_patient.id);
end
$$;

-- Only signed-in users may call these; each checks its own role inside.
revoke execute on function public.create_clinic(text, text, text) from public, anon;
revoke execute on function public.create_patient(text, text) from public, anon;
revoke execute on function public.reset_patient_code(uuid) from public, anon;
revoke execute on function public.publish_program(uuid, jsonb, text) from public, anon;
revoke execute on function public.redeem_access_code(text) from public, anon;
revoke execute on function public.my_care_team() from public, anon;
revoke execute on function public.delete_my_data() from public, anon;
grant execute on function public.create_clinic(text, text, text) to authenticated;
grant execute on function public.create_patient(text, text) to authenticated;
grant execute on function public.reset_patient_code(uuid) to authenticated;
grant execute on function public.publish_program(uuid, jsonb, text) to authenticated;
grant execute on function public.redeem_access_code(text) to authenticated;
grant execute on function public.my_care_team() to authenticated;
grant execute on function public.delete_my_data() to authenticated;

-- ---------------------------------------------------------------- shared starter library

insert into public.exercises (slug, title_en, steps_en, body_region, equipment, move_label_en, release_label_en, default_dose)
values
  ($q$wall_squat$q$, $q$Wall squat$q$, array[$q$Stand with your back flat against a wall, feet hip-width apart and about a foot in front of you.$q$, $q$Slowly slide down the wall by bending your knees, only as far as is comfortable.$q$, $q$Keep your knees in line with your second toe.$q$, $q$Hold the position and keep breathing normally.$q$, $q$Slide back up to standing.$q$]::text[], $q$knee$q$, array[$q$wall$q$]::text[], $q$Slide down$q$, $q$Slide up$q$, $q${"sets":2,"reps":10,"hold_seconds":5,"rest_seconds":30,"duration_seconds":null,"per_side":false,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$straight_leg_raise$q$, $q$Straight leg raise$q$, array[$q$Lie on your back. Bend one knee with the foot flat and keep the other leg straight.$q$, $q$Tighten the thigh muscle of the straight leg.$q$, $q$Lift the straight leg until it is level with the bent knee.$q$, $q$Hold, then lower it slowly to the floor.$q$]::text[], $q$knee$q$, array[$q$mat$q$]::text[], $q$Lift$q$, $q$Lower$q$, $q${"sets":2,"reps":10,"hold_seconds":3,"rest_seconds":30,"duration_seconds":null,"per_side":true,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$heel_raise$q$, $q$Heel raise$q$, array[$q$Stand facing a wall or the back of a chair and hold it lightly for balance.$q$, $q$Rise up onto your toes, lifting both heels.$q$, $q$Pause at the top.$q$, $q$Lower your heels slowly back to the floor.$q$]::text[], $q$ankle$q$, array[$q$chair$q$]::text[], $q$Rise up$q$, $q$Lower slowly$q$, $q${"sets":2,"reps":15,"hold_seconds":1,"rest_seconds":30,"duration_seconds":null,"per_side":false,"move_seconds":2,"release_seconds":3}$q$::jsonb),
  ($q$glute_bridge$q$, $q$Glute bridge$q$, array[$q$Lie on your back with your knees bent and feet flat, hip-width apart.$q$, $q$Squeeze your buttocks and lift your hips until your body is straight from shoulders to knees.$q$, $q$Hold without arching your lower back.$q$, $q$Lower your hips slowly.$q$]::text[], $q$hip$q$, array[$q$mat$q$]::text[], $q$Lift hips$q$, $q$Lower$q$, $q${"sets":2,"reps":10,"hold_seconds":5,"rest_seconds":30,"duration_seconds":null,"per_side":false,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$clamshell$q$, $q$Clamshell$q$, array[$q$Lie on your side with your hips and knees bent and your feet together.$q$, $q$Keep your feet touching and lift your top knee.$q$, $q$Do not let your pelvis roll backwards.$q$, $q$Lower the knee slowly.$q$]::text[], $q$hip$q$, array[$q$mat$q$]::text[], $q$Open$q$, $q$Close$q$, $q${"sets":2,"reps":12,"hold_seconds":2,"rest_seconds":30,"duration_seconds":null,"per_side":true,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$quad_set$q$, $q$Thigh tightening (quad set)$q$, array[$q$Sit or lie with your leg straight out in front of you.$q$, $q$Tighten the muscle on the front of your thigh, pressing the back of your knee down.$q$, $q$Hold, then relax completely.$q$]::text[], $q$knee$q$, array[]::text[], $q$Tighten$q$, $q$Relax$q$, $q${"sets":2,"reps":10,"hold_seconds":5,"rest_seconds":20,"duration_seconds":null,"per_side":false,"move_seconds":1,"release_seconds":1}$q$::jsonb),
  ($q$cat_cow$q$, $q$Cat–cow$q$, array[$q$Start on your hands and knees, hands under shoulders and knees under hips.$q$, $q$Round your back up towards the ceiling and tuck your chin.$q$, $q$Then let your back dip gently while you lift your head.$q$, $q$Move slowly and stay within a comfortable range.$q$]::text[], $q$back$q$, array[$q$mat$q$]::text[], $q$Round up$q$, $q$Dip down$q$, $q${"sets":2,"reps":10,"hold_seconds":0,"rest_seconds":30,"duration_seconds":null,"per_side":false,"move_seconds":3,"release_seconds":3}$q$::jsonb),
  ($q$chin_tuck$q$, $q$Chin tuck$q$, array[$q$Sit or stand tall and look straight ahead.$q$, $q$Gently draw your chin straight back, as if making a double chin.$q$, $q$Keep your eyes level; do not tip your head down.$q$, $q$Hold, then relax.$q$]::text[], $q$neck$q$, array[]::text[], $q$Tuck$q$, $q$Relax$q$, $q${"sets":2,"reps":10,"hold_seconds":5,"rest_seconds":20,"duration_seconds":null,"per_side":false,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$pendulum$q$, $q$Shoulder pendulum$q$, array[$q$Lean forward and support yourself with your good arm on a table.$q$, $q$Let the other arm hang down loosely.$q$, $q$Gently sway your body so the arm swings in small circles.$q$, $q$Keep the arm and shoulder relaxed the whole time.$q$]::text[], $q$shoulder$q$, array[$q$table$q$]::text[], null, null, $q${"sets":3,"reps":null,"hold_seconds":0,"rest_seconds":20,"duration_seconds":30,"per_side":false,"move_seconds":2,"release_seconds":2}$q$::jsonb),
  ($q$calf_stretch$q$, $q$Calf stretch$q$, array[$q$Stand facing a wall with both hands on it.$q$, $q$Step one foot back, keeping that leg straight and the heel on the floor.$q$, $q$Bend the front knee and lean forward until you feel a stretch in the back calf.$q$, $q$Hold still without bouncing.$q$]::text[], $q$ankle$q$, array[$q$wall$q$]::text[], null, null, $q${"sets":3,"reps":null,"hold_seconds":0,"rest_seconds":15,"duration_seconds":30,"per_side":true,"move_seconds":2,"release_seconds":2}$q$::jsonb);
