/// Small text helpers shared by the screens.
library;

/// The patient's end-of-session answer.
enum FeedbackLevel {
  easy('Easy'),
  ok('OK'),
  hard('Hard');

  const FeedbackLevel(this.label);

  final String label;
}

/// session_logs.feedback, stored as "easy|ok|hard[: text]".
class SessionFeedback {
  const SessionFeedback({this.level, this.text});

  /// Null when the stored value does not start with a known level.
  final FeedbackLevel? level;
  final String? text;

  static SessionFeedback? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final colon = value.indexOf(':');
    final head = (colon < 0 ? value : value.substring(0, colon)).trim().toLowerCase();
    final rest = colon < 0 ? null : value.substring(colon + 1).trim();
    final level = FeedbackLevel.values.where((l) => l.name == head).firstOrNull;
    if (level == null) return SessionFeedback(text: value);
    return SessionFeedback(level: level, text: (rest?.isEmpty ?? true) ? null : rest);
  }
}

/// "ABCD-EF23": the code as the patient types it, easier to read aloud.
String formatAccessCode(String code) {
  final c = code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return c.length == 8 ? '${c.substring(0, 4)}-${c.substring(4)}' : c;
}

/// What the clinician sends on WhatsApp or SMS with a new code.
String shareMessage(String code) =>
    'Your PhysioSathi code is ${formatAccessCode(code)}. '
    "Open the app, tap 'Have a code from your physio?', and enter it. "
    'It works for 30 days.';

Uri whatsAppUri(String message) => Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

// Built by hand: Uri(queryParameters:) turns spaces into "+", which some SMS
// apps show as is.
Uri smsUri(String message) => Uri.parse('sms:?body=${Uri.encodeComponent(message)}');

/// "1 set", "2 sets"; [many] for irregular words.
String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : many ?? '${one}s'}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Mon 20 Oct".
String dayLabel(DateTime d) => '${weekdayShort[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "Today", "Yesterday", "3 days ago", then "12 Oct" (with the year if not this one).
/// [inSentence] gives "today", "yesterday", "3 days ago" and "on 12 Oct", to
/// follow words like "Published".
String relativeDay(DateTime day, DateTime now, {bool inSentence = false}) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(now.year, now.month, now.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return inSentence ? 'today' : 'Today';
  if (diff == 1) return inSentence ? 'yesterday' : 'Yesterday';
  if (diff > 1 && diff < 7) return '$diff days ago';
  final base = '${d.day} ${_months[d.month - 1]}${d.year == t.year ? '' : ' ${d.year}'}';
  return inSentence ? 'on $base' : base;
}

/// "12 Oct 2026, 4:05 pm".
String dateTimeLabel(DateTime t) {
  final l = t.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_months[l.month - 1]} ${l.year}, $h:$m ${l.hour < 12 ? 'am' : 'pm'}';
}

/// "about 4 min", rounded up so the estimate is never short.
String minutesLabel(Duration d) => d == Duration.zero ? 'rest day' : 'about ${(d.inSeconds / 60).ceil()} min';

/// "Mon–Fri", "Mon, Wed, Fri", "Every day".
String daysLabel(Set<int> days) {
  final sorted = days.toList()..sort();
  if (sorted.length == 7) return 'Every day';
  if (sorted.isEmpty) return 'No days';
  final contiguous = sorted.length > 2 && sorted.last - sorted.first == sorted.length - 1;
  if (contiguous) return '${weekdayShort[sorted.first - 1]}–${weekdayShort[sorted.last - 1]}';
  return sorted.map((d) => weekdayShort[d - 1]).join(', ');
}

/// "Asha K." → "AK".
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  String first(String p) => String.fromCharCode(p.runes.first);
  return '${first(parts.first)}${parts.length > 1 ? first(parts.last) : ''}'.toUpperCase();
}

/// Plain words for a flag's reason.
String flagReasonLabel(String reason) => switch (reason) {
  'high_pain' => 'High pain',
  'red_flag' => 'Warning sign',
  'missed_days' => 'Missed days',
  _ => reason,
};

/// Plain words for a flag's details, as the patient app writes them.
String flagDetailsLabel(String reason, Map<String, dynamic> details, {String? Function(String slug)? exerciseTitle}) {
  final slug = details['exercise'] as String?;
  final exercise = slug == null ? null : (exerciseTitle?.call(slug) ?? slug.replaceAll('_', ' '));
  final where = exercise == null ? '' : ' during $exercise';
  switch (reason) {
    case 'high_pain':
      final pain = details['pain'];
      return pain == null ? 'Reported high pain$where.' : 'Pain $pain out of 10$where.';
    case 'red_flag':
      final symptom = switch (details['symptom']) {
        'chestPain' => 'Chest pain or tightness',
        'numbness' => 'Numbness, tingling or weakness',
        'severePain' => 'Sudden severe pain',
        'fall' => 'A fall, or feeling faint or dizzy',
        final String other => other,
        _ => 'A warning sign',
      };
      return '$symptom$where.';
    case 'missed_days':
      final days = details['days'];
      return days is int ? '${plural(days, 'scheduled day')} missed in a row.' : 'Several scheduled days were missed.';
    default:
      return details.isEmpty ? '' : details.toString();
  }
}
