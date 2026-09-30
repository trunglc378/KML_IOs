import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/entities/location_entity.dart';
import '../domain/repositories/location_collector_repository.dart';

/// Trien khai thu thap vi tri GPS su dung geolocator (FR-IO-LOC-01, FR-IO-LOC-02).
class LocationCollectorRepositoryImpl implements LocationCollectorRepository {
  @override
  Future<bool> hasPermission() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<LocationEntity?> getCurrentLocation() async {
    final bool allowed = await hasPermission();
    if (!allowed) {
      final bool granted = await requestPermission();
      if (!granted) return null;
    }

    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationEntity(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LocationEntity> get continuousLocationStream {
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((Position pos) => LocationEntity(
              latitude: pos.latitude,
              longitude: pos.longitude,
              accuracy: pos.accuracy,
              altitude: pos.altitude,
              speed: pos.speed,
              heading: pos.heading,
              timestamp: pos.timestamp,
            ));
  }
}
