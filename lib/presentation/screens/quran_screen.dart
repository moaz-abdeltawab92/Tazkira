import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initQuranLibrary();
  }

  Future<void> _initQuranLibrary() async {
    await QuranLibrary().init();
    await QuranLibrary().initTafsir();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : const QuranLibraryScreen(),
    );
  }
}
