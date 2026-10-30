import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic/adherence.dart';
import '../logic/dose.dart';
import 'models.dart';

/// Every call the dashboard makes to the clinic server
/// (supabase/migrations/20261025000000_clinic_link.sql). Row-level security
/// keeps each query inside the signed-in clinician's clinic.
class ClinicApi {
  ClinicApi(this.client, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final SupabaseClient client;
  final DateTime Function() _clock;

  String? get userId => client.auth.currentUser?.id;

  static String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ------------------------------------------------------------ clinic

  /// The clinician row for the signed-in account; null before the clinic is created.
  Future<Clinician?> me() async {
    final uid = userId;
    if (uid == null) return null;
    final row = await client.from('clinicians').select('id, clinic_id, full_name, role, clinics(name)').eq('id', uid).maybeSingle();
    return row == null ? null : Clinician.fromRow(row);
  }

  Future<void> createClinic({required String clinicName, required String fullName, String? phone}) => client.rpc(
    'create_clinic',
    params: {'p_clinic_name': clinicName.trim(), 'p_full_name': fullName.trim(), 'p_phone': phone?.trim()},
  );

  // ------------------------------------------------------------ patients

  /// Patients with what the list shows: link status, last session, open flags
  /// and the schedule, so missed days can be worked out here.
  Future<List<PatientSummary>> patients() async {
    final today = Adherence.dateOnly(_clock());
    final since = DateTime(today.year, today.month, today.day - 27);
    final results = await Future.wait([
      client
          .from('patients')
          .select(
            '${PatientRow.columns}, session_logs(performed_on), flags(id, status), '
            'programs(version, created_at, program_items(days_of_week))',
          )
          .eq('flags.status', 'open')
          .order('performed_on', referencedTable: 'session_logs', ascending: false)
          .limit(1, referencedTable: 'session_logs')
          .order('display_name'),
      client.from('session_logs').select('patient_id, performed_on').gte('performed_on', _day(since)),
    ]);
    final rows = results[0];
    final recent = <String, List<DateTime>>{};
    for (final s in results[1]) {
      recent.putIfAbsent(s['patient_id'] as String, () => []).add(DateTime.parse(s['performed_on'] as String));
    }
    return [
      for (final r in rows)
        () {
          final patient = PatientRow.fromRow(r);
          final last = (r['session_logs'] as List).cast<Map<String, dynamic>>();
          final lastDay = last.isEmpty ? null : DateTime.parse(last.first['performed_on'] as String);
          final programs = (r['programs'] as List).cast<Map<String, dynamic>>();
          final versions = [
            for (final p in programs)
              ScheduleVersion(
                startsOn: Adherence.dateOnly(DateTime.parse(p['created_at'] as String).toLocal()),
                weekdays: {
                  for (final i in (p['program_items'] as List).cast<Map<String, dynamic>>())
                    ...(i['days_of_week'] as List).cast<int>(),
                },
              ),
          ];
          return PatientSummary(
            patient: patient,
            lastSession: lastDay,
            openFlags: (r['flags'] as List).length,
            hasProgram: programs.isNotEmpty,
            // The last session, even if older than the window, ends a missed run.
            adherence: Adherence(
              versions: versions,
              sessionDays: [...?recent[patient.id], ?lastDay],
              linkedOn: patient.linkedAt,
              today: today,
            ),
          );
        }(),
    ];
  }

  Future<PatientRow> patient(String id) async =>
      PatientRow.fromRow(await client.from('patients').select(PatientRow.columns).eq('id', id).single());

  /// Adds a patient. The code comes back once; only its hash is stored.
  Future<({String patientId, String code})> createPatient({required String name, required String language}) async {
    final rows = await client.rpc('create_patient', params: {'p_display_name': name.trim(), 'p_language': language}) as List;
    final row = rows.single as Map<String, dynamic>;
    return (patientId: row['patient_id'] as String, code: row['access_code'] as String);
  }

  /// A new code for a new phone; the old phone stops getting updates.
  Future<String> resetCode(String patientId) async =>
      await client.rpc('reset_patient_code', params: {'p_patient_id': patientId}) as String;

  // ------------------------------------------------------------ programs

  Future<List<LibraryExercise>> library() async {
    final rows = await client.from('exercises').select(LibraryExercise.columns).order('title_en');
    return [for (final r in rows) LibraryExercise.fromRow(r)];
  }

  Future<ProgramVersion?> latestProgram(String patientId) async {
    final row = await client
        .from('programs')
        .select(ProgramVersion.columns)
        .eq('patient_id', patientId)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : ProgramVersion.fromRow(row);
  }

  /// Publishes [items] as the patient's next version and returns its number.
  Future<int> publish({required String patientId, required List<ItemDraft> items, String? notes}) async {
    final rows = await client.rpc(
      'publish_program',
      params: {'p_patient_id': patientId, 'p_items': programItemsJson(items), 'p_notes': notes?.trim()},
    ) as List;
    return (rows.single as Map<String, dynamic>)['version'] as int;
  }

  // ------------------------------------------------------------ patient page

  Future<PatientDetail> patientDetail(String patientId) async {
    final results = await Future.wait<Object>([
      patient(patientId),
      client.from('programs').select(ProgramVersion.columns).eq('patient_id', patientId).order('version', ascending: false),
      client
          .from('session_logs')
          .select(SessionEntry.columns)
          .eq('patient_id', patientId)
          .order('performed_on', ascending: false)
          .order('started_at', ascending: false)
          .limit(200),
      client.from('flags').select(FlagEntry.columns).eq('patient_id', patientId).order('created_at', ascending: false),
    ]);
    List<Map<String, dynamic>> rows(int i) => (results[i] as List).cast<Map<String, dynamic>>();
    return PatientDetail(
      patient: results[0] as PatientRow,
      programs: [for (final r in rows(1)) ProgramVersion.fromRow(r)],
      sessions: [for (final r in rows(2)) SessionEntry.fromRow(r)],
      flags: [for (final r in rows(3)) FlagEntry.fromRow(r)],
      today: _clock(),
    );
  }

  /// Marks a flag handled and notes it in the clinic's audit log.
  Future<void> resolveFlag({required FlagEntry flag, required String patientId, required String clinicId}) async {
    final updated = await client
        .from('flags')
        .update({'status': 'resolved', 'resolved_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', flag.id)
        .select('id');
    if (updated.isEmpty) throw const PostgrestException(message: 'This flag could not be changed.', code: 'not_found');
    await client.from('audit_events').insert({
      'clinic_id': clinicId,
      'actor_id': userId,
      'action': 'resolve',
      'entity': 'flag',
      'entity_id': flag.id,
      'details': {'patient_id': patientId, 'reason': flag.reason},
    });
  }
}
