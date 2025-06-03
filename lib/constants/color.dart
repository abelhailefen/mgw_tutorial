import 'package:flutter/material.dart';

class AppColors {
  // --- Light Theme Specific Colors ---
  static const Color primaryLight = Color(0xFF1976D2); // Colors.blue[700]
  static const Color onPrimaryLight = Colors.white;
  static const Color secondaryLight = Color(0xFF448AFF); // Colors.blueAccent
  static const Color backgroundLight = Color(0xFFE3E8FF); // Scaffold background
  static const Color surfaceLight = Colors.white;         // Default for Card, AppBar, Dialog, Drawer background
  static const Color appBarBackgroundLight = Colors.white;
  static const Color cardBackgroundLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF212121);  // Primary text on surface
  static const Color surfaceVariantLight = Color(0xFFE0E0E0); // Colors.grey.shade200
  static const Color onSurfaceVariantLight = Color(0xFF616161); // Colors.grey.shade700
  static const Color primaryContainerLight = Color(0xFFBBDEFB); // Colors.blue.shade100
  static const Color onPrimaryContainerLight = Color(0xFF0D47A1); // Colors.blue.shade900
  static const Color secondaryContainerLight = Color(0xFFE3F2FD); // Example: Light blue accent container
  static const Color onSecondaryContainerLight = Color(0xFF1565C0); // Example: Text on light blue accent
  static const Color outlineLight = Color(0xFFBDBDBD); // Colors.grey[400] for borders
  static const Color iconLight = Color(0xFF616161); // Colors.grey[700]
  static const Color chipBackgroundLight = primaryLight;
  static const Color chipLabelLight = onPrimaryLight;

  // --- Dark Theme Specific Colors ---
  static const Color primaryDark = Color(0xFF81D4FA); // Colors.lightBlue[300]
  static const Color onPrimaryDark = Colors.black;
  static const Color secondaryDark = Color(0xFF64FFDA); // Colors.tealAccent[200]
  static const Color backgroundDark = Color(0xFF121212);  // Scaffold background
  static const Color surfaceDark = Color(0xFF1E1E1E);    // Default for Card, AppBar, Dialog, Drawer background
  static const Color appBarBackgroundDark = Color(0xFF1F1F1F);
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xE0FFFFFF);  // Primary text on surface (slightly transparent white)
  static const Color surfaceVariantDark = Color(0xFF424242); // Colors.grey.shade800
  static const Color onSurfaceVariantDark = Color(0xFFBDBDBD); // Colors.grey.shade400
  static const Color primaryContainerDark = Color(0xFF0D47A1); // Colors.blue.shade800
  static const Color onPrimaryContainerDark = Color(0xFFBBDEFB); // Colors.blue.shade100
  static const Color secondaryContainerDark = Color(0xFF004D40); // Example: Dark teal accent container
  static const Color onSecondaryContainerDark = Color(0xFF80CBC4); // Example: Text on dark teal accent
  static const Color outlineDark = Color(0xFF616161); // Colors.grey[700] for borders
  static const Color iconDark = Color(0xFFBDBDBD); // Colors.grey[400]
  static const Color chipBackgroundDark = Color(0xFF455A64); // Colors.blueGrey[700]
  static const Color chipLabelDark = Color(0xE0FFFFFF);

  // --- Common Colors ---
  static const Color error = Color(0xFFD32F2F); // Colors.red[700]
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFFCDD2); // Light red for error container bg
  static const Color onErrorContainer = Color(0xFFB71C1C); // Dark red for text on error container

  static const Color success = Color(0xFF388E3C); // Colors.green[700]
  static const Color onSuccess = Colors.white;
  static const Color successContainer = Color(0xFFC8E6C9); // Light green for success container bg
  static const Color onSuccessContainer = Color(0xFF1B5E20); // Dark green for text on success container

  // Semantic names for input fields, etc.
  static const Color inputFillLight = Colors.white;
  static const Color inputFillDark = Color(0xFF2C2C2C);
  static const Color inputHintLight = Color(0xFF757575); // Colors.grey[600]
  static const Color inputHintDark = Color(0xFF9E9E9E); // Colors.grey[500]

  // --- Colors for MyExamsScreen and ExamViewerScreen ---
  static const Color textPrimaryDark = Color(0xFF212121); // Matches onSurfaceLight
  static const Color textSecondaryDark = Color(0xFF616161); // Matches onSurfaceVariantLight
  static const Color downloadIconColor = Color(0xFF388E3C); // Matches success
  static const Color downloadProgressColor = Color(0xFF388E3C); // Matches success
  static const Color errorIconColor = Color(0xFFD32F2F); // Matches error
  static const Color deleteIconColor = Color(0xFFD32F2F); // Matches error
}