-- The phone sends safety flags as "insert, or skip if this id is already
-- there" (on conflict do nothing), so a retry after a dropped connection never
-- duplicates them. Postgres only allows that when the sender may also read the
-- table, and patients had no read policy on flags. Their sessions synced
-- but the flag itself was refused (found in the end-to-end test, 2026-10-30).
-- Patients may now read their own flags, as they already read their own sessions.

create policy "patients read own flags" on public.flags
  for select to authenticated
  using (patient_id = (select private.current_patient_id()));
