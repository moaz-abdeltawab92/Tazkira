import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tazkira_app/widgets/home_body.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff9CB0AE),
          title: Text(
            "تَذْكِرَة",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            width: 1.sw,
            height: 1.sh,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/back_ground.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: const HomeBody(),
          ),
        ),
      ),
    );
  }
}
