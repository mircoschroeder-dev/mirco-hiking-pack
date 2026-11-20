import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packliste_core/models.dart';

// Design "Papier-Wanderkarte": Papierton, Hoehenlinien, Schrift wie auf einer
// topografischen Karte. Systemschriften, damit keine Schriftdateien noetig sind.
const _serif = 'serif';
const _condensed = 'sans-serif-condensed';

class _MapColors {
  const _MapColors({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.contour,
    required this.border,
    required this.forest,
    required this.water,
    required this.red,
  });

  final Color paper;
  final Color card;
  final Color ink;
  final Color inkSoft;
  final Color contour;
  final Color border;
  final Color forest;
  final Color water;
  final Color red;
}

const _day = _MapColors(
  paper: Color(0xFFF3EBD7),
  card: Color(0xFFFAF5E8),
  ink: Color(0xFF2E2A22),
  inkSoft: Color(0xFF5E5545),
  contour: Color(0xFFC2A97F),
  border: Color(0xFF9C8763),
  forest: Color(0xFF3F6B3A),
  water: Color(0xFF3D7A99),
  red: Color(0xFFA8432A),
);

const _night = _MapColors(
  paper: Color(0xFF1C1A16),
  card: Color(0xFF26231D),
  ink: Color(0xFFEDE4CF),
  inkSoft: Color(0xFFB9AE96),
  contour: Color(0xFF4D4436),
  border: Color(0xFF6E6049),
  forest: Color(0xFF8DBB7E),
  water: Color(0xFF7FB3CC),
  red: Color(0xFFE5937A),
);

_MapColors _colors(Brightness b) => b == Brightness.dark ? _night : _day;

/// Zeilenfarbe je Status, wie die Flaechenfarben einer Wanderkarte:
/// Waldgruen gepackt, Ocker vorhanden, Wasserblau kaufen.
Color statusColor(ItemStatus status, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (status) {
    ItemStatus.packed =>
      dark ? const Color(0xFF2C4529) : const Color(0xFFD3E4C3),
    ItemStatus.available =>
      dark ? const Color(0xFF4A3F1F) : const Color(0xFFF2E2AE),
    ItemStatus.toBuy =>
      dark ? const Color(0xFF1F3E4C) : const Color(0xFFCBE2EC),
    ItemStatus.left => Colors.transparent,
  };
}

/// Ueberschrift im Stil einer Kartenbeschriftung: schmale Grossbuchstaben.
TextStyle mapLabelStyle(BuildContext context) => TextStyle(
  fontFamily: _condensed,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.6,
  color: _colors(Theme.of(context).brightness).inkSoft,
);

/// Gewichtszahlen in Kartenrot.
TextStyle weightStyle(BuildContext context, double size) => TextStyle(
  fontFamily: _serif,
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: _colors(Theme.of(context).brightness).red,
);

ThemeData buildTheme(Brightness brightness) {
  final c = _colors(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.forest,
    onPrimary: c.card,
    primaryContainer: c.forest,
    onPrimaryContainer: c.card,
    secondary: c.water,
    onSecondary: c.card,
    tertiary: c.red,
    onTertiary: c.card,
    error: c.red,
    onError: c.card,
    surface: c.card,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSoft,
    surfaceContainer: c.card,
    surfaceContainerHigh: c.card,
    surfaceContainerHighest: c.paper,
    outline: c.border,
    outlineVariant: c.contour,
    inverseSurface: c.ink,
    onInverseSurface: c.paper,
    inversePrimary: c.forest,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(colorScheme: scheme, brightness: brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
    side: BorderSide(color: c.border),
  );
  const buttonSize = Size(64, 56);
  const buttonText = TextStyle(
    fontFamily: _condensed,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  final text = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: c.paper,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontFamily: _serif),
      headlineSmall: text.headlineSmall?.copyWith(fontFamily: _serif),
      titleLarge: text.titleLarge?.copyWith(fontFamily: _serif),
      titleMedium: text.titleMedium?.copyWith(fontSize: 18),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 17),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      // Dunkle Symbole in der Statusleiste auf hellem Papier und umgekehrt.
      systemOverlayStyle:
          (brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemStatusBarContrastEnforced: false,
              ),
      titleTextStyle: TextStyle(
        fontFamily: _serif,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      shape: shape,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        textStyle: buttonText,
        foregroundColor: c.ink,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.forest,
      foregroundColor: c.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      extendedTextStyle: buttonText,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.card,
      selectedColor: c.forest,
      checkmarkColor: c.card,
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      labelStyle: TextStyle(color: c.ink),
      secondaryLabelStyle: TextStyle(color: c.card),
    ),
    popupMenuTheme: PopupMenuThemeData(color: c.card, shape: shape),
    dialogTheme: DialogThemeData(backgroundColor: c.card, shape: shape),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: c.ink, width: 2),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.forest
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(c.card),
    ),
    listTileTheme: const ListTileThemeData(minTileHeight: 64),
    dividerTheme: DividerThemeData(color: c.contour, thickness: 1),
  );
}

/// Papier mit Hoehenlinien als Hintergrund einer ganzen Seite.
class MapBackground extends StatelessWidget {
  const MapBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = _colors(Theme.of(context).brightness);
    return ColoredBox(
      color: c.paper,
      child: CustomPaint(painter: _ContourPainter(c.contour), child: child),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.55);
    final index = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color.withValues(alpha: 0.8);

    // Einige "Berge" mit ineinanderliegenden, unregelmaessigen Ringen.
    final hills = [
      (Offset(size.width * 0.85, size.height * 0.12), size.width * 0.75, 11),
      (Offset(size.width * 0.05, size.height * 0.55), size.width * 0.65, 9),
      (Offset(size.width * 0.9, size.height * 0.92), size.width * 0.6, 8),
    ];
    for (final (center, radius, rings) in hills) {
      final p1 = random.nextDouble() * math.pi * 2;
      final p2 = random.nextDouble() * math.pi * 2;
      final p3 = random.nextDouble() * math.pi * 2;
      for (var k = 1; k <= rings; k++) {
        final r = radius * k / rings;
        final path = Path();
        const steps = 90;
        for (var s = 0; s <= steps; s++) {
          final a = s / steps * math.pi * 2;
          final wobble =
              1 +
              0.16 * math.sin(2 * a + p1) +
              0.09 * math.sin(3 * a + p2 + k * 0.15) +
              0.05 * math.sin(5 * a + p3);
          final point = center + Offset(math.cos(a), math.sin(a)) * r * wobble;
          s == 0
              ? path.moveTo(point.dx, point.dy)
              : path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, k % 5 == 0 ? index : thin);
      }
    }
  }

  @override
  bool shouldRepaint(_ContourPainter old) => old.color != color;
}

/// Fortschritt als Massstabsleiste wie auf einer Wanderkarte.
class ScaleBar extends StatelessWidget {
  const ScaleBar({super.key, required this.value});

  /// 0 bis 1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = _colors(Theme.of(context).brightness);
    return SizedBox(
      height: 12,
      width: double.infinity,
      child: CustomPaint(painter: _ScaleBarPainter(value, c)),
    );
  }
}

class _ScaleBarPainter extends CustomPainter {
  _ScaleBarPainter(this.value, this.c);

  final double value;
  final _MapColors c;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 10;
    final w = size.width / segments;
    for (var i = 0; i < segments; i++) {
      final rect = Rect.fromLTWH(i * w, 0, w, size.height);
      canvas.drawRect(rect, Paint()..color = i.isEven ? c.ink : c.card);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * value.clamp(0, 1), size.height),
      Paint()..color = c.forest,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = c.ink,
    );
  }

  @override
  bool shouldRepaint(_ScaleBarPainter old) => old.value != value || old.c != c;
}
