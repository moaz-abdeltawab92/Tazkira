import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';

class QiblahCubit extends Cubit<QiblahState> {
  QiblahCubit({required this.service, required this.locationService})
      : super(const QiblahState());

  final QiblahService service;
  final LocationService locationService;

  StreamSubscription<QiblahCompassEvent>? _qiblahSubscription;
  StreamSubscription<ServiceStatus>? _locationSubscription;
  bool _isInitialized = false;
  Position? _currentPosition;
  Timer? _stillnessTimer;
  Timer? _initTimeoutTimer;
  double? _lastHeading;
  int _stillnessCount = 0;

  static const double _alignmentThreshold = 0.09;

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

    if (FlutterCompass.events == null) {
      emit(state.copyWith(
        status: QiblahStatus.success,
        hasMagnetometer: false,
      ));
      return;
    }

    await _qiblahSubscription?.cancel();
    _hasTriggeredFeedback = false;

    _qiblahSubscription = service.compassStream.listen(
      _handleCompassData,
      onError: (error) => emit(
        state.copyWith(
          status: QiblahStatus.error,
          message: 'خطأ في بوصلة القبلة: $error',
        ),
      ),
    );

    _initTimeoutTimer?.cancel();
    _initTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (state.status == QiblahStatus.loading ||
          (state.status == QiblahStatus.success && _lastHeading == null)) {
        if (!isClosed) {
          emit(state.copyWith(
            status: QiblahStatus.success,
            hasMagnetometer: false,
          ));
        }
      }
    });
  }

  Future<void> _handleCompassData(QiblahCompassEvent data) async {
    _initTimeoutTimer?.cancel();

    if (_currentPosition == null) {
      try {
        _currentPosition = await locationService.getCurrentPosition();
      } catch (e) {}
    }

    double qiblahBearing = 0.0;
    if (_currentPosition != null) {
      qiblahBearing = service.calculateQiblaBearing(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    final heading = data.heading;
    final accuracy = data.accuracy;

    if (heading != null) {
      if (_lastHeading != null && (heading - _lastHeading!).abs() < 0.001) {
        _stillnessCount++;
      } else {
        _stillnessCount = 0;
      }
      _lastHeading = heading;
    }

    _stillnessTimer?.cancel();
    _stillnessTimer = Timer(const Duration(seconds: 3), () {
      if (state.status == QiblahStatus.success && state.hasMagnetometer) {
        emit(state.copyWith(hasMagnetometer: false));
      }
    });

    bool hasMagnetometer = state.hasMagnetometer;
    bool calibrationNeeded = false;

    if (heading == null || _stillnessCount > 50) {
      hasMagnetometer = false;
    } else if (accuracy != null) {
      if (Platform.isAndroid) {
        if (accuracy < 2) {
          calibrationNeeded = true;
        }
      } else if (Platform.isIOS) {
        if (accuracy < 0 || accuracy > 20) {
          calibrationNeeded = true;
        }
      }
    }

    final currentHeading = heading ?? 0.0;

    final headingRad = -currentHeading * pi / 180;
    final qiblahRad = (qiblahBearing - currentHeading) * pi / 180;

    final isAligned = (qiblahRad % (2 * pi)).abs() < _alignmentThreshold;

    _triggerHapticFeedback(isAligned);

    emit(
      state.copyWith(
        status: QiblahStatus.success,
        qiblahAngle: qiblahRad,
        headingAngle: headingRad,
        isAligned: isAligned,
        sensorAccuracy: accuracy,
        isCalibrationNeeded: calibrationNeeded,
        qiblahBearing: qiblahBearing,
        userLocation: _currentPosition,
        hasMagnetometer: hasMagnetometer,
      ),
    );
  }

  @override
  Future<void> close() async {
    _stillnessTimer?.cancel();
    _initTimeoutTimer?.cancel();
    await _qiblahSubscription?.cancel();
    await _locationSubscription?.cancel();
    return super.close();
  }

  void _triggerHapticFeedback(bool isAligned) {
    if (isAligned && !_hasTriggeredFeedback) {
      HapticFeedback.heavyImpact();
      _hasTriggeredFeedback = true;
    } else if (!isAligned) {
      _hasTriggeredFeedback = false;
    }
  }

  bool _hasTriggeredFeedback = false;
}
