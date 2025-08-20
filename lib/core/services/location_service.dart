import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../utils/exceptions.dart';
import '../../shared/models/user_model.dart' as user_models;

@singleton
class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const AppException('Location services are disabled. Please enable them in settings.');
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw const AppException('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const AppException('Location permissions are permanently denied. Please enable them in settings.');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to get current location: $e');
    }
  }

  // Get location from coordinates
  Future<user_models.Location> getLocationFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        throw const AppException('No location found for the given coordinates');
      }

      final placemark = placemarks.first;
      final city = placemark.locality ?? placemark.subAdministrativeArea ?? 'Unknown City';
      final state = placemark.administrativeArea ?? 'Unknown State';
      final country = placemark.country ?? 'Unknown Country';
      
      final formattedAddress = _formatAddress(placemark);

      return user_models.Location(
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
        country: country,
        formattedAddress: formattedAddress,
      );
    } catch (e) {
      if (e is AppException) rethrow;
  throw AppException('Failed to get location details: $e');
    }
  }

  // Get current location with details
  Future<user_models.Location> getCurrentLocation() async {
    try {
      final position = await getCurrentPosition();
      return await getLocationFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (e is AppException) rethrow;
  throw AppException('Failed to get current location with details: $e');
    }
  }

  // Calculate distance between two locations
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to kilometers
  }

  // Calculate distance between two Location objects
  double calculateDistanceBetweenLocations(user_models.Location location1, user_models.Location location2) {
    return calculateDistance(
      lat1: location1.latitude,
      lon1: location1.longitude,
      lat2: location2.latitude,
      lon2: location2.longitude,
    );
  }

  // Check if user is within a certain distance from a location
  bool isWithinDistance({
    required user_models.Location userLocation,
    required user_models.Location targetLocation,
    required double maxDistanceKm,
  }) {
    final distance = calculateDistanceBetweenLocations(userLocation, targetLocation);
    return distance <= maxDistanceKm;
  }

  // Get location stream for real-time updates
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: locationSettings ?? 
        const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // Update every 100 meters
        ),
    );
  }

  // Get location updates stream with details
  Stream<user_models.Location> getLocationStream() {
    return getPositionStream().asyncMap((position) async {
      return await getLocationFromCoordinates(position.latitude, position.longitude);
    });
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Get readable distance string
  String getDistanceString(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.round()} km away';
    }
  }

  // Search for places by name
  Future<List<user_models.Location>> searchPlaces(String query) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(query);
      
      List<user_models.Location> detailedLocations = [];
      for (var location in locations) {
        final detailedLocation = await getLocationFromCoordinates(
          location.latitude, 
          location.longitude,
        );
        detailedLocations.add(detailedLocation);
      }
      
      return detailedLocations;
    } catch (e) {
  throw AppException('Failed to search places: $e');
    }
  }

  // Get nearby users (would typically be implemented with a backend service)
  Future<List<String>> getNearbyUserIds({
    required user_models.Location userLocation,
    required double radiusKm,
  }) async {
    try {
      // This would typically involve querying a backend service
      // For now, return empty list as this requires geospatial queries
      // that are complex to implement with Firestore
  return const [];
    } catch (e) {
  throw AppException('Failed to get nearby users: $e');
    }
  }

  // Validate coordinates
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  // Format address from placemark
  String _formatAddress(geocoding.Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.locality?.isNotEmpty == true) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      addressParts.add(placemark.country!);
    }

    return addressParts.join(', ');
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider for current location
final currentLocationProvider = FutureProvider<user_models.Location>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

// Provider for location stream
final locationStreamProvider = StreamProvider<user_models.Location>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getLocationStream();
});

// Provider for location permission status
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.checkLocationPermission();
});
