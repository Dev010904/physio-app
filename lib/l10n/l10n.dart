import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../exercises/exercise.dart';
import '../session/session_log.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The app's current language code: 'en' or 'hi'.
  String get lang => Localizations.localeOf(this).languageCode;
}

/// "2 sets × 10 reps · hold 5 s · each side · rest 30 s", in the app's language.
String doseSummary(AppLocalizations l, Prescription rx) => [
  rx.isTimed ? l.doseSetsTime(rx.sets, rx.durationSeconds!) : l.doseSetsReps(rx.sets, rx.reps!),
  if (!rx.isTimed && rx.holdSeconds > 0) l.doseHold(rx.holdSeconds),
  if (rx.perSide) l.doseEachSide,
  l.doseRest(rx.restSeconds),
].join(' · ');

/// "about 4 min" for planning; rounds up so the estimate is never short.
String aboutMinutes(AppLocalizations l, Duration d) => l.aboutMinutes((d.inSeconds / 60).ceil());

/// "Monday" or "सोमवार".
String weekdayName(BuildContext context, DateTime day) => DateFormat.EEEE(context.lang).format(day);

/// "26 Oct" or "26 अक्टू॰".
String dayAndMonth(BuildContext context, DateTime day) => DateFormat.MMMd(context.lang).format(day);

String redFlagLabel(AppLocalizations l, RedFlag flag) => switch (flag) {
  RedFlag.chestPain => l.flagChestPain,
  RedFlag.numbness => l.flagNumbness,
  RedFlag.severePain => l.flagSeverePain,
  RedFlag.fall => l.flagFall,
};
