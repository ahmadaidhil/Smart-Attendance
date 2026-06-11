import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    required int radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lng1: userLng,
      lat2: targetLat,
      lng2: targetLng,
    );
    return distance <= radiusMeters;
  }

  Future<LocationValidationResult> validateLocation({
    required double targetLat,
    required double targetLng,
    required int radiusMeters,
  }) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      return LocationValidationResult(
        isValid: false,
        message: 'Izin lokasi diperlukan untuk absensi',
        distance: null,
      );
    }

    final position = await getCurrentPosition();
    if (position == null) {
      return LocationValidationResult(
        isValid: false,
        message: 'Tidak dapat mengambil lokasi. Pastikan GPS aktif.',
        distance: null,
      );
    }

    final distance = calculateDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: targetLat,
      lng2: targetLng,
    );

    final isValid = distance <= radiusMeters;
    return LocationValidationResult(
      isValid: isValid,
      message: isValid
          ? 'Lokasi valid (${distance.toStringAsFixed(0)}m dari kelas)'
          : 'Anda berada ${distance.toStringAsFixed(0)}m dari kelas. Batas: ${radiusMeters}m',
      distance: distance,
      position: position,
    );
  }
}

class LocationValidationResult {
  final bool isValid;
  final String message;
  final double? distance;
  final Position? position;

  const LocationValidationResult({
    required this.isValid,
    required this.message,
    this.distance,
    this.position,
  });
}
