-- Move the row-level-security helpers out of the API-exposed public schema.
-- Postgres grants EXECUTE to PUBLIC by default, so the earlier revoke from anon
-- still left them callable at /rest/v1/rpc/*. Policies keep working: they
-- reference the functions by id, not by name.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

alter function public.current_clinic_id() set schema private;
alter function public.current_patient_id() set schema private;
alter function public.patient_in_my_clinic(uuid) set schema private;

-- SQL function bodies resolve names at run time, so point this one at the new schema.
create or replace function private.patient_in_my_clinic(p_patient_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.patients
    where id = p_patient_id and clinic_id = private.current_clinic_id()
  )
$$;

revoke execute on function private.current_clinic_id() from public, anon;
revoke execute on function private.current_patient_id() from public, anon;
revoke execute on function private.patient_in_my_clinic(uuid) from public, anon;

grant execute on function private.current_clinic_id() to authenticated;
grant execute on function private.current_patient_id() to authenticated;
grant execute on function private.patient_in_my_clinic(uuid) to authenticated;
