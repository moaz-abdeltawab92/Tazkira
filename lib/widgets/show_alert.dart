import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showAlert({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = " متابعة التسبيح",
  VoidCallback? onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
