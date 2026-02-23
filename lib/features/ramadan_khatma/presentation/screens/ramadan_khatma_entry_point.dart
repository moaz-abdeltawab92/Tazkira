import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/features/ramadan_khatma/data/services/khatma_storage_service.dart';
import 'package:tazkira_app/features/ramadan_khatma/presentation/screens/khatma_selection_screen.dart';
import 'package:tazkira_app/features/ramadan_khatma/presentation/screens/khatma_tracking_screen.dart';

class RamadanKhatmaEntryPoint extends StatefulWidget {
  const RamadanKhatmaEntryPoint({super.key});

  @override
  State<RamadanKhatmaEntryPoint> createState() =>
      _RamadanKhatmaEntryPointState();
}

class _RamadanKhatmaEntryPointState extends State<RamadanKhatmaEntryPoint> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkKhatmaStatus();
  }

  Future<void> _checkKhatmaStatus() async {
    try {
      // Check if user has already started a khatma
      final progress = await KhatmaStorageService.loadKhatmaProgress();

      if (!mounted) return;

      if (progress != null) {
        // User has started, go to tracking screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => KhatmaTrackingScreen(initialProgress: progress),
          ),
        );
      } else {
        // New user, show selection screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const KhatmaSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      // If any error occurs, show error screen instead of crashing
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'حدث خطأ في تحميل البيانات';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6BA598),
          title: Text(
            'ختمة رمضان',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                  });
                  _checkKhatmaStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6BA598),
                ),
                child: Text(
                  'حاول مرة أخرى',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6BA598),
        ),
      ),
    );
  }
}
