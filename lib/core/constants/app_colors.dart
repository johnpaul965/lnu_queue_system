// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class LNUColors {
  // ── Core palette: blue, dark blue, light blue, white, yellow, black ──
  static const Color darkBlue  = Color(0xFF0D0D7A);
  static const Color blue      = Color(0xFF1A56DB);
  static const Color lightBlue = Color(0xFFBDD7FF);
  static const Color yellow    = Color(0xFFF5A623);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF111827);

  // ── Aliases ───────────────────────────────────────────────────────────
  static const Color primary      = darkBlue;
  static const Color primaryLight = blue;
  static const Color primaryDark  = Color(0xFF070750);
  static const Color secondary    = yellow;
  static const Color secondaryDark  = Color(0xFFD4891E);
  static const Color secondaryLight = Color(0xFFFFD166);

  // ── Surfaces / text ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F4FF);   // very pale blue-white
  static const Color surface    = white;
  static const Color border     = Color(0xFFD0DEFF);   // soft light blue border
  static const Color textMuted  = Color(0xFF4B5E82);   // muted blue-navy text
  static const Color onSurface  = black;

  // ── Status colors — all from the 6-color palette ─────────────────────
  static const Color statusSubmitted    = blue;
  static const Color statusUnderReview  = blue;
  static const Color statusIncomplete   = yellow;
  static const Color statusForPayment   = yellow;
  static const Color statusVerified     = blue;
  static const Color statusProcessing   = darkBlue;
  static const Color statusForClaiming  = darkBlue;
  static const Color statusCompleted    = black;
  static const Color statusRejected     = black;

  static Color forStatus(String status) => switch (status) {
    'SUBMITTED'        => statusSubmitted,
    'UNDER_REVIEW'     => statusUnderReview,
    'INCOMPLETE'       => statusIncomplete,
    'FOR_PAYMENT'      => statusForPayment,
    'PAYMENT_VERIFIED' => statusVerified,
    'PROCESSING'       => statusProcessing,
    'FOR_CLAIMING'     => statusForClaiming,
    'COMPLETED'        => statusCompleted,
    'REJECTED'         => statusRejected,
    _                  => textMuted,
  };
}
