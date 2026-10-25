import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your physio companion'**
  String get appTagline;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @letsMove.
  ///
  /// In en, this message translates to:
  /// **'Let\'s move'**
  String get letsMove;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @todaysProgram.
  ///
  /// In en, this message translates to:
  /// **'Today\'s program'**
  String get todaysProgram;

  /// No description provided for @fromPhysio.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromPhysio(String name);

  /// No description provided for @yourPhysio.
  ///
  /// In en, this message translates to:
  /// **'your physio'**
  String get yourPhysio;

  /// No description provided for @yourProgram.
  ///
  /// In en, this message translates to:
  /// **'Your program'**
  String get yourProgram;

  /// No description provided for @nothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled yet. Your physio will add exercises.'**
  String get nothingScheduled;

  /// No description provided for @nothingTodayNext.
  ///
  /// In en, this message translates to:
  /// **'Nothing today. Next session: {day}.'**
  String nothingTodayNext(String day);

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @aboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min'**
  String aboutMinutes(int minutes);

  /// No description provided for @aboutMinutesInTotal.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min in total'**
  String aboutMinutesInTotal(int minutes);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession;

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline. Your progress is saved and will be sent later.'**
  String get offlineSaved;

  /// No description provided for @exercisesHeading.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesHeading;

  /// No description provided for @haveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a code from your physio?'**
  String get haveCode;

  /// No description provided for @haveCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Link the app to get your own program and share your progress.'**
  String get haveCodeBody;

  /// No description provided for @linkedSnack.
  ///
  /// In en, this message translates to:
  /// **'Linked. Your physio\'s program is ready.'**
  String get linkedSnack;

  /// No description provided for @programUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your physio updated your program'**
  String get programUpdated;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @noteFromPhysio.
  ///
  /// In en, this message translates to:
  /// **'Note from your physio'**
  String get noteFromPhysio;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @doseSetsReps.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets × {reps} reps'**
  String doseSetsReps(int sets, int reps);

  /// No description provided for @doseSetsTime.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {seconds}s'**
  String doseSetsTime(int sets, int seconds);

  /// No description provided for @doseHold.
  ///
  /// In en, this message translates to:
  /// **'hold {seconds} s'**
  String doseHold(int seconds);

  /// No description provided for @doseEachSide.
  ///
  /// In en, this message translates to:
  /// **'each side'**
  String get doseEachSide;

  /// No description provided for @doseRest.
  ///
  /// In en, this message translates to:
  /// **'rest {seconds} s'**
  String doseRest(int seconds);

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'{region, select, knee{Knee} hip{Hip} ankle{Ankle} back{Back} neck{Neck} shoulder{Shoulder} other{Other}}'**
  String region(String region);

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'{item, select, wall{Wall} mat{Mat} chair{Chair} table{Table} other{Equipment}}'**
  String equipment(String item);

  /// No description provided for @whatItDoes.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get whatItDoes;

  /// No description provided for @howToDoIt.
  ///
  /// In en, this message translates to:
  /// **'How to do it'**
  String get howToDoIt;

  /// No description provided for @startExercise.
  ///
  /// In en, this message translates to:
  /// **'Start exercise'**
  String get startExercise;

  /// No description provided for @effectWorks.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get effectWorks;

  /// No description provided for @effectStretches.
  ///
  /// In en, this message translates to:
  /// **'Stretches'**
  String get effectStretches;

  /// No description provided for @effectLoosens.
  ///
  /// In en, this message translates to:
  /// **'Gently loosens'**
  String get effectLoosens;

  /// No description provided for @exerciseXofY.
  ///
  /// In en, this message translates to:
  /// **'Exercise {current} of {total}'**
  String exerciseXofY(int current, int total);

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @voiceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn voice off'**
  String get voiceOff;

  /// No description provided for @voiceOn.
  ///
  /// In en, this message translates to:
  /// **'Turn voice on'**
  String get voiceOn;

  /// No description provided for @endSessionQuestion.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get endSessionQuestion;

  /// No description provided for @progressSaved.
  ///
  /// In en, this message translates to:
  /// **'What you have done so far is saved.'**
  String get progressSaved;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @finishSet.
  ///
  /// In en, this message translates to:
  /// **'Finish set'**
  String get finishSet;

  /// No description provided for @finishSide.
  ///
  /// In en, this message translates to:
  /// **'Finish side'**
  String get finishSide;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @addTime30.
  ///
  /// In en, this message translates to:
  /// **'+30 s'**
  String get addTime30;

  /// No description provided for @nextSet.
  ///
  /// In en, this message translates to:
  /// **'Next: set {set} of {total}'**
  String nextSet(int set, int total);

  /// No description provided for @setXofY.
  ///
  /// In en, this message translates to:
  /// **'Set {set} of {total}'**
  String setXofY(int set, int total);

  /// No description provided for @repXofY.
  ///
  /// In en, this message translates to:
  /// **'Rep {rep} of {total}'**
  String repXofY(int rep, int total);

  /// No description provided for @leftSide.
  ///
  /// In en, this message translates to:
  /// **'Left side'**
  String get leftSide;

  /// No description provided for @rightSide.
  ///
  /// In en, this message translates to:
  /// **'Right side'**
  String get rightSide;

  /// No description provided for @tapToPause.
  ///
  /// In en, this message translates to:
  /// **'Tap to pause'**
  String get tapToPause;

  /// No description provided for @pausedTapResume.
  ///
  /// In en, this message translates to:
  /// **'Paused · tap to resume'**
  String get pausedTapResume;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get getReady;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left in this session'**
  String timeLeft(String time);

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @completeSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}} · {time} of exercise'**
  String completeSummary(int count, String time);

  /// No description provided for @howWasIt.
  ///
  /// In en, this message translates to:
  /// **'How was it today?'**
  String get howWasIt;

  /// No description provided for @feedbackEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get feedbackEasy;

  /// No description provided for @feedbackOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get feedbackOk;

  /// No description provided for @feedbackHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get feedbackHard;

  /// No description provided for @howDidItFeel.
  ///
  /// In en, this message translates to:
  /// **'How did {exercise} feel?'**
  String howDidItFeel(String exercise);

  /// No description provided for @painScale.
  ///
  /// In en, this message translates to:
  /// **'Any pain? 0 is none, 10 is the worst you can imagine.'**
  String get painScale;

  /// No description provided for @painTooHigh.
  ///
  /// In en, this message translates to:
  /// **'That is a lot of pain. We will stop the session so you can rest.'**
  String get painTooHigh;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'For example: knee felt stiff on the left'**
  String get noteHint;

  /// No description provided for @shareNote.
  ///
  /// In en, this message translates to:
  /// **'Share this note with my physio'**
  String get shareNote;

  /// No description provided for @shareNoteOff.
  ///
  /// In en, this message translates to:
  /// **'Otherwise it stays on this phone'**
  String get shareNoteOff;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @painValue.
  ///
  /// In en, this message translates to:
  /// **'Pain {value}'**
  String painValue(int value);

  /// No description provided for @whyStopping.
  ///
  /// In en, this message translates to:
  /// **'Why are you stopping?'**
  String get whyStopping;

  /// No description provided for @justStop.
  ///
  /// In en, this message translates to:
  /// **'I just want to stop for today'**
  String get justStop;

  /// No description provided for @flagChestPain.
  ///
  /// In en, this message translates to:
  /// **'Chest pain or tightness'**
  String get flagChestPain;

  /// No description provided for @flagNumbness.
  ///
  /// In en, this message translates to:
  /// **'Numbness, tingling or weakness'**
  String get flagNumbness;

  /// No description provided for @flagSeverePain.
  ///
  /// In en, this message translates to:
  /// **'Sudden severe pain'**
  String get flagSeverePain;

  /// No description provided for @flagFall.
  ///
  /// In en, this message translates to:
  /// **'I fell, or feel faint or dizzy'**
  String get flagFall;

  /// No description provided for @stopNow.
  ///
  /// In en, this message translates to:
  /// **'Stop exercising now'**
  String get stopNow;

  /// No description provided for @adviceChest.
  ///
  /// In en, this message translates to:
  /// **'Chest pain can be serious. Sit down and call emergency services now.'**
  String get adviceChest;

  /// No description provided for @adviceFall.
  ///
  /// In en, this message translates to:
  /// **'Stay still and sit or lie down. If you hit your head, feel faint, or cannot get up, call emergency services.'**
  String get adviceFall;

  /// No description provided for @adviceNumbness.
  ///
  /// In en, this message translates to:
  /// **'Stop and rest. Tell your physio about the numbness or tingling before you exercise again.'**
  String get adviceNumbness;

  /// No description provided for @adviceSeverePain.
  ///
  /// In en, this message translates to:
  /// **'Stop and rest the area. Do not continue this exercise until your physio has checked it.'**
  String get adviceSeverePain;

  /// No description provided for @advicePain.
  ///
  /// In en, this message translates to:
  /// **'Pain of {pain} out of 10 is too much. Rest now, and check with your physio before your next session.'**
  String advicePain(int pain);

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call emergency 112'**
  String get callEmergency;

  /// No description provided for @callPhysio.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callPhysio(String name);

  /// No description provided for @imOk.
  ///
  /// In en, this message translates to:
  /// **'I\'m OK, close'**
  String get imOk;

  /// No description provided for @notLinkedNobodyTold.
  ///
  /// In en, this message translates to:
  /// **'This app is not linked to a physio, so nobody has been told. Please contact your doctor or physio.'**
  String get notLinkedNobodyTold;

  /// No description provided for @physioWillSee.
  ///
  /// In en, this message translates to:
  /// **'{name} will see this in your log as soon as your phone is online.'**
  String physioWillSee(String name);

  /// No description provided for @cannotDial.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app. Please dial {number}.'**
  String cannotDial(String number);

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @noSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'Your streak, your week and each exercise\'s history appear here after your first session.'**
  String get noSessionsBody;

  /// No description provided for @daysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day in a row} other{days in a row}}'**
  String daysInARow(int count);

  /// No description provided for @ofThisWeeksPlan.
  ///
  /// In en, this message translates to:
  /// **'of this week\'s plan'**
  String get ofThisWeeksPlan;

  /// No description provided for @last2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Last 2 weeks'**
  String get last2Weeks;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @yourExercises.
  ///
  /// In en, this message translates to:
  /// **'Your exercises'**
  String get yourExercises;

  /// No description provided for @timesDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String timesDone(int count);

  /// No description provided for @painNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'pain not recorded'**
  String get painNotRecorded;

  /// No description provided for @lastPain.
  ///
  /// In en, this message translates to:
  /// **'last pain {pain}/10'**
  String lastPain(int pain);

  /// No description provided for @painOutOf10.
  ///
  /// In en, this message translates to:
  /// **'pain {pain}/10'**
  String painOutOf10(int pain);

  /// No description provided for @setsOfPlanned.
  ///
  /// In en, this message translates to:
  /// **'{done} of {planned} sets'**
  String setsOfPlanned(int done, int planned);

  /// No description provided for @repsCount.
  ///
  /// In en, this message translates to:
  /// **'{reps} reps'**
  String repsCount(int reps);

  /// No description provided for @sharedWithPhysio.
  ///
  /// In en, this message translates to:
  /// **'Shared with your physio'**
  String get sharedWithPhysio;

  /// No description provided for @privateOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Private, on this phone only'**
  String get privateOnPhone;

  /// No description provided for @myPhysio.
  ///
  /// In en, this message translates to:
  /// **'My physio'**
  String get myPhysio;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languagePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get languagePhone;

  /// No description provided for @themePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get themePhone;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @welcomeTour.
  ///
  /// In en, this message translates to:
  /// **'Welcome tour'**
  String get welcomeTour;

  /// No description provided for @welcomeTourBody.
  ///
  /// In en, this message translates to:
  /// **'How tutorials and the glow colours work'**
  String get welcomeTourBody;

  /// No description provided for @thisBuild.
  ///
  /// In en, this message translates to:
  /// **'This build'**
  String get thisBuild;

  /// No description provided for @worksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get worksOffline;

  /// No description provided for @crashReporting.
  ///
  /// In en, this message translates to:
  /// **'Crash reporting'**
  String get crashReporting;

  /// No description provided for @backendSync.
  ///
  /// In en, this message translates to:
  /// **'Backend sync'**
  String get backendSync;

  /// No description provided for @statusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get statusOn;

  /// No description provided for @statusNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get statusNotSetUp;

  /// No description provided for @sendTestEvent.
  ///
  /// In en, this message translates to:
  /// **'Send test event to Sentry'**
  String get sendTestEvent;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notLinked;

  /// No description provided for @notLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your physio to get your own program.'**
  String get notLinkedBody;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Linking is not available in this build.'**
  String get linkUnavailable;

  /// No description provided for @linkedAs.
  ///
  /// In en, this message translates to:
  /// **'Linked as {name}'**
  String linkedAs(String name);

  /// No description provided for @useNewCode.
  ///
  /// In en, this message translates to:
  /// **'Use a new code'**
  String get useNewCode;

  /// No description provided for @useNewCodeBody.
  ///
  /// In en, this message translates to:
  /// **'For a new phone, or when your physio gives you a new code'**
  String get useNewCodeBody;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for PhysioSathi. Turn them on in your phone settings.'**
  String get notificationsOff;

  /// No description provided for @remindDaily.
  ///
  /// In en, this message translates to:
  /// **'Remind me every day'**
  String get remindDaily;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for your exercises'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'A few minutes now keeps your recovery on track.'**
  String get reminderBody;

  /// No description provided for @linkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link with my physio'**
  String get linkTitle;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your physio'**
  String get enterCode;

  /// No description provided for @codeHelp.
  ///
  /// In en, this message translates to:
  /// **'It has 8 letters and numbers. Your physio can give you a new one if it has expired.'**
  String get codeHelp;

  /// No description provided for @consent.
  ///
  /// In en, this message translates to:
  /// **'Share my exercise logs and pain scores with my physio'**
  String get consent;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Your notes stay on this phone unless you choose to share them. Camera video is never saved or sent.'**
  String get consentBody;

  /// No description provided for @linkButton.
  ///
  /// In en, this message translates to:
  /// **'Link my app'**
  String get linkButton;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Connect to Wi-Fi or mobile data and try again.'**
  String get errNoInternet;

  /// No description provided for @errSlow.
  ///
  /// In en, this message translates to:
  /// **'The connection is too slow right now. Please try again.'**
  String get errSlow;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not link right now. Please try again in a moment.'**
  String get errGeneric;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This code is not valid or has expired. Ask your physio for a new one.'**
  String get errInvalidCode;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {app}'**
  String welcomeTitle(String app);

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your home exercises, guided step by step. Everything works without internet.'**
  String get welcomeBody;

  /// No description provided for @watchTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch, then move along'**
  String get watchTitle;

  /// No description provided for @watchBody.
  ///
  /// In en, this message translates to:
  /// **'The video moves with the timer and the voice, rep by rep. The glow shows what each exercise does:'**
  String get watchBody;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise safely'**
  String get safetyTitle;

  /// No description provided for @safetyBody.
  ///
  /// In en, this message translates to:
  /// **'Move slowly and stay within comfort. Stop and contact your physiotherapist if you feel sharp pain, numbness, or pain above 7 out of 10.'**
  String get safetyBody;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @draftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft instructions, not yet reviewed by a physiotherapist.'**
  String get draftNotice;

  /// No description provided for @safetyNotice.
  ///
  /// In en, this message translates to:
  /// **'Stop and contact your physiotherapist if you feel sharp pain, numbness, or pain above 7 out of 10.'**
  String get safetyNotice;

  /// No description provided for @cueStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get cueStart;

  /// No description provided for @cueNextExercise.
  ///
  /// In en, this message translates to:
  /// **'Next, {exercise}'**
  String cueNextExercise(String exercise);

  /// No description provided for @cueSessionDone.
  ///
  /// In en, this message translates to:
  /// **'Session complete. Well done.'**
  String get cueSessionDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
