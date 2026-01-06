import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';

class QiblahCompassEvent {
  final double? heading;
  final double? accuracy;

  QiblahCompassEvent({this.heading, this.accuracy});
}

class QiblahService {
  static const double _smoothingFactor = 0.2;
  double? _lastSmoothedHeading;

  Stream<QiblahCompassEvent> get compassStream =>
      FlutterCompass.events!.map((event) => QiblahCompassEvent(
            heading: _smoothHeading(event.heading),
            accuracy: event.accuracy,
          ));

  double? _smoothHeading(double? newHeading) {
    if (newHeading == null) return null;
    if (_lastSmoothedHeading == null) {
      _lastSmoothedHeading = newHeading;
      return newHeading;
    }

    double diff = newHeading - _lastSmoothedHeading!;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    _lastSmoothedHeading = _lastSmoothedHeading! + (_smoothingFactor * diff);

    _lastSmoothedHeading = (_lastSmoothedHeading! + 360) % 360;

    return _lastSmoothedHeading;
  }

  double calculateQiblaBearing(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    return Qibla(coordinates).direction;
  }
}
