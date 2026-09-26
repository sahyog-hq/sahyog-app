// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'सहयोग';

  @override
  String get appTagline => 'आपत्ती प्रतिसाद जाळे';

  @override
  String get sos_alert => 'एसओएस इशारा';

  @override
  String get detecting_activity => 'हालचाल तपासली जात आहे';

  @override
  String get language => 'भाषा';

  @override
  String get languageSubtitle =>
      'इंग्रजी, हिंदी किंवा मराठी. बदल लगेच लागू होतात.';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get marathi => 'मराठी';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signInHint => 'Google ने जोडा किंवा ईमेल वापरा';

  @override
  String get secureConnection => 'सुरक्षित SSL एन्क्रिप्टेड कनेक्शन';

  @override
  String get orDivider => 'किंवा';

  @override
  String get dashboard => 'डॅशबोर्ड';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get map => 'नकाशा';

  @override
  String get missing => 'बेपत्ता';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get sos => 'एसओएस';

  @override
  String get tasks => 'कामे';

  @override
  String get operations => 'कार्यवाही';

  @override
  String get noEmailLinked => 'ईमेल जोडलेले नाही';

  @override
  String get citizen => 'नागरिक';

  @override
  String get healthContactDetails => 'आरोग्य आणि संपर्क माहिती';

  @override
  String get healthContactSubtitle => 'आपत्कालीन पथकासाठी माहिती अद्ययावत करा';

  @override
  String get bloodGroup => 'रक्तगट';

  @override
  String get bloodGroupHint => 'उदा. O+';

  @override
  String get address => 'पत्ता';

  @override
  String get addressHint => 'संपूर्ण पत्ता';

  @override
  String get medicalHistory => 'वैद्यकीय इतिहास';

  @override
  String get medicalHistoryHint => 'ऍलर्जी, जुने आजार...';

  @override
  String get saveDetails => 'माहिती जतन करा';

  @override
  String get profileUpdated => 'प्रोफाइल यशस्वीरित्या अद्ययावत झाले';

  @override
  String updateFailed(String error) {
    return 'अद्यतन अयशस्वी: $error';
  }

  @override
  String get volunteerAvailability => 'स्वयंसेवक उपलब्धता';

  @override
  String get volunteerAvailabilitySubtitle =>
      'सर्व्हरच्या लाइव्ह स्थितीत दिसते.';

  @override
  String get enableLocationSync => 'लोकेशन सिंक चालू करा';

  @override
  String get enableLocationSyncSubtitle => 'लाइव्ह आपत्ती देखरेखीसाठी आवश्यक.';

  @override
  String get syncNow => 'आता सिंक करा';

  @override
  String get locationSynced => 'लोकेशन यशस्वीरित्या सिंक झाले';

  @override
  String locationSyncFailed(String error) {
    return 'लोकेशन सिंक अयशस्वी: $error';
  }

  @override
  String get markedActive => 'तुम्ही आता सक्रिय आहात.';

  @override
  String get markedInactive => 'तुम्ही आता निष्क्रिय आहात.';

  @override
  String availabilityUpdateFailed(String error) {
    return 'उपलब्धता अद्यतन अयशस्वी: $error';
  }

  @override
  String get availabilityVolunteerOnly =>
      'उपलब्धता आणि लोकेशन फक्त स्वयंसेवक लॉगिनवर चालू आहे.';

  @override
  String get manageAccount => 'खाते व्यवस्थापित करा';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get tinymlTitle => 'TinyML सेन्सर संरक्षण';

  @override
  String get tinymlActive => 'सक्रिय — रिअल-टाइम अपघात आणि स्थिरता शोध';

  @override
  String get tinymlDisabled => 'बंद — हालचाल निरीक्षण थांबवले आहे';

  @override
  String get photo => 'फोटो';

  @override
  String get photos => 'फोटो';

  @override
  String get tapToViewDetails => 'तपशील आणि फोटो पाहण्यासाठी टॅप करा';

  @override
  String get loadingPhoto => 'फोटो लोड होत आहे…';

  @override
  String get photoFailed => 'फोटो लोड होऊ शकला नाही';

  @override
  String get noPhoto => 'फोटो नाही';

  @override
  String get retryPhoto => 'पुन्हा प्रयत्न करा';

  @override
  String get unnamed => 'अनामिक';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get found => 'सापडले';

  @override
  String get statusMissing => 'बेपत्ता';

  @override
  String get ageLabel => 'वय';

  @override
  String get statusLabel => 'स्थिती';

  @override
  String get description => 'वर्णन';

  @override
  String get reporterPhone => 'रिपोर्टर फोन';

  @override
  String get lastSeen => 'शेवटचे दिसले';

  @override
  String get assignedTo => 'नेमून दिले';

  @override
  String get unassigned => 'नेमलेले नाही';
}
