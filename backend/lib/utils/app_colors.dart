import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A90E2);
  static const Color secondary = Color(0xFF7BB3F0);
  static const Color accent = Color(0xFF5DADE2);
  static const Color background = Color(0xFFF8FBFF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF85C1E9),
      Color(0xFFAED6F1),
      Color(0xFF85C1E9),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}


