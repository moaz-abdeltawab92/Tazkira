import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/screens/homepage.dart';

void main() async {
  //To fix text being hidden bug in flutter_screenutil in release mode
  await ScreenUtil.ensureScreenSize();
  runApp(const TazkiraApp());
}

class TazkiraApp extends StatelessWidget {
  const TazkiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
          ),
          debugShowCheckedModeBanner: false,
          home: const Homepage(),
        );
      },
    );
  }
}
