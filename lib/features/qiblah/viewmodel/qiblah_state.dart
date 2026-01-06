import 'package:tazkira_app/core/routing/route_export.dart';

enum QiblahStatus { initial, loading, success, error }

class QiblahState {
  const QiblahState({
    this.status = QiblahStatus.initial,
    this.message,
    this.qiblahAngle = 0.0,
    this.headingAngle = 0.0,
    this.isAligned = false,
    this.userLocation,
    this.routePoints,
    this.distance,
    this.duration,
    this.sensorAccuracy,
    this.hasMagnetometer = true,
    this.isCalibrationNeeded = false,
    this.qiblahBearing = 0.0,
  });

  final QiblahStatus status;
  final String? message;
  final double qiblahAngle;
  final double headingAngle;
  final bool isAligned;
  final Position? userLocation;
  final List<LatLng>? routePoints;
  final double? distance;
  final double? duration;
  final double? sensorAccuracy;
  final bool hasMagnetometer;
  final bool isCalibrationNeeded;
  final double qiblahBearing;

  QiblahState copyWith({
    QiblahStatus? status,
    String? message,
    double? qiblahAngle,
    double? headingAngle,
    bool? isAligned,
    Position? userLocation,
    List<LatLng>? routePoints,
    double? distance,
    double? duration,
    double? sensorAccuracy,
    bool? hasMagnetometer,
    bool? isCalibrationNeeded,
    double? qiblahBearing,
  }) =>
      QiblahState(
        status: status ?? this.status,
        message: message ?? this.message,
        qiblahAngle: qiblahAngle ?? this.qiblahAngle,
        headingAngle: headingAngle ?? this.headingAngle,
        isAligned: isAligned ?? this.isAligned,
        userLocation: userLocation ?? this.userLocation,
        routePoints: routePoints ?? this.routePoints,
        distance: distance ?? this.distance,
        duration: duration ?? this.duration,
        sensorAccuracy: sensorAccuracy ?? this.sensorAccuracy,
        hasMagnetometer: hasMagnetometer ?? this.hasMagnetometer,
        isCalibrationNeeded: isCalibrationNeeded ?? this.isCalibrationNeeded,
        qiblahBearing: qiblahBearing ?? this.qiblahBearing,
      );
}
