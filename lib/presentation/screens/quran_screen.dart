import 'package:flutter/material.dart';
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
    QuranLibrary().init();
    QuranLibrary().initTafsir();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: QuranLibraryScreen(),
    );
  }
}
