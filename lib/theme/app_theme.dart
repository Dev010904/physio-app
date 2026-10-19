import 'package:flutter/material.dart';

/// PhysioSathi design system: "Calm clinic" in light mode, "Bold focus" in
/// dark mode (chosen 2026-10-19). Large text and big touch targets throughout,
/// so the app stays easy for older patients and busy clinicians.
abstract final class AppTheme {
  static ThemeData light() => _build(_calmClinic, Brand.calm);
  static ThemeData dark() => _build(_boldFocus, Brand.bold);

  // Calm clinic: mint page, white cards, teal accents.
  static const _calmClinic = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F6E56),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE1F5EE),
    onPrimaryContainer: Color(0xFF04342C),
    secondary: Color(0xFF1D9E75),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE1F5EE),
    onSecondaryContainer: Color(0xFF04342C),
    tertiary: Color(0xFF5DCAA5),
    onTertiary: Color(0xFF04342C),
    error: Color(0xFFA32D2D),
    onError: Colors.white,
    errorContainer: Color(0xFFFCEBEB),
    onErrorContainer: Color(0xFF501313),
    surface: Color(0xFFF4FAF8),
    onSurface: Color(0xFF04342C),
    onSurfaceVariant: Color(0xFF5F5E5A),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Color(0xFFEAF5F1),
    surfaceContainerHighest: Color(0xFFE1F5EE),
    outline: Color(0xFFB4B2A9),
    outlineVariant: Color(0xFFD3D1C7),
  );

  // Bold focus: deep navy, lime highlights; high contrast, easy on OLED batteries.
  static const _boldFocus = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF97C459),
    onPrimary: Color(0xFF173404),
    primaryContainer: Color(0xFF185FA5),
    onPrimaryContainer: Color(0xFFE6F1FB),
    secondary: Color(0xFFC0DD97),
    onSecondary: Color(0xFF173404),
    secondaryContainer: Color(0xFF185FA5),
    onSecondaryContainer: Color(0xFFE6F1FB),
    tertiary: Color(0xFF5DCAA5),
    onTertiary: Color(0xFF04342C),
    error: Color(0xFFF09595),
    onError: Color(0xFF501313),
    errorContainer: Color(0xFF791F1F),
    onErrorContainer: Color(0xFFFCEBEB),
    surface: Color(0xFF042C53),
    onSurface: Color(0xFFE6F1FB),
    onSurfaceVariant: Color(0xFF85B7EB),
    surfaceContainerLowest: Color(0xFF042C53),
    surfaceContainerLow: Color(0xFF0C447C),
    surfaceContainer: Color(0xFF0C447C),
    surfaceContainerHigh: Color(0xFF185FA5),
    surfaceContainerHighest: Color(0xFF0C447C),
    outline: Color(0xFF378ADD),
    outlineVariant: Color(0xFF185FA5),
  );

  static ThemeData _build(ColorScheme c, Brand brand) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(brand.radius));
    final base = ThemeData(colorScheme: c, useMaterial3: true);
    final text = base.textTheme
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.45),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: c.onSurface, displayColor: c.onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: c.surface,
      textTheme: text,
      extensions: [brand],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: shape,
          textStyle: text.labelLarge?.copyWith(fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.primary, width: 1.5),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brand.soft,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.bodyMedium?.copyWith(fontSize: 13, color: c.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.onSurface,
        minVerticalPadding: 12,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brand.soft,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontSize: 13)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: c.outlineVariant, thickness: 0.6),
    );
  }
}

/// Brand values that Material's ColorScheme has no slot for.
@immutable
class Brand extends ThemeExtension<Brand> {
  const Brand({required this.radius, required this.soft, required this.ringTrack});

  static const calm = Brand(radius: 16, soft: Color(0xFFE1F5EE), ringTrack: Color(0xFFDDEFE8));
  static const bold = Brand(radius: 14, soft: Color(0xFF185FA5), ringTrack: Color(0xFF0C447C));

  /// Corner radius for cards, buttons and panels.
  final double radius;

  /// Soft tint behind chips, icons and selected items.
  final Color soft;

  /// The unfilled part of progress rings and bars.
  final Color ringTrack;

  static Brand of(BuildContext context) => Theme.of(context).extension<Brand>() ?? calm;

  @override
  Brand copyWith({double? radius, Color? soft, Color? ringTrack}) =>
      Brand(radius: radius ?? this.radius, soft: soft ?? this.soft, ringTrack: ringTrack ?? this.ringTrack);

  @override
  Brand lerp(Brand? other, double t) => other == null
      ? this
      : Brand(
          radius: radius + (other.radius - radius) * t,
          soft: Color.lerp(soft, other.soft, t)!,
          ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
        );
}
