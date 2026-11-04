import 'package:flutter/widgets.dart';

abstract final class MqColors {
  static const purple50 = Color(0xFFF5E5FF);
  static const purple700 = Color(0xFF6500CC);
  static const purple800 = Color(0xFF4F0099);

  static const grey50 = Color(0xFFFFFFFF);
  static const grey100 = Color(0xFFF8F7FA);
  static const grey200 = Color(0xFFEDECF1);
  static const grey300 = Color(0xFFD1CCDC);
  static const grey400 = Color(0xFFB2ABC4);
  static const grey950 = Color(0xFF0A0A23);

  static const textIconsSecondary = Color(0xFF6D658B);

  static const red50 = Color(0xFFFED5E1);
  static const red500 = Color(0xFFFF014D);
  static const red700 = Color(0xFFB30135);
}

abstract final class MqRadius {
  static const md = 6.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const xxl = 16.0;
  static const full = 9999.0;
}

abstract final class MqControlSize {
  static const sm = 32.0;
  static const md = 40.0;
  static const lg = 48.0;
}

abstract final class MqFontSize {
  static const xs = 12.0;
  static const sm = 14.0;
  static const base = 16.0;
  static const lg = 18.0;
  static const xl = 20.0;
}
