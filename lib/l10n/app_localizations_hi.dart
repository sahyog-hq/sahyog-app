// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सहयोग';

  @override
  String get appTagline => 'आपदा प्रतिक्रिया नेटवर्क';

  @override
  String get sos_alert => 'एसओएस अलर्ट';

  @override
  String get detecting_activity => 'गतिविधि का पता लगाया जा रहा है';

  @override
  String get language => 'भाषा';

  @override
  String get languageSubtitle =>
      'अंग्रेज़ी, हिन्दी या मराठी। बदलाव तुरंत लागू होंगे।';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get marathi => 'मराठी';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signInHint => 'Google से जुड़ें या ईमेल का उपयोग करें';

  @override
  String get secureConnection => 'सुरक्षित SSL एन्क्रिप्टेड कनेक्शन';

  @override
  String get orDivider => 'या';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get home => 'होम';

  @override
  String get map => 'मानचित्र';

  @override
  String get missing => 'लापता';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get sos => 'एसओएस';

  @override
  String get tasks => 'कार्य';

  @override
  String get operations => 'संचालन';

  @override
  String get noEmailLinked => 'कोई ईमेल लिंक नहीं है';

  @override
  String get citizen => 'नागरिक';

  @override
  String get healthContactDetails => 'स्वास्थ्य और संपर्क विवरण';

  @override
  String get healthContactSubtitle => 'आपातकालीन टीम के लिए जानकारी अपडेट करें';

  @override
  String get bloodGroup => 'रक्त समूह';

  @override
  String get bloodGroupHint => 'जैसे O+';

  @override
  String get address => 'पता';

  @override
  String get addressHint => 'पूरा पता';

  @override
  String get medicalHistory => 'चिकित्सा इतिहास';

  @override
  String get medicalHistoryHint => 'एलर्जी, पुरानी बीमारियाँ...';

  @override
  String get saveDetails => 'विवरण सहेजें';

  @override
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई';

  @override
  String updateFailed(String error) {
    return 'अपडेट विफल: $error';
  }

  @override
  String get volunteerAvailability => 'स्वयंसेवक उपलब्धता';

  @override
  String get volunteerAvailabilitySubtitle =>
      'सर्वर की लाइव स्थिति में दिखता है।';

  @override
  String get enableLocationSync => 'लोकेशन सिंक चालू करें';

  @override
  String get enableLocationSyncSubtitle => 'लाइव आपदा निगरानी के लिए आवश्यक।';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get locationSynced => 'लोकेशन सफलतापूर्वक सिंक हुई';

  @override
  String locationSyncFailed(String error) {
    return 'लोकेशन सिंक विफल: $error';
  }

  @override
  String get markedActive => 'आप अब सक्रिय चिह्नित हैं।';

  @override
  String get markedInactive => 'आप अब निष्क्रिय चिह्नित हैं।';

  @override
  String availabilityUpdateFailed(String error) {
    return 'उपलब्धता अपडेट विफल: $error';
  }

  @override
  String get availabilityVolunteerOnly =>
      'उपलब्धता और लोकेशन केवल स्वयंसेवक लॉगिन पर चालू हैं।';

  @override
  String get manageAccount => 'खाता प्रबंधित करें';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get tinymlTitle => 'TinyML सेंसर सुरक्षा';

  @override
  String get tinymlActive =>
      'सक्रिय — वास्तविक समय दुर्घटना और गतिहीनता डिटेक्टर';

  @override
  String get tinymlDisabled => 'बंद — गति निगरानी रुकी हुई है';

  @override
  String get photo => 'फ़ोटो';

  @override
  String get photos => 'फ़ोटो';

  @override
  String get tapToViewDetails => 'विवरण और फ़ोटो देखने के लिए टैप करें';

  @override
  String get loadingPhoto => 'फ़ोटो लोड हो रही है…';

  @override
  String get photoFailed => 'फ़ोटो लोड नहीं हो सकी';

  @override
  String get noPhoto => 'कोई फ़ोटो नहीं';

  @override
  String get retryPhoto => 'फिर कोशिश करें';

  @override
  String get unnamed => 'अनाम';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get found => 'मिल गए';

  @override
  String get statusMissing => 'लापता';

  @override
  String get ageLabel => 'आयु';

  @override
  String get statusLabel => 'स्थिति';

  @override
  String get description => 'विवरण';

  @override
  String get reporterPhone => 'रिपोर्टर फ़ोन';

  @override
  String get lastSeen => 'अंतिम बार देखा';

  @override
  String get assignedTo => 'सौंपा गया';

  @override
  String get unassigned => 'अनियुक्त';
}
