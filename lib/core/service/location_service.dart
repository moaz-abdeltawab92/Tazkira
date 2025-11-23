import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<ServiceStatus> get serviceStatusStream =>
      Geolocator.getServiceStatusStream();

  Future<LocationStatus> checkLocationStatus() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isServiceEnabled) {
      return const LocationStatus(isGranted: false, isServiceEnabled: false);
    }

    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final requestedPermission = await Geolocator.requestPermission();
      return LocationStatus(
        isGranted: requestedPermission == LocationPermission.always ||
            requestedPermission == LocationPermission.whileInUse,
        isServiceEnabled: true,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationStatus(isGranted: false, isServiceEnabled: true);
    }

    return LocationStatus(
      isGranted: permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse,
      isServiceEnabled: true,
    );
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

class LocationStatus {
  const LocationStatus(
      {required this.isGranted, required this.isServiceEnabled});

  final bool isGranted;
  final bool isServiceEnabled;
}
