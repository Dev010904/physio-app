import 'package:clinician_web/logic/text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('session feedback', () {
    test('level alone', () {
      final f = SessionFeedback.parse('easy')!;
      expect((f.level, f.text), (FeedbackLevel.easy, null));
    });

    test('level with text', () {
      final f = SessionFeedback.parse('hard: knee felt stiff: after stairs')!;
      expect(f.level, FeedbackLevel.hard);
      expect(f.text, 'knee felt stiff: after stairs');
    });

    test('case and spaces do not matter', () => expect(SessionFeedback.parse('  OK ')!.level, FeedbackLevel.ok));

    test('unknown values keep their text', () {
      final f = SessionFeedback.parse('great day')!;
      expect((f.level, f.text), (null, 'great day'));
    });

    test('empty is nothing', () {
      expect(SessionFeedback.parse(null), isNull);
      expect(SessionFeedback.parse('  '), isNull);
    });
  });

  group('access code', () {
    test('shown as two groups of four', () {
      expect(formatAccessCode('abcd2345'), 'ABCD-2345');
      expect(formatAccessCode('AB CD-23 45'), 'ABCD-2345');
    });

    test('the share message has the code and the app steps', () {
      expect(
        shareMessage('ABCD2345'),
        "Your PhysioSathi code is ABCD-2345. Open the app, tap 'Have a code from your physio?', and enter it. It works for 30 days.",
      );
    });

    test('WhatsApp and SMS links carry the message', () {
      final m = shareMessage('ABCD2345');
      expect(whatsAppUri(m).host, 'wa.me');
      expect(whatsAppUri(m).queryParameters['text'], m);
      expect(smsUri(m).toString(), startsWith('sms:?body=Your%20PhysioSathi'));
      expect(smsUri(m).toString(), isNot(contains('+')));
    });
  });

  group('labels', () {
    test('days', () {
      expect(daysLabel({1, 2, 3, 4, 5, 6, 7}), 'Every day');
      expect(daysLabel({1, 2, 3, 4, 5}), 'Mon–Fri');
      expect(daysLabel({5, 1, 3}), 'Mon, Wed, Fri');
      expect(daysLabel({6, 7}), 'Sat, Sun');
    });

    test('relative days', () {
      final now = DateTime(2026, 10, 25, 9);
      expect(relativeDay(DateTime(2026, 10, 25, 23), now), 'Today');
      expect(relativeDay(DateTime(2026, 10, 24), now), 'Yesterday');
      expect(relativeDay(DateTime(2026, 10, 21), now), '4 days ago');
      expect(relativeDay(DateTime(2026, 10, 12), now), '12 Oct');
      expect(relativeDay(DateTime(2025, 12, 31), now), '31 Dec 2025');
    });

    test('relative days inside a sentence', () {
      final now = DateTime(2026, 10, 25, 9);
      expect('Published ${relativeDay(DateTime(2026, 10, 25), now, inSentence: true)}', 'Published today');
      expect('Published ${relativeDay(DateTime(2026, 10, 24), now, inSentence: true)}', 'Published yesterday');
      expect('Published ${relativeDay(DateTime(2026, 10, 22), now, inSentence: true)}', 'Published 3 days ago');
      expect('Published ${relativeDay(DateTime(2026, 10, 12), now, inSentence: true)}', 'Published on 12 Oct');
      expect('Published ${relativeDay(DateTime(2025, 12, 31), now, inSentence: true)}', 'Published on 31 Dec 2025');
    });

    test('minutes round up', () {
      expect(minutesLabel(const Duration(seconds: 61)), 'about 2 min');
      expect(minutesLabel(Duration.zero), 'rest day');
    });

    test('initials', () {
      expect(initials('Asha Kumar'), 'AK');
      expect(initials('  meera  '), 'M');
      expect(initials(''), '?');
    });

    test('flag details in plain words', () {
      expect(flagDetailsLabel('high_pain', {'pain': 8, 'exercise': 'wall_squat'}, exerciseTitle: (_) => 'Wall squat'), 'Pain 8 out of 10 during Wall squat.');
      expect(flagDetailsLabel('red_flag', {'symptom': 'chestPain'}), 'Chest pain or tightness.');
      expect(flagDetailsLabel('missed_days', {'days': 1}), '1 scheduled day missed in a row.');
      expect(flagDetailsLabel('missed_days', {'days': 4}), '4 scheduled days missed in a row.');
    });

    test('plurals', () {
      expect(plural(1, 'set'), '1 set');
      expect(plural(0, 'set'), '0 sets');
      expect(plural(3, 'scheduled day'), '3 scheduled days');
      expect(plural(2, 'person', 'people'), '2 people');
      expect(flagDetailsLabel('high_pain', {'pain': 9, 'exercise': 'heel_raise'}), 'Pain 9 out of 10 during heel raise.');
    });
  });
}
