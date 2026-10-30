// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTagline => 'आपका फ़िज़ियो साथी';

  @override
  String get navToday => 'आज';

  @override
  String get navProgress => 'प्रगति';

  @override
  String get navLibrary => 'व्यायाम';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get greetingMorning => 'सुप्रभात';

  @override
  String get greetingAfternoon => 'नमस्ते';

  @override
  String get greetingEvening => 'शुभ संध्या';

  @override
  String get letsMove => 'चलिए शुरू करें';

  @override
  String get restDay => 'आराम का दिन';

  @override
  String get todaysProgram => 'आज का कार्यक्रम';

  @override
  String fromPhysio(String name) {
    return '$name की ओर से';
  }

  @override
  String get yourPhysio => 'आपके फ़िज़ियो';

  @override
  String get yourProgram => 'आपका कार्यक्रम';

  @override
  String get nothingScheduled =>
      'अभी कुछ तय नहीं है। आपके फ़िज़ियो व्यायाम जोड़ेंगे।';

  @override
  String nothingTodayNext(String day) {
    return 'आज कुछ नहीं। अगला सत्र: $day।';
  }

  @override
  String exerciseCount(int count) {
    return '$count व्यायाम';
  }

  @override
  String aboutMinutes(int minutes) {
    return 'लगभग $minutes मिनट';
  }

  @override
  String aboutMinutesInTotal(int minutes) {
    return 'कुल लगभग $minutes मिनट';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String get startSession => 'सत्र शुरू करें';

  @override
  String get offlineSaved =>
      'ऑफ़लाइन। आपकी प्रगति सेव है और बाद में भेज दी जाएगी।';

  @override
  String get exercisesHeading => 'व्यायाम';

  @override
  String get haveCode => 'क्या फ़िज़ियो ने आपको कोड दिया है?';

  @override
  String get haveCodeBody =>
      'ऐप को जोड़ें, ताकि आपको अपना कार्यक्रम मिले और आपकी प्रगति फ़िज़ियो तक पहुँचे।';

  @override
  String get linkedSnack => 'जुड़ गया। आपके फ़िज़ियो का कार्यक्रम तैयार है।';

  @override
  String get programUpdated => 'आपके फ़िज़ियो ने आपका कार्यक्रम बदला है';

  @override
  String get dismiss => 'हटाएँ';

  @override
  String get noteFromPhysio => 'आपके फ़िज़ियो का संदेश';

  @override
  String get tomorrow => 'कल';

  @override
  String get rest => 'आराम';

  @override
  String doseSetsReps(int sets, int reps) {
    return '$sets सेट × $reps बार';
  }

  @override
  String doseSetsTime(int sets, int seconds) {
    return '$sets × $seconds सेकंड';
  }

  @override
  String doseHold(int seconds) {
    return '$seconds सेकंड रोकें';
  }

  @override
  String get doseEachSide => 'हर तरफ़';

  @override
  String doseRest(int seconds) {
    return '$seconds सेकंड आराम';
  }

  @override
  String region(String region) {
    String _temp0 = intl.Intl.selectLogic(region, {
      'knee': 'घुटना',
      'hip': 'कूल्हा',
      'ankle': 'टखना',
      'back': 'पीठ',
      'neck': 'गर्दन',
      'shoulder': 'कंधा',
      'other': 'अन्य',
    });
    return '$_temp0';
  }

  @override
  String equipment(String item) {
    String _temp0 = intl.Intl.selectLogic(item, {
      'wall': 'दीवार',
      'mat': 'मैट',
      'chair': 'कुर्सी',
      'table': 'मेज़',
      'other': 'सामान',
    });
    return '$_temp0';
  }

  @override
  String get whatItDoes => 'इससे क्या होता है';

  @override
  String get howToDoIt => 'कैसे करें';

  @override
  String get startExercise => 'व्यायाम शुरू करें';

  @override
  String get effectWorks => 'मज़बूत करता है';

  @override
  String get effectStretches => 'खिंचाव देता है';

  @override
  String get effectLoosens => 'धीरे से ढीला करता है';

  @override
  String exerciseXofY(int current, int total) {
    return 'व्यायाम $current / $total';
  }

  @override
  String get stop => 'रुकें';

  @override
  String get voiceOff => 'आवाज़ बंद करें';

  @override
  String get voiceOn => 'आवाज़ चालू करें';

  @override
  String get endSessionQuestion => 'सत्र ख़त्म करें?';

  @override
  String get progressSaved => 'अब तक का काम सेव है।';

  @override
  String get keepGoing => 'जारी रखें';

  @override
  String get endSession => 'सत्र ख़त्म करें';

  @override
  String get finishSet => 'सेट पूरा';

  @override
  String get finishSide => 'यह तरफ़ पूरी';

  @override
  String get skip => 'छोड़ें';

  @override
  String get addTime30 => '+30 सेकंड';

  @override
  String nextSet(int set, int total) {
    return 'अगला: सेट $set / $total';
  }

  @override
  String setXofY(int set, int total) {
    return 'सेट $set / $total';
  }

  @override
  String repXofY(int rep, int total) {
    return 'बार $rep / $total';
  }

  @override
  String get leftSide => 'बाईं तरफ़';

  @override
  String get rightSide => 'दाईं तरफ़';

  @override
  String get tapToPause => 'रोकने के लिए छुएँ';

  @override
  String get pausedTapResume => 'रुका है · जारी रखने के लिए छुएँ';

  @override
  String get getReady => 'तैयार हो जाइए';

  @override
  String get hold => 'रोकें';

  @override
  String get upNext => 'अगला';

  @override
  String timeLeft(String time) {
    return 'इस सत्र में $time बाकी';
  }

  @override
  String get sessionComplete => 'सत्र पूरा हुआ';

  @override
  String completeSummary(int count, String time) {
    return '$count व्यायाम · $time व्यायाम किया';
  }

  @override
  String get howWasIt => 'आज कैसा रहा?';

  @override
  String get feedbackEasy => 'आसान';

  @override
  String get feedbackOk => 'ठीक';

  @override
  String get feedbackHard => 'मुश्किल';

  @override
  String howDidItFeel(String exercise) {
    return '$exercise कैसा लगा?';
  }

  @override
  String get painScale =>
      'कोई दर्द? 0 मतलब बिल्कुल नहीं, 10 मतलब सबसे ज़्यादा दर्द।';

  @override
  String get painTooHigh =>
      'यह बहुत ज़्यादा दर्द है। हम सत्र रोक रहे हैं ताकि आप आराम कर सकें।';

  @override
  String get addNote => 'नोट लिखें';

  @override
  String get noteHint => 'जैसे: बाएँ घुटने में जकड़न लगी';

  @override
  String get shareNote => 'यह नोट मेरे फ़िज़ियो को दिखाएँ';

  @override
  String get shareNoteOff => 'नहीं तो यह इसी फ़ोन पर रहेगा';

  @override
  String get continueLabel => 'आगे';

  @override
  String painValue(int value) {
    return 'दर्द $value';
  }

  @override
  String get whyStopping => 'आप क्यों रुक रहे हैं?';

  @override
  String get justStop => 'आज के लिए बस रुकना है';

  @override
  String get flagChestPain => 'सीने में दर्द या जकड़न';

  @override
  String get flagNumbness => 'सुन्नपन, झनझनाहट या कमज़ोरी';

  @override
  String get flagSeverePain => 'अचानक तेज़ दर्द';

  @override
  String get flagFall => 'मैं गिर गया/गई, या चक्कर या बेहोशी लग रही है';

  @override
  String get stopNow => 'अभी व्यायाम रोकें';

  @override
  String get adviceChest =>
      'सीने का दर्द गंभीर हो सकता है। बैठ जाइए और तुरंत आपातकालीन सेवा को फ़ोन कीजिए।';

  @override
  String get adviceFall =>
      'हिलें नहीं, बैठ या लेट जाइए। सिर में चोट लगी हो, बेहोशी लग रही हो या उठ न पा रहे हों, तो आपातकालीन सेवा को फ़ोन कीजिए।';

  @override
  String get adviceNumbness =>
      'रुकिए और आराम कीजिए। दोबारा व्यायाम से पहले फ़िज़ियो को सुन्नपन या झनझनाहट के बारे में बताइए।';

  @override
  String get adviceSeverePain =>
      'रुकिए और उस हिस्से को आराम दीजिए। फ़िज़ियो के जाँचने तक यह व्यायाम न करें।';

  @override
  String advicePain(int pain) {
    return '10 में से $pain का दर्द बहुत ज़्यादा है। अभी आराम कीजिए और अगले सत्र से पहले फ़िज़ियो से बात कीजिए।';
  }

  @override
  String get callEmergency => 'आपातकालीन 112 पर कॉल करें';

  @override
  String callPhysio(String name) {
    return '$name को कॉल करें';
  }

  @override
  String get imOk => 'मैं ठीक हूँ, बंद करें';

  @override
  String get notLinkedNobodyTold =>
      'यह ऐप किसी फ़िज़ियो से जुड़ा नहीं है, इसलिए किसी को सूचना नहीं गई। कृपया अपने डॉक्टर या फ़िज़ियो से संपर्क करें।';

  @override
  String physioWillSee(String name) {
    return 'फ़ोन ऑनलाइन होते ही $name को यह आपकी जानकारी में दिखेगा।';
  }

  @override
  String cannotDial(String number) {
    return 'फ़ोन ऐप नहीं खुला। कृपया $number डायल करें।';
  }

  @override
  String get noSessionsYet => 'अभी कोई सत्र नहीं';

  @override
  String get noSessionsBody =>
      'पहले सत्र के बाद यहाँ लगातार दिनों की गिनती, हफ़्ते की प्रगति और हर व्यायाम का इतिहास दिखेगा।';

  @override
  String daysInARow(int count) {
    return 'दिन लगातार';
  }

  @override
  String get ofThisWeeksPlan => 'इस हफ़्ते की योजना का';

  @override
  String get last2Weeks => 'पिछले 2 हफ़्ते';

  @override
  String get comingUp => 'आने वाले दिन';

  @override
  String get yourExercises => 'आपके व्यायाम';

  @override
  String timesDone(int count) {
    return '$count बार';
  }

  @override
  String get painNotRecorded => 'दर्द दर्ज नहीं';

  @override
  String lastPain(int pain) {
    return 'पिछला दर्द $pain/10';
  }

  @override
  String painOutOf10(int pain) {
    return 'दर्द $pain/10';
  }

  @override
  String setsOfPlanned(int done, int planned) {
    return '$planned में से $done सेट';
  }

  @override
  String repsCount(int reps) {
    return '$reps बार';
  }

  @override
  String get sharedWithPhysio => 'फ़िज़ियो को दिखाया गया';

  @override
  String get privateOnPhone => 'निजी, सिर्फ़ इस फ़ोन पर';

  @override
  String get myPhysio => 'मेरे फ़िज़ियो';

  @override
  String get reminder => 'याद दिलाना';

  @override
  String get appearance => 'दिखावट';

  @override
  String get language => 'भाषा';

  @override
  String get languagePhone => 'फ़ोन';

  @override
  String get themePhone => 'फ़ोन';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeDark => 'गहरा';

  @override
  String get welcomeTour => 'परिचय फिर देखें';

  @override
  String get welcomeTourBody => 'वीडियो और चमकते रंगों का मतलब';

  @override
  String get thisBuild => 'यह संस्करण';

  @override
  String get worksOffline => 'बिना इंटरनेट चलता है';

  @override
  String get crashReporting => 'गड़बड़ी की रिपोर्ट';

  @override
  String get backendSync => 'सर्वर से सिंक';

  @override
  String get statusOn => 'चालू';

  @override
  String get statusNotSetUp => 'सेट नहीं';

  @override
  String get sendTestEvent => 'Sentry को टेस्ट भेजें';

  @override
  String get notLinked => 'जुड़ा नहीं';

  @override
  String get notLinkedBody =>
      'अपना कार्यक्रम पाने के लिए फ़िज़ियो का दिया कोड डालें।';

  @override
  String get linkUnavailable => 'इस संस्करण में जोड़ना उपलब्ध नहीं है।';

  @override
  String linkedAs(String name) {
    return '$name के रूप में जुड़ा';
  }

  @override
  String get useNewCode => 'नया कोड डालें';

  @override
  String get useNewCodeBody => 'नए फ़ोन के लिए, या जब फ़िज़ियो नया कोड दें';

  @override
  String get notificationsOff =>
      'PhysioSathi की सूचनाएँ बंद हैं। फ़ोन की सेटिंग्स में चालू करें।';

  @override
  String get remindDaily => 'रोज़ याद दिलाएँ';

  @override
  String get reminderTime => 'समय';

  @override
  String get reminderTitle => 'व्यायाम का समय';

  @override
  String get reminderBody =>
      'अभी कुछ मिनट का व्यायाम आपको जल्दी ठीक होने में मदद करेगा।';

  @override
  String get linkTitle => 'फ़िज़ियो से जोड़ें';

  @override
  String get enterCode => 'फ़िज़ियो का दिया कोड डालें';

  @override
  String get codeHelp =>
      'इसमें 8 अक्षर और अंक होते हैं। समय सीमा ख़त्म होने पर फ़िज़ियो नया कोड दे सकते हैं।';

  @override
  String get consent =>
      'मेरे व्यायाम और दर्द की जानकारी मेरे फ़िज़ियो के साथ साझा करें';

  @override
  String get consentBody =>
      'आपके नोट इसी फ़ोन पर रहते हैं, जब तक आप उन्हें साझा न करें। कैमरा वीडियो कभी सेव या भेजा नहीं जाता।';

  @override
  String get linkButton => 'ऐप जोड़ें';

  @override
  String get errNoInternet =>
      'इंटरनेट नहीं है। वाई-फ़ाई या मोबाइल डेटा चालू करके फिर कोशिश करें।';

  @override
  String get errSlow => 'अभी कनेक्शन बहुत धीमा है। कृपया फिर कोशिश करें।';

  @override
  String get errGeneric => 'अभी जोड़ नहीं पाए। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get errInvalidCode =>
      'यह कोड सही नहीं है या इसकी समय सीमा ख़त्म हो गई है। फ़िज़ियो से नया कोड लें।';

  @override
  String welcomeTitle(String app) {
    return '$app में आपका स्वागत है';
  }

  @override
  String get welcomeBody =>
      'घर पर व्यायाम, हर कदम पर मार्गदर्शन के साथ। सब कुछ बिना इंटरनेट के चलता है।';

  @override
  String get watchTitle => 'देखिए, फिर साथ-साथ कीजिए';

  @override
  String get watchBody =>
      'वीडियो टाइमर और आवाज़ के साथ हर बार चलता है। चमक बताती है कि व्यायाम कहाँ असर करता है:';

  @override
  String get safetyTitle => 'सुरक्षित व्यायाम करें';

  @override
  String get safetyBody =>
      'धीरे-धीरे और आराम की सीमा में व्यायाम करें। तेज़ दर्द, सुन्नपन, या 10 में से 7 से ज़्यादा दर्द हो तो रुकें और अपने फ़िज़ियोथेरेपिस्ट से संपर्क करें।';

  @override
  String get next => 'आगे';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get draftNotice =>
      'ये निर्देश अभी ड्राफ़्ट हैं, किसी फ़िज़ियोथेरेपिस्ट ने अभी जाँचे नहीं हैं।';

  @override
  String get safetyNotice =>
      'तेज़ दर्द, सुन्नपन, या 10 में से 7 से ज़्यादा दर्द हो तो रुकें और अपने फ़िज़ियोथेरेपिस्ट से संपर्क करें।';

  @override
  String get cueStart => 'शुरू';

  @override
  String cueNextExercise(String exercise) {
    return 'अगला, $exercise';
  }

  @override
  String get cueSessionDone => 'सत्र पूरा हुआ। बहुत बढ़िया।';

  @override
  String get countWithCamera => 'कैमरे से गिनें';

  @override
  String get stopCamera => 'कैमरा बंद करें';

  @override
  String get cameraGuideTitle => 'फ़ोन ऐसे रखें';

  @override
  String get cameraPlaceSideStanding =>
      'फ़ोन को अपनी बगल में लगभग 3 कदम दूर खड़ा रखें, ताकि सिर से पैर तक पूरा शरीर दिखे।';

  @override
  String get cameraPlaceSideLying =>
      'फ़ोन को ज़मीन पर अपनी बगल में लगभग 2 कदम दूर खड़ा रखें, ताकि लेटे हुए पूरा शरीर दिखे।';

  @override
  String get cameraPlaceFrontLying =>
      'फ़ोन को ज़मीन पर अपने सामने लगभग 2 कदम दूर खड़ा रखें, ताकि करवट लेटे हुए कूल्हे और घुटने दिखें।';

  @override
  String get cameraGuideTips =>
      'अच्छी रोशनी रखें और फ़ोन को हिलने न दें। टाइमर चलता रहेगा; कैमरा सिर्फ़ आपकी गिनती करेगा।';

  @override
  String get cameraPrivacy =>
      'तस्वीर इसी फ़ोन पर रहती है। कुछ भी रिकॉर्ड या भेजा नहीं जाता।';

  @override
  String get startCamera => 'कैमरा शुरू करें';

  @override
  String get cameraStarting => 'कैमरा शुरू हो रहा है…';

  @override
  String get cameraStepBack =>
      'आप पूरे नहीं दिख रहे। ऐसे आएँ कि पूरा शरीर दिखे।';

  @override
  String cameraBest(int degrees) {
    return 'सबसे ज़्यादा $degrees°';
  }

  @override
  String get cameraDenied =>
      'कैमरे की अनुमति बंद है, इसलिए गिनती टाइमर से होगी।';

  @override
  String get cameraFailed =>
      'कैमरा शुरू नहीं हो सका, इसलिए गिनती टाइमर से होगी।';
}
