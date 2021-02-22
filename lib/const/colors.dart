

import 'package:flutter/material.dart';

/// In-app colors according to the design.
///
/// The app palette is described by private constants listed at the bottom of this class.
class AppColors {

  static const primaryAction = _tint;
  static const lightAction = _light_tint;
  static const extraLightAction = _extra_light_tint;
  static const disabledAction = _light_tint;
  static const primaryActionText = Colors.white;
  static const primaryActionIcon = Colors.white;
  static const splash = Color(0x22000000);
  static const accent = _accent;
  static const success = Color(0xFF47AB52);

  static const tabActive = _tint;
  static const tabInactive = _light_tint;

  static const background = _background;

  static const lightHintText = _light_tint;
  static const hintText = _text;
  static const linkText = _tint;
  static const disabledText = _light_tint;

  static const toolbarTitleText = Colors.black;
  static const toolbarSubtitleText = _light_tint;
  static const toolbarIcon = _tint;

  static const screenTitleText = Colors.black;

  static const divider = _extra_light_tint;
  static const settingsItemText = Color(0xFF414D80);

  static const inputBackground = _extra_light_tint;
  static const inputBackgroundFocused = Colors.white;
  static const noImageBackground = _extra_light_tint;
  static const noImageForeground = Color(0xFFD1D6E9);
  static const fieldIconForeground = Color(0xFFA6ACC5);
  static const inputActiveBorder = _tint;
  static const inputHint = _light_tint;

  static const logoText = _tint;

  static const dialogOverlay = Color(0xBA000000);
  static const dialogBackground = _background;

  static const itemBackground = Colors.white;
  static const errorBackground = Color(0xFFF5E9ED);
  static const errorText = Color(0xFFDE164D);
  static const errorAccent = Color(0xFFDE164D);

  // -- app palette

  static const MaterialColor primaryMaterial = MaterialColor(
    _tintValue,
    <int, Color>{
      50: Color(0xFFE8EAF6),
      100: Color(0xFF9EADEC),
      200: Color(0xFF899BE1),
      300: Color(0xFF6679C8),
      400: Color(0xFF475CAE),
      500: Color(0xFF3D4E95),
      600: Color(0xFF32417B),
      700: Color(0xFF283462),
      800: Color(0xFF222C53),
      900: Color(0xFF1A2241),
    },
  );

  static const transparent = Color(0x00000000);
  static const _background = Color(0xFFF2F5FA);
  static const _tint = Color(_tintValue);
  static const _light_tint = Color(0xFF8088A9);
  static const _extra_light_tint = Color(0xFFDFE5F0);
  static const _text = Color(0xFF323647);
  static const _accent = Color(0xFFDE164D);
  static const _tintValue = 0xFF954E3D;
}