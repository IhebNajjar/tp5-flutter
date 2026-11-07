import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Future<Position?> getCurrentPosition() async {
    // Return null immediately in test environments to prevent unhandled platform channel hangs
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) {
          return null;
        }
      } catch (_) {}
    }

    try {
      if (!kIsWeb) {
        // 1. Check & request permission on native platforms
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }

        // 2. Ensure location services are enabled
        if (!(await Geolocator.isLocationServiceEnabled())) {
          return null;
        }
      }

      // 3. Fetch position with reasonable timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Geolocation error or unsupported platform: $e');
      return null;
    }
  }
}
