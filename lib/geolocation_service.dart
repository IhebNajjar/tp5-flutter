import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Future<Position?> getCurrentPosition() async {
    // Return null immediately in test environments to prevent unhandled platform channel hangs
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return null;
      }
    } catch (_) {}

    try {
      // 1. Check & request permission
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

      // 3. Fetch position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Geolocation error or unsupported platform: $e');
      return null;
    }
  }
}
