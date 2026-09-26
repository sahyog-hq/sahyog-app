import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permission helpers so location, camera, and uploads work on
/// Android 13+ and iOS (permission_handler needs Podfile macros there).
class AppPermissions {
  AppPermissions._();

  static Future<void> requestLaunchPermissions() async {
    if (kIsWeb) return;
    await ensureLocation(openSettingsIfDenied: false);
    await Permission.notification.request();
  }

  static Future<bool> ensureLocation({bool openSettingsIfDenied = true}) async {
    if (kIsWeb) return true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (openSettingsIfDenied) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfDenied) {
        await Geolocator.openAppSettings();
      }
      return false;
    }
    if (permission == LocationPermission.denied) return false;

    await Permission.locationWhenInUse.request();
    return true;
  }

  static Future<bool> ensureCamera() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensurePhotos() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited || status.isPermanentlyDenied;
    }
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  static Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 70,
  }) async {
    final ok = source == ImageSource.camera
        ? await ensureCamera()
        : await ensurePhotos();
    if (!ok && source == ImageSource.camera) return null;
    try {
      return ImagePicker().pickImage(
        source: source,
        imageQuality: imageQuality,
      );
    } catch (e) {
      debugPrint('[AppPermissions] pickImage failed: $e');
      return null;
    }
  }
}
