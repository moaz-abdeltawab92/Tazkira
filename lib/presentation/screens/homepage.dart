import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/presentation/widgets/home/home_body.dart';

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
          backgroundColor: const Color.fromARGB(255, 175, 197, 195),
          title: Text(
            "تَذْكِرَة",
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: 24.sp.clamp(18, 28),
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/back_ground.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const HomeBody(),
              ),
            );
          },
        ),
      ),
    );
  }
}
