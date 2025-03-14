import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

void showAlert({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = "متابعة التسبيح",
  VoidCallback? onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          title,
          style:
              GoogleFonts.cairo(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style:
              GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) onConfirm();
            },
            child: Text(
              confirmText,
              style: GoogleFonts.tajawal(
                  fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
