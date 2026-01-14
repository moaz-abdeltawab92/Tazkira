import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazkira_app/core/services/daily_quote_service.dart';
import 'package:share_plus/share_plus.dart';

class DailyQuoteWidget extends StatefulWidget {
  const DailyQuoteWidget({super.key});

  @override
  State<DailyQuoteWidget> createState() => _DailyQuoteWidgetState();
}

class _DailyQuoteWidgetState extends State<DailyQuoteWidget> {
  Map<String, dynamic>? _quote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final quote = await DailyQuoteService.getDailyQuote();
    setState(() {
      _quote = quote;
      _isLoading = false;
    });
  }

  void _shareQuote() {
    if (_quote != null) {
      final text = '${_quote!['text']}\n\n${_quote!['source']}\n\n';
      // ignore: deprecated_member_use
      Share.share(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7CB9AD).withOpacity(0.3),
              const Color(0xFF5A9A8E).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_quote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7CB9AD).withOpacity(0.3),
            const Color(0xFF5A9A8E).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF7CB9AD).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24.sp,
                ),
                onPressed: _shareQuote,
              ),
              Text(
                DailyQuoteService.getQuoteTypeName(_quote!['type']),
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Quote Text
          Text(
            _quote!['text'],
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.8,
            ),
          ),
          SizedBox(height: 12.h),

          // Source
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _quote!['source'],
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
