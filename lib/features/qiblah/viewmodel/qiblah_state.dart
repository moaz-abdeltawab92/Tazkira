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
      );
}
