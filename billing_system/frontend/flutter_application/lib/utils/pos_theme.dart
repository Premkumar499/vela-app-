import 'package:flutter/material.dart';

/// POS-specific design tokens.
/// All colors, typography, and decoration helpers live here.
/// Import this instead of (or alongside) the legacy AppTheme.
class PosTheme {
  PosTheme._();

  // ─── Palette ────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryDark  = Color(0xFF003C8F);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primarySoft  = Color(0xFFE3F2FD); // header / hover tint

  static const Color background   = Color(0xFFF8F9FA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceAlt   = Color(0xFFF4F6F9);

  static const Color border       = Color(0xFFE0E4EA);
  static const Color borderDark   = Color(0xFFCDD3DC);

  static const Color textPrimary  = Color(0xFF1A1D23);
  static const Color textSecondary= Color(0xFF6B7280);
  static const Color textHint     = Color(0xFFADB5BD);

  static const Color success      = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger       = Color(0xFFC62828);
  static const Color dangerLight  = Color(0xFFFFEBEE);

  static const Color grandTotalBg = Color(0xFF1565C0);

  // ─── Avatar palette (cycling for product initials) ───────────────────
  static const List<Color> avatarColors = [
    Color(0xFF1565C0), // blue
    Color(0xFF00695C), // teal
    Color(0xFF6A1B9A), // purple
    Color(0xFFAD1457), // pink
    Color(0xFF558B2F), // green
    Color(0xFFE65100), // orange
    Color(0xFF37474F), // grey
    Color(0xFF0277BD), // light-blue
  ];

  static Color avatarColor(int index) =>
      avatarColors[index % avatarColors.length];

  // ─── Spacing ────────────────────────────────────────────────────────────
  static const double radiusSm  = 6.0;
  static const double radiusMd  = 10.0;
  static const double radiusLg  = 14.0;
  static const double radiusXl  = 20.0;

  static const double padSm     = 8.0;
  static const double padMd     = 12.0;
  static const double padLg     = 16.0;
  static const double padXl     = 20.0;

  // ─── Typography ─────────────────────────────────────────────────────────
  static const TextStyle title = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle smallBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static const TextStyle amount = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: -0.5,
  );

  static const TextStyle amountWhite = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: Colors.white, letterSpacing: -0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: textHint, letterSpacing: 0.3,
  );

  // ─── Shadows ────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8, offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 2, offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16, offset: const Offset(2, 0),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 12, offset: const Offset(0, 4),
    ),
  ];

  // ─── Decorations ────────────────────────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  static BoxDecoration get cardHovered => BoxDecoration(
    color: primarySoft,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: primaryLight, width: 1.5),
    boxShadow: cardShadow,
  );

  static BoxDecoration get rightPanel => BoxDecoration(
    color: surface,
    border: const Border(left: BorderSide(color: Color(0xFFE0E4EA))),
    boxShadow: panelShadow,
  );

  static BoxDecoration get searchBar => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  // ─── Button Styles ───────────────────────────────────────────────────────
  static ButtonStyle primaryButton({double height = 52}) =>
      ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
        ),
      );

  static ButtonStyle successButton({double height = 52}) =>
      ElevatedButton.styleFrom(
        backgroundColor: success,
        foregroundColor: Colors.white,
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle dangerButton({double height = 52}) =>
      OutlinedButton.styleFrom(
        foregroundColor: danger,
        minimumSize: Size(0, height),
        side: const BorderSide(color: Color(0xFFFFCDD2)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle outlineButton({double height = 52}) =>
      OutlinedButton.styleFrom(
        foregroundColor: textSecondary,
        minimumSize: Size(0, height),
        side: const BorderSide(color: Color(0xFFCDD3DC)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      );

  // ─── MaterialApp ThemeData ────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: surface,
      surfaceContainerHighest: background,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: Colors.white, letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: border),
      ),
    ),
    dividerColor: border,
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    ),
  );
}
