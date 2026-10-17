import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle headingLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle headingMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle headingSmall({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle button({Color color = Colors.white}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle currencyBig({Color color = AppColors.primary}) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
}
