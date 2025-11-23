import 'package:tazkira_app/core/routing/route_export.dart';
import '../widgets/compass_widget.dart';

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
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.qiblahAngle != current.qiblahAngle,
          builder: (context, state) {
            if (state.status == QiblahStatus.error) {
              return _buildErrorState(context, state);
            } else {
              return _buildSuccessState(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QiblahState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'خطأ: ${state.message}',
              style: GoogleFonts.cairo(fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16.h),
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
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CompassWidget(
                headingAngle: state.headingAngle,
                qiblahAngle: state.qiblahAngle,
                isAligned: state.isAligned,
                isLoading: state.status == QiblahStatus.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
