import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
    Locale('mr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sahyog'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'DISASTER RESPONSE NETWORK'**
  String get appTagline;

  /// No description provided for @sos_alert.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert'**
  String get sos_alert;

  /// No description provided for @detecting_activity.
  ///
  /// In en, this message translates to:
  /// **'Detecting activity'**
  String get detecting_activity;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English, Hindi, or Marathi. Changes apply instantly.'**
  String get languageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInHint.
  ///
  /// In en, this message translates to:
  /// **'Connect with Google or use email'**
  String get signInHint;

  /// No description provided for @secureConnection.
  ///
  /// In en, this message translates to:
  /// **'Secure SSL Encrypted Connection'**
  String get secureConnection;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @noEmailLinked.
  ///
  /// In en, this message translates to:
  /// **'No email linked'**
  String get noEmailLinked;

  /// No description provided for @citizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get citizen;

  /// No description provided for @healthContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Health & Contact Details'**
  String get healthContactDetails;

  /// No description provided for @healthContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update info for emergency responders'**
  String get healthContactSubtitle;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @bloodGroupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. O+'**
  String get bloodGroupHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Full physical address'**
  String get addressHint;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @medicalHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Allergies, chronic conditions...'**
  String get medicalHistoryHint;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @volunteerAvailability.
  ///
  /// In en, this message translates to:
  /// **'Volunteer Availability'**
  String get volunteerAvailability;

  /// No description provided for @volunteerAvailabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reflects directly to server live status.'**
  String get volunteerAvailabilitySubtitle;

  /// No description provided for @enableLocationSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Location Sync'**
  String get enableLocationSync;

  /// No description provided for @enableLocationSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for live disaster monitoring.'**
  String get enableLocationSyncSubtitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @locationSynced.
  ///
  /// In en, this message translates to:
  /// **'Location synced successfully'**
  String get locationSynced;

  /// No description provided for @locationSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Location sync failed: {error}'**
  String locationSyncFailed(String error);

  /// No description provided for @markedActive.
  ///
  /// In en, this message translates to:
  /// **'You are now marked active.'**
  String get markedActive;

  /// No description provided for @markedInactive.
  ///
  /// In en, this message translates to:
  /// **'You are now marked inactive.'**
  String get markedInactive;

  /// No description provided for @availabilityUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Availability update failed: {error}'**
  String availabilityUpdateFailed(String error);

  /// No description provided for @availabilityVolunteerOnly.
  ///
  /// In en, this message translates to:
  /// **'Availability and location toggle are enabled only for volunteer login.'**
  String get availabilityVolunteerOnly;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage Account'**
  String get manageAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @tinymlTitle.
  ///
  /// In en, this message translates to:
  /// **'TinyML Sensor Safeguard'**
  String get tinymlTitle;

  /// No description provided for @tinymlActive.
  ///
  /// In en, this message translates to:
  /// **'Active — Real-time crash & immobility detector'**
  String get tinymlActive;

  /// No description provided for @tinymlDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled — Motion monitoring paused'**
  String get tinymlDisabled;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @tapToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details and photos'**
  String get tapToViewDetails;

  /// No description provided for @loadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Loading photo…'**
  String get loadingPhoto;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load photo'**
  String get photoFailed;

  /// No description provided for @noPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo attached'**
  String get noPhoto;

  /// No description provided for @retryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryPhoto;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'FOUND'**
  String get found;

  /// No description provided for @statusMissing.
  ///
  /// In en, this message translates to:
  /// **'MISSING'**
  String get statusMissing;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reporterPhone.
  ///
  /// In en, this message translates to:
  /// **'Reporter phone'**
  String get reporterPhone;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @holdForSos.
  ///
  /// In en, this message translates to:
  /// **'HOLD FOR SOS'**
  String get holdForSos;

  /// No description provided for @holdToRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'Hold 5s to request help'**
  String get holdToRequestHelp;

  /// No description provided for @slideAType.
  ///
  /// In en, this message translates to:
  /// **'Slide a type • {seconds}s'**
  String slideAType(String seconds);

  /// No description provided for @keepHoldingSlide.
  ///
  /// In en, this message translates to:
  /// **'Keep holding — slide to {type}'**
  String keepHoldingSlide(String type);

  /// No description provided for @sosActive.
  ///
  /// In en, this message translates to:
  /// **'SOS ACTIVE'**
  String get sosActive;

  /// No description provided for @holdToCancelSos.
  ///
  /// In en, this message translates to:
  /// **'Hold 5s to cancel the SOS'**
  String get holdToCancelSos;

  /// No description provided for @releasing.
  ///
  /// In en, this message translates to:
  /// **'RELEASING...'**
  String get releasing;

  /// No description provided for @releaseIn.
  ///
  /// In en, this message translates to:
  /// **'Release in {seconds}s'**
  String releaseIn(String seconds);

  /// No description provided for @disasterFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get disasterFlood;

  /// No description provided for @disasterEarthquake.
  ///
  /// In en, this message translates to:
  /// **'Quake'**
  String get disasterEarthquake;

  /// No description provided for @disasterFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get disasterFire;

  /// No description provided for @disasterLandslide.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get disasterLandslide;

  /// No description provided for @disasterMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get disasterMedical;

  /// No description provided for @disasterAccident.
  ///
  /// In en, this message translates to:
  /// **'Crash'**
  String get disasterAccident;

  /// No description provided for @disasterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get disasterOther;

  /// No description provided for @recentDisasterAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Disaster Alerts'**
  String get recentDisasterAlerts;

  /// No description provided for @reportMissing.
  ///
  /// In en, this message translates to:
  /// **'Report Missing'**
  String get reportMissing;

  /// No description provided for @volunteer.
  ///
  /// In en, this message translates to:
  /// **'VOLUNTEER'**
  String get volunteer;

  /// No description provided for @coordinator.
  ///
  /// In en, this message translates to:
  /// **'COORDINATOR'**
  String get coordinator;
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
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

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
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
