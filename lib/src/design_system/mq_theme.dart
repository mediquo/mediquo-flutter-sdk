import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class MqTheme {
  final Color brand;
  final Color brandStrong;
  final Color brandSubtle;
  final Color textBrand;

  final Color background;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textInverse;
  final Color textOnBrand;
  final Color borderDefault;
  final Color borderStrong;

  final Color error;
  final Color errorSubtle;
  final Color errorStrong;

  final String? fontFamily;

  const MqTheme({
    this.brand = MqColors.purple700,
    this.brandStrong = MqColors.purple800,
    this.brandSubtle = MqColors.purple50,
    this.textBrand = MqColors.purple700,
    this.background = MqColors.grey50,
    this.surfaceRaised = MqColors.grey100,
    this.textPrimary = MqColors.grey950,
    this.textSecondary = MqColors.textIconsSecondary,
    this.textDisabled = MqColors.grey400,
    this.textInverse = MqColors.grey50,
    this.textOnBrand = MqColors.grey50,
    this.borderDefault = MqColors.grey200,
    this.borderStrong = MqColors.grey300,
    this.error = MqColors.red500,
    this.errorSubtle = MqColors.red50,
    this.errorStrong = MqColors.red700,
    this.fontFamily,
  });

  factory MqTheme.fromBrand(Color brand) {
    final strong = Color.lerp(brand, const Color(0xFF000000), 0.25)!;
    final light = ThemeData.estimateBrightnessForColor(brand) == Brightness.light;
    return MqTheme(
      brand: brand,
      brandStrong: strong,
      brandSubtle: Color.lerp(brand, MqColors.grey50, 0.9)!,
      textBrand: light ? strong : brand,
      textOnBrand: light ? MqColors.grey950 : MqColors.grey50,
    );
  }

  static MqTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MqThemeScope>()?.theme ?? const MqTheme();

  Widget wrap(Widget child) => _MqThemeScope(
        theme: this,
        child: Builder(builder: (context) => Theme(data: _themeData(Theme.of(context)), child: child)),
      );

  ThemeData _themeData(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: brand,
        onPrimary: textOnBrand,
        surface: background,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceTint: Colors.transparent,
        outline: borderDefault,
        outlineVariant: borderDefault,
        error: error,
      ),
      textTheme: _withoutTracking(
        base.textTheme.apply(fontFamily: fontFamily, bodyColor: textPrimary, displayColor: textPrimary),
      ),
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: surfaceRaised,
      hoverColor: surfaceRaised,
      dividerColor: borderDefault,
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: brand),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brand,
        selectionColor: brandSubtle,
        selectionHandleColor: brand,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: borderDefault)),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: MqFontSize.base,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MqRadius.xxl))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MqRadius.lg)),
      ),
    );
  }
}

TextTheme _withoutTracking(TextTheme t) {
  TextStyle? f(TextStyle? s) => s?.copyWith(letterSpacing: 0);
  return t.copyWith(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

class _MqThemeScope extends InheritedTheme {
  final MqTheme theme;

  const _MqThemeScope({required this.theme, required super.child});

  @override
  Widget wrap(BuildContext context, Widget child) => _MqThemeScope(theme: theme, child: child);

  @override
  bool updateShouldNotify(_MqThemeScope old) => old.theme != theme;
}
