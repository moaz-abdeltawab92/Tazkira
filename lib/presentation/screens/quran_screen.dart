import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_library/quran_library.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    QuranLibrary().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF3E3131),
        title: Text(
          "القرآن الكريم",
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: double.infinity,
        color: isDarkMode ? Colors.black : Colors.white,
        child: QuranLibraryScreen(
          downloadFontsDialogStyle: DownloadFontsDialogStyle(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          ),
          isDark: isDarkMode,
        ),
      ),
    );
  }
}
