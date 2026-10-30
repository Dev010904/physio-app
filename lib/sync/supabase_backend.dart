import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local_store.dart';
import '../program/program_controller.dart';

/// The clinic server: Supabase with the M2 functions
/// (supabase/migrations/20261025000000_clinic_link.sql).
class SupabaseBackend implements ProgramBackend {
  SupabaseBackend(this._client);

  final SupabaseClient _client;

  static const _programColumns =
      'id, version, clinician_notes, program_items(id, position, sets, reps, hold_seconds, rest_seconds, '
      'duration_seconds, per_side, move_seconds, release_seconds, days_of_week, notes, '
      'exercises(id, slug, title_en, title_hi, steps_en, steps_hi, body_region, equipment, '
      'move_label_en, move_label_hi, release_label_en, release_label_hi))';

  @override
  Future<CareLink> link(String code) async {
    // Patients have no email or password: the phone signs in anonymously and
    // the access code ties that sign-in to their record.
    if (_client.auth.currentUser == null) await _client.auth.signInAnonymously();
    try {
      final rows = await _client.rpc('redeem_access_code', params: {'p_code': code}) as List;
      final patient = rows.single as Map<String, dynamic>;
      final team = (await _client.rpc('my_care_team') as List).cast<Map<String, dynamic>>();
      final t = team.isEmpty ? const <String, dynamic>{} : team.first;
      return CareLink(
        patientId: patient['patient_id'] as String,
        displayName: patient['display_name'] as String,
        language: patient['language'] as String? ?? 'en',
        clinicName: t['clinic_name'] as String?,
        clinicPhone: t['clinic_phone'] as String?,
        clinicianName: t['clinician_name'] as String?,
        clinicianPhone: t['clinician_phone'] as String?,
      );
    } on PostgrestException catch (e) {
      throw LinkException(e.message);
    }
  }

  @override
  Future<void> deleteMyData() async {
    // Removes the patient row; the database deletes their logs and programs with it.
    await _client.rpc('delete_my_data');
    await _client.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> latestProgram() => _client
      .from('programs')
      .select(_programColumns)
      .order('version', ascending: false)
      .limit(1)
      .maybeSingle();

  @override
  Future<void> push(String patientId, List<SessionRecord> sessions, List<FlagRecord> flags) async {
    String day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (sessions.isNotEmpty) {
      await _client.from('session_logs').upsert([
        for (final s in sessions)
          {
            'id': s.id,
            'patient_id': patientId,
            'program_id': s.programId,
            'performed_on': day(s.performedOn),
            'started_at': s.startedAt.toUtc().toIso8601String(),
            'feedback': s.feedback,
          },
      ], onConflict: 'id', ignoreDuplicates: true);
      final exercises = [
        for (final s in sessions)
          for (final e in s.exercises)
            if (e.itemId != null)
              {
                'id': e.id,
                'session_id': s.id,
                'program_item_id': e.itemId,
                'sets_done': e.setsDone,
                'reps_done': e.repsDone,
                'rep_source': e.repSource,
                'peak_angle_deg': e.peakAngle,
                'pain_0_10': e.pain,
                // Private notes stay on the phone unless the patient shares them.
                'shared_note': e.shareNote ? e.note : null,
              },
      ];
      if (exercises.isNotEmpty) {
        await _client.from('exercise_logs').upsert(exercises, onConflict: 'id', ignoreDuplicates: true);
      }
    }
    if (flags.isNotEmpty) {
      await _client.from('flags').upsert([
        for (final f in flags)
          {'id': f.id, 'patient_id': patientId, 'reason': f.reason, 'details': f.details, 'created_at': f.createdAt.toUtc().toIso8601String()},
      ], onConflict: 'id', ignoreDuplicates: true);
    }
  }
}

/// A code the server did not accept, with its message for the patient.
class LinkException implements Exception {
  const LinkException(this.message);

  final String message;

  @override
  String toString() => message;
}
