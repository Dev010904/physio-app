-- Initial schema for the physio app (spec: "Data model").
-- Every table has row-level security: clinicians see only their clinic,
-- patients see only their own rows. Camera frames and AI chats are never stored.

-- ---------------------------------------------------------------- tables

create table public.clinics (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  country     text not null default 'IN',
  created_at  timestamptz not null default now()
);

create table public.clinicians (
  id          uuid primary key references auth.users (id) on delete cascade,
  clinic_id   uuid not null references public.clinics (id) on delete cascade,
  full_name   text not null,
  role        text not null default 'physio' check (role in ('physio', 'admin')),
  created_at  timestamptz not null default now()
);

create table public.patients (
  id                uuid primary key default gen_random_uuid(),
  clinic_id         uuid not null references public.clinics (id) on delete cascade,
  clinician_id      uuid references public.clinicians (id) on delete set null,
  auth_user_id      uuid unique references auth.users (id) on delete set null,
  display_name      text not null,
  language          text not null default 'en' check (language in ('en', 'hi')),
  access_code_hash  text unique,
  consent_at        timestamptz,
  created_at        timestamptz not null default now()
);

-- clinic_id null = shared starter library visible to every clinic.
create table public.exercises (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid references public.clinics (id) on delete cascade,
  title_en     text not null,
  title_hi     text,
  steps_en     text[] not null default '{}',
  steps_hi     text[] not null default '{}',
  video_path   text,
  image_paths  text[] not null default '{}',
  body_region  text,
  equipment    text[] not null default '{}',
  camera_rule  jsonb,
  created_at   timestamptz not null default now()
);

create table public.programs (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients (id) on delete cascade,
  version          int not null default 1 check (version > 0),
  starts_on        date,
  ends_on          date,
  clinician_notes  text,
  created_by       uuid references public.clinicians (id) on delete set null,
  created_at       timestamptz not null default now(),
  unique (patient_id, version)
);

create table public.program_items (
  id            uuid primary key default gen_random_uuid(),
  program_id    uuid not null references public.programs (id) on delete cascade,
  exercise_id   uuid not null references public.exercises (id),
  position      int not null,
  sets          int not null check (sets > 0),
  reps          int check (reps > 0),
  hold_seconds  int check (hold_seconds >= 0),
  rest_seconds  int not null default 30 check (rest_seconds >= 0),
  tempo         text,
  days_of_week  int[] not null default '{1,2,3,4,5,6,7}',
  notes         text,
  unique (program_id, position)
);

-- Logs are append-only and their ids are generated on the phone, so offline
-- devices can sync later without conflicts.
create table public.session_logs (
  id            uuid primary key,
  patient_id    uuid not null references public.patients (id) on delete cascade,
  program_id    uuid not null references public.programs (id) on delete cascade,
  performed_on  date not null,
  started_at    timestamptz,
  feedback      text,
  created_at    timestamptz not null default now()
);

create table public.exercise_logs (
  id               uuid primary key,
  session_id       uuid not null references public.session_logs (id) on delete cascade,
  program_item_id  uuid not null references public.program_items (id) on delete cascade,
  sets_done        int not null default 0 check (sets_done >= 0),
  reps_done        int check (reps_done >= 0),
  rep_source       text not null default 'manual' check (rep_source in ('manual', 'camera')),
  peak_angle_deg   numeric(5, 1),
  pain_0_10        int check (pain_0_10 between 0 and 10),
  shared_note      text,
  created_at       timestamptz not null default now()
);

create table public.flags (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid not null references public.patients (id) on delete cascade,
  reason       text not null check (reason in ('high_pain', 'red_flag', 'missed_days')),
  details      jsonb not null default '{}',
  status       text not null default 'open' check (status in ('open', 'resolved')),
  created_at   timestamptz not null default now(),
  resolved_at  timestamptz
);

create table public.audit_events (
  id          bigint generated always as identity primary key,
  clinic_id   uuid not null references public.clinics (id) on delete cascade,
  actor_id    uuid,
  action      text not null,
  entity      text not null,
  entity_id   uuid,
  details     jsonb not null default '{}',
  created_at  timestamptz not null default now()
);

-- Foreign-key indexes used by the policies below.
create index on public.clinicians (clinic_id);
create index on public.patients (clinic_id);
create index on public.patients (clinician_id);
create index on public.exercises (clinic_id);
create index on public.programs (created_by);
create index on public.program_items (exercise_id);
create index on public.session_logs (patient_id);
create index on public.session_logs (program_id);
create index on public.exercise_logs (session_id);
create index on public.exercise_logs (program_item_id);
create index on public.flags (patient_id);
create index on public.audit_events (clinic_id);

-- ---------------------------------------------------------------- helpers

create function public.current_clinic_id()
returns uuid
language sql stable security definer
set search_path = ''
as $$
  select clinic_id from public.clinicians where id = (select auth.uid())
$$;

create function public.current_patient_id()
returns uuid
language sql stable security definer
set search_path = ''
as $$
  select id from public.patients where auth_user_id = (select auth.uid())
$$;

create function public.patient_in_my_clinic(p_patient_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.patients
    where id = p_patient_id and clinic_id = public.current_clinic_id()
  )
$$;

revoke execute on function public.current_clinic_id() from anon;
revoke execute on function public.current_patient_id() from anon;
revoke execute on function public.patient_in_my_clinic(uuid) from anon;

-- ---------------------------------------------------------------- row-level security

alter table public.clinics       enable row level security;
alter table public.clinicians    enable row level security;
alter table public.patients      enable row level security;
alter table public.exercises     enable row level security;
alter table public.programs      enable row level security;
alter table public.program_items enable row level security;
alter table public.session_logs  enable row level security;
alter table public.exercise_logs enable row level security;
alter table public.flags         enable row level security;
alter table public.audit_events  enable row level security;

-- Clinics and clinicians
create policy "clinicians read their clinic" on public.clinics
  for select to authenticated using (id = (select public.current_clinic_id()));

create policy "clinicians read colleagues" on public.clinicians
  for select to authenticated using (clinic_id = (select public.current_clinic_id()));

create policy "clinicians update themselves" on public.clinicians
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()) and clinic_id = (select public.current_clinic_id()));

-- Patients
create policy "clinicians manage their clinic's patients" on public.patients
  for all to authenticated
  using (clinic_id = (select public.current_clinic_id()))
  with check (clinic_id = (select public.current_clinic_id()));

create policy "patients read themselves" on public.patients
  for select to authenticated using (auth_user_id = (select auth.uid()));

-- Exercise library
create policy "read shared and own-clinic exercises" on public.exercises
  for select to authenticated using (
    clinic_id is null
    or clinic_id = (select public.current_clinic_id())
    or clinic_id = (select clinic_id from public.patients where id = (select public.current_patient_id()))
  );

create policy "clinicians manage own-clinic exercises" on public.exercises
  for all to authenticated
  using (clinic_id = (select public.current_clinic_id()))
  with check (clinic_id = (select public.current_clinic_id()));

-- Programs
create policy "clinicians manage programs" on public.programs
  for all to authenticated
  using (public.patient_in_my_clinic(patient_id))
  with check (public.patient_in_my_clinic(patient_id));

create policy "patients read own programs" on public.programs
  for select to authenticated using (patient_id = (select public.current_patient_id()));

create policy "clinicians manage program items" on public.program_items
  for all to authenticated
  using (exists (select 1 from public.programs p where p.id = program_id and public.patient_in_my_clinic(p.patient_id)))
  with check (exists (select 1 from public.programs p where p.id = program_id and public.patient_in_my_clinic(p.patient_id)));

create policy "patients read own program items" on public.program_items
  for select to authenticated
  using (exists (select 1 from public.programs p where p.id = program_id and p.patient_id = (select public.current_patient_id())));

-- Logs: patients append, clinicians read
create policy "patients add own sessions" on public.session_logs
  for insert to authenticated with check (patient_id = (select public.current_patient_id()));

create policy "patients read own sessions" on public.session_logs
  for select to authenticated using (patient_id = (select public.current_patient_id()));

create policy "clinicians read sessions" on public.session_logs
  for select to authenticated using (public.patient_in_my_clinic(patient_id));

create policy "patients add own exercise logs" on public.exercise_logs
  for insert to authenticated
  with check (exists (select 1 from public.session_logs s where s.id = session_id and s.patient_id = (select public.current_patient_id())));

create policy "patients read own exercise logs" on public.exercise_logs
  for select to authenticated
  using (exists (select 1 from public.session_logs s where s.id = session_id and s.patient_id = (select public.current_patient_id())));

create policy "clinicians read exercise logs" on public.exercise_logs
  for select to authenticated
  using (exists (select 1 from public.session_logs s where s.id = session_id and public.patient_in_my_clinic(s.patient_id)));

-- Flags: raised by the patient's app, handled by the clinician
create policy "patients raise own flags" on public.flags
  for insert to authenticated with check (patient_id = (select public.current_patient_id()));

create policy "clinicians read flags" on public.flags
  for select to authenticated using (public.patient_in_my_clinic(patient_id));

create policy "clinicians resolve flags" on public.flags
  for update to authenticated
  using (public.patient_in_my_clinic(patient_id))
  with check (public.patient_in_my_clinic(patient_id));

-- Audit log: clinicians read their clinic's history and append to it
create policy "clinicians read audit log" on public.audit_events
  for select to authenticated using (clinic_id = (select public.current_clinic_id()));

create policy "clinicians append audit log" on public.audit_events
  for insert to authenticated
  with check (clinic_id = (select public.current_clinic_id()) and actor_id = (select auth.uid()));
