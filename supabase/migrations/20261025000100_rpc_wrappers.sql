-- Keep the SECURITY DEFINER bodies out of the API schema (Supabase lint 0029).
-- The API keeps the same function names as thin SECURITY INVOKER wrappers;
-- each body still checks who is calling before it touches anything.

alter function public.create_clinic(text, text, text) set schema private;
alter function public.create_patient(text, text) set schema private;
alter function public.reset_patient_code(uuid) set schema private;
alter function public.publish_program(uuid, jsonb, text) set schema private;
alter function public.redeem_access_code(text) set schema private;
alter function public.my_care_team() set schema private;
alter function public.delete_my_data() set schema private;

create function public.create_clinic(p_clinic_name text, p_full_name text, p_phone text default null)
returns uuid
language sql security invoker
set search_path = ''
as $$ select private.create_clinic(p_clinic_name, p_full_name, p_phone) $$;

create function public.create_patient(p_display_name text, p_language text default 'en')
returns table (patient_id uuid, access_code text)
language sql security invoker
set search_path = ''
as $$ select * from private.create_patient(p_display_name, p_language) $$;

create function public.reset_patient_code(p_patient_id uuid)
returns text
language sql security invoker
set search_path = ''
as $$ select private.reset_patient_code(p_patient_id) $$;

create function public.publish_program(p_patient_id uuid, p_items jsonb, p_notes text default null)
returns table (program_id uuid, version int)
language sql security invoker
set search_path = ''
as $$ select * from private.publish_program(p_patient_id, p_items, p_notes) $$;

create function public.redeem_access_code(p_code text)
returns table (patient_id uuid, display_name text, language text)
language sql security invoker
set search_path = ''
as $$ select * from private.redeem_access_code(p_code) $$;

create function public.my_care_team()
returns table (clinic_name text, clinic_phone text, clinician_name text, clinician_phone text)
language sql stable security invoker
set search_path = ''
as $$ select * from private.my_care_team() $$;

create function public.delete_my_data()
returns void
language sql security invoker
set search_path = ''
as $$ select private.delete_my_data() $$;

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
