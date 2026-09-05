import 'dart:async';

import 'package:geolocator/geolocator.dart';

class RoadLocation {
  final double latitude;
  final double longitude;

  const RoadLocation({required this.latitude, required this.longitude});
}

class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  Future<bool> checkLocationService() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<RoadLocation> getCurrentLocation() async {
    final serviceEnabled = await checkLocationService();
    if (!serviceEnabled) {
      throw const LocationException('Please enable location services.');
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is required to save the road damage location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it from app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      return RoadLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      throw const LocationException('Location timeout. Please try again.');
    } catch (_) {
      throw const LocationException('GPS unavailable. Please try again.');
    }
  }
}
