import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/service/location_service.dart';
import '../service/qiblah_service.dart';
import 'qiblah_state.dart';

class QiblahCubit extends Cubit<QiblahState> {
  QiblahCubit({required this.service, required this.locationService})
      : super(const QiblahState());

  final QiblahService service;
  final LocationService locationService;

  StreamSubscription<QiblahDirection>? _qiblahSubscription;
  StreamSubscription<ServiceStatus>? _locationSubscription;
  bool _hasTriggeredFeedback = false;
  bool _isInitialized = false;

  static const double _alignmentThreshold = 0.09;
  static const double _degreesToRadians = pi / 180;

  /// Initializes listeners
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    emit(
      state.copyWith(status: QiblahStatus.loading),
    );

    _setupLocationServiceListener();
    await _startIfGranted();
  }

  void _setupLocationServiceListener() {
    _locationSubscription = locationService.serviceStatusStream.listen(
      (status) async {
        if (status == ServiceStatus.enabled) {
          await _startIfGranted();
        } else {
          await _handleLocationServiceDisabled();
        }
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: QiblahStatus.error,
            message: 'خطأ في خدمة الموقع: $error',
          ),
        );
      },
    );
  }

  Future<void> _handleLocationServiceDisabled() async {
    await _qiblahSubscription?.cancel();
    emit(
      state.copyWith(
        status: QiblahStatus.error,
        message: 'من فضلك شغل خدمة الموقع لاستخدام البوصلة',
      ),
    );
  }

  Future<void> _startIfGranted() async {
    try {
      final status = await locationService.checkLocationStatus();
      if (status.isGranted) {
        await _startQiblahCompass();
      } else {
        emit(
          state.copyWith(
            status: QiblahStatus.error,
            message: 'الموقع مش متفعل أو الصلاحية مرفوضة',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: QiblahStatus.error,
          message: 'خطأ في التحقق من حالة الموقع: $error',
        ),
      );
    }
  }

  Future<void> _startQiblahCompass() async {
    if (state.status != QiblahStatus.loading) {
      emit(state.copyWith(status: QiblahStatus.loading));
    }

    await _qiblahSubscription?.cancel();
    _hasTriggeredFeedback = false;

    _qiblahSubscription = service.qiblahStream
        .distinct(
          (prev, curr) =>
              (prev.direction - curr.direction).abs() < 0.5 &&
              (prev.qiblah - curr.qiblah).abs() < 0.5,
        )
        .listen(
          _handleQiblahData,
          onError: (error) => emit(
            state.copyWith(
              status: QiblahStatus.error,
              message: 'خطأ في بوصلة القبلة: $error',
            ),
          ),
        );
  }

  void _handleQiblahData(QiblahDirection data) {
    final qiblahAngle = _validateAndConvertAngle(data.qiblah);
    final headingAngle = _validateAndConvertAngle(data.direction);
    final isAligned = (qiblahAngle % (2 * pi)).abs() < _alignmentThreshold;

    _triggerHapticFeedback(isAligned);

    emit(
      state.copyWith(
        status: QiblahStatus.success,
        qiblahAngle: qiblahAngle,
        headingAngle: headingAngle,
        isAligned: isAligned,
      ),
    );
  }

  double _validateAndConvertAngle(double angle) {
    if (angle.isNaN || !angle.isFinite) return 0.0;
    return -angle * _degreesToRadians;
  }

  void _triggerHapticFeedback(bool isAligned) {
    if (isAligned && !_hasTriggeredFeedback) {
      HapticFeedback.heavyImpact();
      _hasTriggeredFeedback = true;
    } else if (!isAligned) {
      _hasTriggeredFeedback = false;
    }
  }

  @override
  Future<void> close() async {
    await _qiblahSubscription?.cancel();
    await _locationSubscription?.cancel();
    return super.close();
  }
}
