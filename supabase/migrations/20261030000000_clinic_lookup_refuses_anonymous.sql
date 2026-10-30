-- Anonymous sign-in is on for patient phones (Auth settings, 2026-10-30), so
-- every policy for the authenticated role also applies to anonymous users.
-- Clinician access already needs a clinicians row, which only create_clinic
-- makes, and it refuses anonymous users. As a second lock, the clinic lookup
-- behind every clinician policy (directly or via patient_in_my_clinic) now
-- refuses them too.

create or replace function private.current_clinic_id()
returns uuid
language sql stable security definer
set search_path = ''
as $$
  select c.clinic_id from public.clinicians c
  where c.id = (select auth.uid()) and not private.is_anonymous()
$$;
