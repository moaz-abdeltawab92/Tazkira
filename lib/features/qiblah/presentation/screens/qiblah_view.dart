import 'package:tazkira_app/core/routing/route_export.dart';

class QiblahView extends StatelessWidget {
  const QiblahView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QiblahCubit(
        service: QiblahService(),
        locationService: LocationService(),
      )..init(),
      child: const _QiblahViewContent(),
    );
  }
}

class _QiblahViewContent extends StatelessWidget {
  const _QiblahViewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7CB9AD), Color(0xFF5A9A8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<QiblahCubit, QiblahState>(
          builder: (context, state) {
            if (state.status == QiblahStatus.error) {
              return _buildErrorState(context, state);
            } else if (!state.hasMagnetometer) {
              return _buildFallbackState(context, state);
            } else {
              return Stack(
                children: [
                  _buildSuccessState(context, state),
                  if (state.isCalibrationNeeded)
                    _buildCalibrationOverlay(context),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QiblahState state) {
    // Check if error is related to location permission
    final isPermissionError = state.message?.contains('الصلاحية') ?? false;
    final isLocationServiceError =
        state.message?.contains('خدمة الموقع') ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPermissionError || isLocationServiceError
                ? Icons.location_off_rounded
                : Icons.error,
            size: 64,
            color: isPermissionError || isLocationServiceError
                ? const Color(0xFF7CB9AD)
                : Colors.red,
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              state.message ?? 'حدث خطأ',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          if (isPermissionError)
            // Show "Open Settings" button for permission errors
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  icon: const Icon(Icons.settings, size: 20),
                  label: Text(
                    'فتح الإعدادات',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7CB9AD),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () {
                    context.read<QiblahCubit>().init();
                  },
                  child: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF7CB9AD),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            // Show only "Try Again" for other errors
            ElevatedButton(
              onPressed: () {
                context.read<QiblahCubit>().init();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7CB9AD),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalibrationOverlay(BuildContext context) {
    return Positioned(
      top: 20.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.vibration, color: Colors.orange, size: 24),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'البوصلة غير دقيقة، يرجى تحريك الهاتف بحركة 8 (∞) للمعايرة',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackState(BuildContext context, QiblahState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off_outlined,
                size: 80, color: Color(0xFF7CB9AD)),
            SizedBox(height: 24.h),
            Text(
              'عذراً، هاتفك لا يدعم مستشعر البوصلة',
              style: GoogleFonts.cairo(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C5F4F),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'يمكنك معرفة القبلة من خلال وضع الهاتف في اتجاه القبلة التقريبي بناءً على موقعك:\nالقبلة تبعد ${state.qiblahBearing.toStringAsFixed(1)} درجة من الشمال الحقيقي.',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<QiblahCubit>().init();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'حاول مرة أخرى',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7CB9AD),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, QiblahState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A9A8E),
            Color(0xFF7CB9AD),
            Color(0xFFB8DDD5),
            Color(0xFFE8F5F3),
            Color(0xFFF5FFFE),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: CompassWidget(
              headingAngle: state.headingAngle,
              qiblahAngle: state.qiblahAngle,
              isAligned: state.isAligned,
              isLoading: state.status == QiblahStatus.loading,
              sensorAccuracy: state.sensorAccuracy,
            ),
          ),
        ],
      ),
    );
  }
}
