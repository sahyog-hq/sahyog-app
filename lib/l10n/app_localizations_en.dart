// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sahyog';

  @override
  String get appTagline => 'DISASTER RESPONSE NETWORK';

  @override
  String get sos_alert => 'SOS Alert';

  @override
  String get detecting_activity => 'Detecting activity';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle =>
      'English, Hindi, or Marathi. Changes apply instantly.';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get marathi => 'मराठी';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInHint => 'Connect with Google or use email';

  @override
  String get secureConnection => 'Secure SSL Encrypted Connection';

  @override
  String get orDivider => 'OR';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get missing => 'Missing';

  @override
  String get profile => 'Profile';

  @override
  String get sos => 'SOS';

  @override
  String get tasks => 'Tasks';

  @override
  String get operations => 'Operations';

  @override
  String get noEmailLinked => 'No email linked';

  @override
  String get citizen => 'CITIZEN';

  @override
  String get healthContactDetails => 'Health & Contact Details';

  @override
  String get healthContactSubtitle => 'Update info for emergency responders';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get bloodGroupHint => 'e.g. O+';

  @override
  String get address => 'Address';

  @override
  String get addressHint => 'Full physical address';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get medicalHistoryHint => 'Allergies, chronic conditions...';

  @override
  String get saveDetails => 'Save Details';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get volunteerAvailability => 'Volunteer Availability';

  @override
  String get volunteerAvailabilitySubtitle =>
      'Reflects directly to server live status.';

  @override
  String get enableLocationSync => 'Enable Location Sync';

  @override
  String get enableLocationSyncSubtitle =>
      'Required for live disaster monitoring.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get locationSynced => 'Location synced successfully';

  @override
  String locationSyncFailed(String error) {
    return 'Location sync failed: $error';
  }

  @override
  String get markedActive => 'You are now marked active.';

  @override
  String get markedInactive => 'You are now marked inactive.';

  @override
  String availabilityUpdateFailed(String error) {
    return 'Availability update failed: $error';
  }

  @override
  String get availabilityVolunteerOnly =>
      'Availability and location toggle are enabled only for volunteer login.';

  @override
  String get manageAccount => 'Manage Account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get tinymlTitle => 'TinyML Sensor Safeguard';

  @override
  String get tinymlActive => 'Active — Real-time crash & immobility detector';

  @override
  String get tinymlDisabled => 'Disabled — Motion monitoring paused';

  @override
  String get photo => 'Photo';

  @override
  String get photos => 'Photos';

  @override
  String get tapToViewDetails => 'Tap to view details and photos';

  @override
  String get loadingPhoto => 'Loading photo…';

  @override
  String get photoFailed => 'Could not load photo';

  @override
  String get noPhoto => 'No photo attached';

  @override
  String get retryPhoto => 'Retry';

  @override
  String get unnamed => 'Unnamed';

  @override
  String get unknown => 'Unknown';

  @override
  String get found => 'FOUND';

  @override
  String get statusMissing => 'MISSING';

  @override
  String get ageLabel => 'Age';

  @override
  String get statusLabel => 'Status';

  @override
  String get description => 'Description';

  @override
  String get reporterPhone => 'Reporter phone';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get holdForSos => 'HOLD FOR SOS';

  @override
  String get holdToRequestHelp => 'Hold 5s to request help';

  @override
  String slideAType(String seconds) {
    return 'Slide a type • ${seconds}s';
  }

  @override
  String keepHoldingSlide(String type) {
    return 'Keep holding — slide to $type';
  }

  @override
  String get sosActive => 'SOS ACTIVE';

  @override
  String get holdToCancelSos => 'Hold 5s to cancel the SOS';

  @override
  String get releasing => 'RELEASING...';

  @override
  String releaseIn(String seconds) {
    return 'Release in ${seconds}s';
  }

  @override
  String get disasterFlood => 'Flood';

  @override
  String get disasterEarthquake => 'Quake';

  @override
  String get disasterFire => 'Fire';

  @override
  String get disasterLandslide => 'Slide';

  @override
  String get disasterMedical => 'Medical';

  @override
  String get disasterAccident => 'Crash';

  @override
  String get disasterOther => 'Other';

  @override
  String get recentDisasterAlerts => 'Recent Disaster Alerts';

  @override
  String get reportMissing => 'Report Missing';

  @override
  String get volunteer => 'VOLUNTEER';

  @override
  String get coordinator => 'COORDINATOR';
}
