// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your physio companion';

  @override
  String get navToday => 'Today';

  @override
  String get navProgress => 'Progress';

  @override
  String get navLibrary => 'Library';

  @override
  String get settings => 'Settings';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get letsMove => 'Let\'s move';

  @override
  String get restDay => 'Rest day';

  @override
  String get todaysProgram => 'Today\'s program';

  @override
  String fromPhysio(String name) {
    return 'From $name';
  }

  @override
  String get yourPhysio => 'your physio';

  @override
  String get yourProgram => 'Your program';

  @override
  String get nothingScheduled =>
      'Nothing is scheduled yet. Your physio will add exercises.';

  @override
  String nothingTodayNext(String day) {
    return 'Nothing today. Next session: $day.';
  }

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String aboutMinutes(int minutes) {
    return 'about $minutes min';
  }

  @override
  String aboutMinutesInTotal(int minutes) {
    return 'About $minutes min in total';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get startSession => 'Start session';

  @override
  String get offlineSaved =>
      'Offline. Your progress is saved and will be sent later.';

  @override
  String get exercisesHeading => 'Exercises';

  @override
  String get haveCode => 'Have a code from your physio?';

  @override
  String get haveCodeBody =>
      'Link the app to get your own program and share your progress.';

  @override
  String get linkedSnack => 'Linked. Your physio\'s program is ready.';

  @override
  String get programUpdated => 'Your physio updated your program';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get noteFromPhysio => 'Note from your physio';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get rest => 'Rest';

  @override
  String doseSetsReps(int sets, int reps) {
    return '$sets sets × $reps reps';
  }

  @override
  String doseSetsTime(int sets, int seconds) {
    return '$sets × ${seconds}s';
  }

  @override
  String doseHold(int seconds) {
    return 'hold $seconds s';
  }

  @override
  String get doseEachSide => 'each side';

  @override
  String doseRest(int seconds) {
    return 'rest $seconds s';
  }

  @override
  String region(String region) {
    String _temp0 = intl.Intl.selectLogic(region, {
      'knee': 'Knee',
      'hip': 'Hip',
      'ankle': 'Ankle',
      'back': 'Back',
      'neck': 'Neck',
      'shoulder': 'Shoulder',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String equipment(String item) {
    String _temp0 = intl.Intl.selectLogic(item, {
      'wall': 'Wall',
      'mat': 'Mat',
      'chair': 'Chair',
      'table': 'Table',
      'other': 'Equipment',
    });
    return '$_temp0';
  }

  @override
  String get whatItDoes => 'What it does';

  @override
  String get howToDoIt => 'How to do it';

  @override
  String get startExercise => 'Start exercise';

  @override
  String get effectWorks => 'Works';

  @override
  String get effectStretches => 'Stretches';

  @override
  String get effectLoosens => 'Gently loosens';

  @override
  String exerciseXofY(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String get stop => 'Stop';

  @override
  String get voiceOff => 'Turn voice off';

  @override
  String get voiceOn => 'Turn voice on';

  @override
  String get endSessionQuestion => 'End this session?';

  @override
  String get progressSaved => 'What you have done so far is saved.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get endSession => 'End session';

  @override
  String get finishSet => 'Finish set';

  @override
  String get finishSide => 'Finish side';

  @override
  String get skip => 'Skip';

  @override
  String get addTime30 => '+30 s';

  @override
  String nextSet(int set, int total) {
    return 'Next: set $set of $total';
  }

  @override
  String setXofY(int set, int total) {
    return 'Set $set of $total';
  }

  @override
  String repXofY(int rep, int total) {
    return 'Rep $rep of $total';
  }

  @override
  String get leftSide => 'Left side';

  @override
  String get rightSide => 'Right side';

  @override
  String get tapToPause => 'Tap to pause';

  @override
  String get pausedTapResume => 'Paused · tap to resume';

  @override
  String get getReady => 'Get ready';

  @override
  String get hold => 'Hold';

  @override
  String get upNext => 'Up next';

  @override
  String timeLeft(String time) {
    return '$time left in this session';
  }

  @override
  String get sessionComplete => 'Session complete';

  @override
  String completeSummary(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · $time of exercise';
  }

  @override
  String get howWasIt => 'How was it today?';

  @override
  String get feedbackEasy => 'Easy';

  @override
  String get feedbackOk => 'OK';

  @override
  String get feedbackHard => 'Hard';

  @override
  String howDidItFeel(String exercise) {
    return 'How did $exercise feel?';
  }

  @override
  String get painScale =>
      'Any pain? 0 is none, 10 is the worst you can imagine.';

  @override
  String get painTooHigh =>
      'That is a lot of pain. We will stop the session so you can rest.';

  @override
  String get addNote => 'Add a note';

  @override
  String get noteHint => 'For example: knee felt stiff on the left';

  @override
  String get shareNote => 'Share this note with my physio';

  @override
  String get shareNoteOff => 'Otherwise it stays on this phone';

  @override
  String get continueLabel => 'Continue';

  @override
  String painValue(int value) {
    return 'Pain $value';
  }

  @override
  String get whyStopping => 'Why are you stopping?';

  @override
  String get justStop => 'I just want to stop for today';

  @override
  String get flagChestPain => 'Chest pain or tightness';

  @override
  String get flagNumbness => 'Numbness, tingling or weakness';

  @override
  String get flagSeverePain => 'Sudden severe pain';

  @override
  String get flagFall => 'I fell, or feel faint or dizzy';

  @override
  String get stopNow => 'Stop exercising now';

  @override
  String get adviceChest =>
      'Chest pain can be serious. Sit down and call emergency services now.';

  @override
  String get adviceFall =>
      'Stay still and sit or lie down. If you hit your head, feel faint, or cannot get up, call emergency services.';

  @override
  String get adviceNumbness =>
      'Stop and rest. Tell your physio about the numbness or tingling before you exercise again.';

  @override
  String get adviceSeverePain =>
      'Stop and rest the area. Do not continue this exercise until your physio has checked it.';

  @override
  String advicePain(int pain) {
    return 'Pain of $pain out of 10 is too much. Rest now, and check with your physio before your next session.';
  }

  @override
  String get callEmergency => 'Call emergency 112';

  @override
  String callPhysio(String name) {
    return 'Call $name';
  }

  @override
  String get imOk => 'I\'m OK, close';

  @override
  String get notLinkedNobodyTold =>
      'This app is not linked to a physio, so nobody has been told. Please contact your doctor or physio.';

  @override
  String physioWillSee(String name) {
    return '$name will see this in your log as soon as your phone is online.';
  }

  @override
  String cannotDial(String number) {
    return 'Could not open the phone app. Please dial $number.';
  }

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get noSessionsBody =>
      'Your streak, your week and each exercise\'s history appear here after your first session.';

  @override
  String daysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days in a row',
      one: 'day in a row',
    );
    return '$_temp0';
  }

  @override
  String get ofThisWeeksPlan => 'of this week\'s plan';

  @override
  String get last2Weeks => 'Last 2 weeks';

  @override
  String get comingUp => 'Coming up';

  @override
  String get yourExercises => 'Your exercises';

  @override
  String timesDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get painNotRecorded => 'pain not recorded';

  @override
  String lastPain(int pain) {
    return 'last pain $pain/10';
  }

  @override
  String painOutOf10(int pain) {
    return 'pain $pain/10';
  }

  @override
  String setsOfPlanned(int done, int planned) {
    return '$done of $planned sets';
  }

  @override
  String repsCount(int reps) {
    return '$reps reps';
  }

  @override
  String get sharedWithPhysio => 'Shared with your physio';

  @override
  String get privateOnPhone => 'Private, on this phone only';

  @override
  String get myPhysio => 'My physio';

  @override
  String get reminder => 'Reminder';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get languagePhone => 'Phone';

  @override
  String get themePhone => 'Phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get welcomeTour => 'Welcome tour';

  @override
  String get welcomeTourBody => 'How tutorials and the glow colours work';

  @override
  String get thisBuild => 'This build';

  @override
  String get worksOffline => 'Works offline';

  @override
  String get crashReporting => 'Crash reporting';

  @override
  String get backendSync => 'Backend sync';

  @override
  String get statusOn => 'On';

  @override
  String get statusNotSetUp => 'Not set up';

  @override
  String get sendTestEvent => 'Send test event to Sentry';

  @override
  String get notLinked => 'Not linked';

  @override
  String get notLinkedBody =>
      'Enter the code from your physio to get your own program.';

  @override
  String get linkUnavailable => 'Linking is not available in this build.';

  @override
  String linkedAs(String name) {
    return 'Linked as $name';
  }

  @override
  String get useNewCode => 'Use a new code';

  @override
  String get useNewCodeBody =>
      'For a new phone, or when your physio gives you a new code';

  @override
  String get notificationsOff =>
      'Notifications are off for PhysioSathi. Turn them on in your phone settings.';

  @override
  String get remindDaily => 'Remind me every day';

  @override
  String get reminderTime => 'Time';

  @override
  String get reminderTitle => 'Time for your exercises';

  @override
  String get reminderBody => 'A few minutes now keeps your recovery on track.';

  @override
  String get linkTitle => 'Link with my physio';

  @override
  String get enterCode => 'Enter the code from your physio';

  @override
  String get codeHelp =>
      'It has 8 letters and numbers. Your physio can give you a new one if it has expired.';

  @override
  String get consent => 'Share my exercise logs and pain scores with my physio';

  @override
  String get consentBody =>
      'Your notes stay on this phone unless you choose to share them. Camera video is never saved or sent.';

  @override
  String get linkButton => 'Link my app';

  @override
  String get errNoInternet =>
      'No internet connection. Connect to Wi-Fi or mobile data and try again.';

  @override
  String get errSlow =>
      'The connection is too slow right now. Please try again.';

  @override
  String get errGeneric =>
      'Could not link right now. Please try again in a moment.';

  @override
  String get errInvalidCode =>
      'This code is not valid or has expired. Ask your physio for a new one.';

  @override
  String welcomeTitle(String app) {
    return 'Welcome to $app';
  }

  @override
  String get welcomeBody =>
      'Your home exercises, guided step by step. Everything works without internet.';

  @override
  String get watchTitle => 'Watch, then move along';

  @override
  String get watchBody =>
      'The video moves with the timer and the voice, rep by rep. The glow shows what each exercise does:';

  @override
  String get safetyTitle => 'Exercise safely';

  @override
  String get safetyBody =>
      'Move slowly and stay within comfort. Stop and contact your physiotherapist if you feel sharp pain, numbness, or pain above 7 out of 10.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get draftNotice =>
      'Draft instructions, not yet reviewed by a physiotherapist.';

  @override
  String get safetyNotice =>
      'Stop and contact your physiotherapist if you feel sharp pain, numbness, or pain above 7 out of 10.';

  @override
  String get cueStart => 'Start';

  @override
  String cueNextExercise(String exercise) {
    return 'Next, $exercise';
  }

  @override
  String get cueSessionDone => 'Session complete. Well done.';

  @override
  String get countWithCamera => 'Count with camera';

  @override
  String get stopCamera => 'Stop camera';

  @override
  String get cameraGuideTitle => 'Place your phone';

  @override
  String get cameraPlaceSideStanding =>
      'Stand the phone up about 3 steps to your side, so your whole body shows, head to feet.';

  @override
  String get cameraPlaceSideLying =>
      'Stand the phone up on the floor about 2 steps to your side, so your whole body shows while you lie down.';

  @override
  String get cameraPlaceFrontLying =>
      'Stand the phone up on the floor about 2 steps in front of you, so your hips and knees show while you lie on your side.';

  @override
  String get cameraGuideTips =>
      'Use good light and keep the phone still. The timer keeps going; the camera only counts your reps.';

  @override
  String get cameraPrivacy =>
      'The picture stays on this phone. Nothing is recorded or sent.';

  @override
  String get startCamera => 'Start camera';

  @override
  String get cameraStarting => 'Starting camera…';

  @override
  String get cameraStepBack =>
      'Can\'t see you fully. Move so your whole body shows.';

  @override
  String cameraBest(int degrees) {
    return 'Best $degrees°';
  }

  @override
  String get cameraDenied =>
      'Camera permission is off, so reps follow the timer.';

  @override
  String get cameraFailed =>
      'The camera could not start, so reps follow the timer.';

  @override
  String get yourData => 'Your data';

  @override
  String get deleteMyData => 'Delete my data';

  @override
  String get deleteMyDataBody =>
      'Removes your exercise history and notes from this phone.';

  @override
  String get deleteMyDataLinkedBody =>
      'Removes your history and notes from this phone and your record at your physio\'s clinic.';

  @override
  String get deleteConfirmTitle => 'Delete your data?';

  @override
  String get deleteConfirmBody =>
      'This removes your exercise history, pain scores and notes from this phone. It cannot be undone.';

  @override
  String get deleteConfirmLinkedBody =>
      'This removes your exercise history, pain scores and notes from this phone and from your physio\'s clinic, and unlinks this phone. Your physio will no longer see your progress. It cannot be undone.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get dataDeleted => 'Your data was deleted.';

  @override
  String get deleteNeedsInternet =>
      'Deleting your record at the clinic needs the internet. Nothing was deleted; try again when you\'re online.';
}
