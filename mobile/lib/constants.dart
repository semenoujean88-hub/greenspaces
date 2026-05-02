import 'package:flutter/material.dart';

// ── Couleurs GreenSpace ──────────────────────
const kGreen      = Color(0xFF2D6A4F);
const kGreenDark  = Color(0xFF1B4332);
const kGreenLight = Color(0xFFD8F3DC);
const kBrown      = Color(0xFF924809);
const kBrownDark  = Color(0xFF5D2906);
const kCream      = Color(0xFFF5E6D3);
const kGray       = Color(0xFF6B7280);
const kGrayLight  = Color(0xFFF3F4F6);
const kWhite      = Color(0xFFFFFFFF);
const kDanger     = Color(0xFFDC2626);
const kSuccess    = Color(0xFF16A34A);
const kWarning    = Color(0xFFD97706);

// ── Texte ────────────────────────────────────
const kTextDark   = Color(0xFF111827);
const kTextMuted  = Color(0xFF6B7280);

// ── Rôles ────────────────────────────────────
const kRoles = {
  'AGRICULTEUR':   {'label': 'Agriculteur',   'icon': Icons.agriculture},
  'EXPORTATEUR':   {'label': 'Exportateur',   'icon': Icons.local_shipping},
  'VERIFICATEUR':  {'label': 'Vérificateur',  'icon': Icons.verified_user},
  'TRANSFORMATEUR':{'label': 'Transformateur','icon': Icons.precision_manufacturing},
  'COOPERATIVE':   {'label': 'Coopérative',   'icon': Icons.groups},
};

// ── URL de base de l'API ─────────────────────
// const kBaseUrl = 'http://10.0.2.2:8000/api'; // Android emulator → localhost
// const kBaseUrl = '192.168.10.125:8000/api'; // Appareil physique
// ✅ URL de production
const kBaseUrl = 'https://greenspaces.onrender.com';


// ── ThemeData ────────────────────────────────
ThemeData greenSpaceTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kGreen, brightness: Brightness.light),
    scaffoldBackgroundColor: kGreenLight,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: kWhite,
      foregroundColor: kTextDark,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrown,
        foregroundColor: kWhite,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGreen,
        side: const BorderSide(color: kGreen),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kGreen, width: 2),
      ),
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: kWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
  );
}
