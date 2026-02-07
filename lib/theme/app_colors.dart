import 'package:flutter/material.dart';

/// Color palette for iMosque Admin Dashboard
/// Consistent with mobile app - Sacred Serenity Color Palette
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS - Islamic Green Theme
  // ============================================
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryVariant = Color(0xFF4CAF50);

  // ============================================
  // SECONDARY COLORS
  // ============================================
  static const Color secondary = Color(0xFF81C784);
  static const Color secondaryVariant = Color(0xFF4CAF50);

  // ============================================
  // ACCENT COLORS
  // ============================================
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentGoldLight = Color(0xFFFFD54F);

  // ============================================
  // BACKGROUND & SURFACE
  // ============================================
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color dialog = Color(0xFFFFFFFF);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);

  // ============================================
  // DIVIDER & BORDER
  // ============================================
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x0A000000);

  // ============================================
  // STATUS INDICATORS
  // ============================================
  static const Color active = Color(0xFF4CAF50);
  static const Color inactive = Color(0xFF9E9E9E);
  static const Color blocked = Color(0xFFD32F2F);
  static const Color pending = Color(0xFFF57C00);
  static const Color verified = Color(0xFF2E7D32);
  static const Color rejected = Color(0xFFD32F2F);

  // ============================================
  // SIDEBAR COLORS
  // ============================================
  static const Color sidebarBackground = Color(0xFF1B5E20);
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarTextSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color sidebarHover = Color(0xFF2E7D32);
  static const Color sidebarActive = Color(0xFF388E3C);
  static const Color sidebarIcon = Color(0xFFFFFFFF);

  // ============================================
  // DATA TABLE COLORS
  // ============================================
  static const Color tableHeader = Color(0xFFF5F5F5);
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFFAFAFA);
  static const Color tableRowHover = Color(0xFFE8F5E9);
  static const Color tableBorder = Color(0xFFE0E0E0);
}
