import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationService {
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFF44336);
  static const Color _warningColor = Color(0xFFFF9800);
  static const Color _infoColor = Color(0xFF2196F3);

  static void showToast(
    String message, {
    Toast? toastLength,
    ToastGravity? gravity,
    int timeInSecForIosWeb = 1,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 16.0,
    FontWeight? fontWeight,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength ?? Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.TOP,
      timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor: backgroundColor ?? Colors.grey[800],
      textColor: textColor ?? Colors.white,
      fontSize: fontSize,
    );
  }

  static void showSuccessToast(String message) {
    showToast(
      message,
      backgroundColor: _successColor,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void showErrorToast(String message) {
    showToast(
      message,
      backgroundColor: _errorColor,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void showWarningToast(String message) {
    showToast(
      message,
      backgroundColor: _warningColor,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void showInfoToast(String message) {
    showToast(
      message,
      backgroundColor: _infoColor,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void showTopToast(String message, {bool isError = false}) {
    showToast(
      message,
      backgroundColor: isError ? _errorColor : _successColor,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor ?? Colors.grey[800],
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: _successColor,
      textColor: Colors.white,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: _errorColor,
      textColor: Colors.white,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: _warningColor,
      textColor: Colors.white,
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: _infoColor,
      textColor: Colors.white,
    );
  }
}
