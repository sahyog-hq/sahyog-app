import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Opens turn-by-turn navigation in native Google Maps or Apple Maps.
  static Future<bool> openDirections(double latitude, double longitude, {String? label}) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'SOS');

    try {
      if (!kIsWeb && Platform.isIOS) {
        final appleMapsUrl = Uri.parse(
          'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d&q=$encodedLabel',
        );
        if (await canLaunchUrl(appleMapsUrl)) {
          return await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        }
      }

      if (!kIsWeb && Platform.isAndroid) {
        // google.navigation opens the Maps app already in directions mode.
        // canLaunchUrl returns false on Android 11+ unless every scheme is
        // declared, so try the intents directly.
        final navigationUrl = Uri.parse(
          'google.navigation:q=$latitude,$longitude&mode=d',
        );
        if (await launchUrl(navigationUrl, mode: LaunchMode.externalApplication)) {
          return true;
        }

        final geoUrl = Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)',
        );
        if (await launchUrl(geoUrl, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }

      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
      );
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (_) {}
    return false;
  }

  /// Opens the given coordinates pinned in external maps
  static Future<bool> openMapLocation(double latitude, double longitude, {String? label}) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (!kIsWeb && Platform.isIOS) {
        final Uri appleMapsUrl = Uri.parse(
          'https://maps.apple.com/?ll=$latitude,$longitude${label != null ? '&q=${Uri.encodeComponent(label)}' : ''}',
        );
        if (await canLaunchUrl(appleMapsUrl)) {
          return await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        }
      }

      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
